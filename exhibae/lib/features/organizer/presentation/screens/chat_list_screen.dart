import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/widgets/profile_picture_display.dart';
import '../../../../core/routes/app_router.dart';
import '../../services/chat_notification_service.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final SupabaseService _supabaseService = SupabaseService.instance;
  bool _isLoading = true;
  List<Map<String, dynamic>> _chats = [];
  String? _error;
  String _searchQuery = '';
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadChats();
    _subscribeToChats();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    await ChatNotificationService.instance.initialize();
    await ChatNotificationService.instance.updateUnreadCount();
  }

  @override
  void dispose() {
    _unsubscribeFromChats();
    super.dispose();
  }

  Future<void> _loadChats() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final userId = _supabaseService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabaseService.client
          .from('chats')
          .select('''
            *,
            brand:brand_id(
              id,
              company_name,
              full_name,
              avatar_url
            ),
            exhibition:exhibition_id(
              id,
              title
            ),
            last_message:messages!chat_messages_chat_id_fkey(
              content,
              created_at,
              sender_id,
              is_read
            )
          ''')
          .eq('organizer_id', userId)
          .order('updated_at', ascending: false);

      if (mounted) {
        setState(() {
          _chats = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _subscribeToChats() {
    final userId = _supabaseService.currentUser?.id;
    if (userId == null) return;

    _supabaseService.client
        .from('chats')
        .stream(primaryKey: ['id'])
        .eq('organizer_id', userId)
        .listen((List<Map<String, dynamic>> data) {
          if (mounted) {
            setState(() {
              _chats = data;
            });
          }
        });
  }

  void _unsubscribeFromChats() {
    // Supabase automatically handles unsubscription
  }

  List<Map<String, dynamic>> get _filteredChats {
    return _chats.where((chat) {
      // Search filter
      final brand = chat['brand'] ?? {};
      final exhibition = chat['exhibition'] ?? {};
      final matchesSearch = 
        brand['company_name']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false ||
        exhibition['title']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false;
      
      if (!matchesSearch) return false;
      
      // Status filter
      if (_selectedFilter != 'all') {
        switch (_selectedFilter) {
          case 'unread':
            final lastMessage = chat['last_message'] ?? [];
            if (lastMessage.isEmpty) return false;
            final message = lastMessage.last;
            return message['sender_id'] != _supabaseService.currentUser?.id &&
                   !message['is_read'];
          case 'active':
            return chat['status'] == 'active';
          case 'archived':
            return chat['status'] == 'archived';
        }
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Messages',
          style: TextStyle(
            color: AppTheme.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    style: const TextStyle(color: AppTheme.white),
                    decoration: InputDecoration(
                      hintText: 'Search messages...',
                      hintStyle: TextStyle(color: AppTheme.white.withOpacity(0.6)),
                      prefixIcon: Icon(Icons.search, color: AppTheme.white.withOpacity(0.6)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', 'all'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Unread', 'unread'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Active', 'active'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Archived', 'archived'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.white),
                    ),
                  )
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Error loading messages',
                              style: TextStyle(
                                color: AppTheme.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _error!,
                              style: TextStyle(
                                color: AppTheme.white.withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadChats,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.white.withOpacity(0.2),
                                foregroundColor: AppTheme.white,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _filteredChats.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: AppTheme.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: AppTheme.white.withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.chat_bubble_outline,
                                    size: 64,
                                    color: AppTheme.white.withOpacity(0.6),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'No messages found',
                                  style: TextStyle(
                                    color: AppTheme.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _searchQuery.isNotEmpty
                                      ? 'Try adjusting your search or filters'
                                      : 'Your messages will appear here',
                                  style: TextStyle(
                                    color: AppTheme.white.withOpacity(0.8),
                                    fontSize: 16,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredChats.length,
                            itemBuilder: (context, index) {
                              final chat = _filteredChats[index];
                              return _buildChatCard(chat);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    
    return FilterChip(
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = selected ? value : 'all';
        });
      },
      backgroundColor: isSelected ? AppTheme.white : AppTheme.white.withOpacity(0.1),
      selectedColor: AppTheme.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppTheme.white : AppTheme.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? AppTheme.gradientBlack : AppTheme.white,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  Widget _buildChatCard(Map<String, dynamic> chat) {
    final brand = chat['brand'] ?? {};
    final exhibition = chat['exhibition'] ?? {};
    final lastMessage = chat['last_message'] ?? [];
    final message = lastMessage.isNotEmpty ? lastMessage.last : null;
    final isUnread = message != null &&
                     message['sender_id'] != _supabaseService.currentUser?.id &&
                     !message['is_read'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pushNamed(
              context,
              AppRouter.chat,
              arguments: chat,
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ProfilePictureDisplay(
                  avatarUrl: brand['avatar_url'],
                  size: 48,
                  backgroundColor: AppTheme.white.withOpacity(0.1),
                  iconColor: AppTheme.white,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              brand['company_name'] ?? 'Unknown Brand',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                                color: AppTheme.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (message != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              _formatMessageTime(DateTime.parse(message['created_at'])),
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.white.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        exhibition['title'] ?? 'Unknown Exhibition',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.white.withOpacity(0.8),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (message != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (message['sender_id'] == _supabaseService.currentUser?.id)
                              Icon(
                                Icons.check,
                                size: 14,
                                color: AppTheme.white.withOpacity(0.6),
                              ),
                            if (message['sender_id'] == _supabaseService.currentUser?.id)
                              const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                message['content'] ?? '',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.white.withOpacity(0.6),
                                  fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isUnread) ...[
                              const SizedBox(width: 8),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppTheme.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatMessageTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }
}
