import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';

class ChatNotificationService {
  static final ChatNotificationService _instance = ChatNotificationService._internal();
  static ChatNotificationService get instance => _instance;

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final SupabaseService _supabaseService = SupabaseService.instance;
  RealtimeChannel? _messageChannel;
  bool _isInitialized = false;

  ChatNotificationService._internal();

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize notifications
    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Subscribe to new messages
    _subscribeToMessages();

    _isInitialized = true;
  }

  void _onNotificationTap(NotificationResponse response) {
    // TODO: Handle notification tap - navigate to chat screen
  }

  void _subscribeToMessages() {
    final userId = _supabaseService.currentUser?.id;
    if (userId == null) return;

    _messageChannel = _supabaseService.client
        .channel('public:messages')
        .on(
          RealtimeListenTypes.postgresChanges,
          SupabaseEventTypes.insert,
          (payload) async {
            if (payload.newRecord == null) return;

            final message = Map<String, dynamic>.from(payload.newRecord!);
            if (message['sender_id'] == userId) return;

            // Get chat details
            final chat = await _supabaseService.client
                .from('chats')
                .select('''
                  *,
                  brand:brand_id(
                    id,
                    company_name,
                    full_name
                  ),
                  exhibition:exhibition_id(
                    id,
                    title
                  )
                ''')
                .eq('id', message['chat_id'])
                .single();

            if (chat == null) return;

            // Show notification
            await _showMessageNotification(
              chat: chat,
              message: message,
            );
          },
          filter: 'organizer_id=eq.$userId',
        )
        .subscribe();
  }

  void unsubscribe() {
    _messageChannel?.unsubscribe();
  }

  Future<void> _showMessageNotification({
    required Map<String, dynamic> chat,
    required Map<String, dynamic> message,
  }) async {
    final brand = chat['brand'] ?? {};
    final exhibition = chat['exhibition'] ?? {};

    const androidDetails = AndroidNotificationDetails(
      'chat_messages',
      'Chat Messages',
      channelDescription: 'Notifications for new chat messages',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      message['id'].hashCode,
      brand['company_name'] ?? 'New Message',
      '${message['content']} - ${exhibition['title']}',
      details,
      payload: chat['id'],
    );
  }

  Future<void> clearNotifications() async {
    await _notifications.cancelAll();
  }

  Future<void> updateUnreadCount() async {
    final userId = _supabaseService.currentUser?.id;
    if (userId == null) return;

    try {
      // Get unread message count
      final response = await _supabaseService.client
          .from('messages')
          .select('id', const FetchOptions(count: CountOption.exact))
          .eq('organizer_id', userId)
          .neq('sender_id', userId)
          .eq('is_read', false);

      final count = response.count ?? 0;

      // Update badge count
      await _notifications.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          ),
        ),
        onDidReceiveNotificationResponse: _onNotificationTap,
      );

      if (count > 0) {
        await _notifications.show(
          0,
          'Unread Messages',
          'You have $count unread messages',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'unread_messages',
              'Unread Messages',
              channelDescription: 'Badge count for unread messages',
              importance: Importance.min,
              priority: Priority.min,
              showWhen: false,
              playSound: false,
              enableVibration: false,
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: false,
              presentBadge: true,
              presentSound: false,
              badgeNumber: 0,
            ),
          ),
        );
      } else {
        await _notifications.cancel(0);
      }
    } catch (e) {
      // Ignore errors
    }
  }
}
