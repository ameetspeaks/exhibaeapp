import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _applicationUpdates = true;
  bool _exhibitionReminders = true;
  bool _marketingEmails = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Notification Settings',
          style: TextStyle(
            color: AppTheme.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: AppTheme.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSettingSection(
              'Push Notifications',
              'Receive notifications on your device',
              _pushNotifications,
              (value) => setState(() => _pushNotifications = value),
            ),
            _buildSettingSection(
              'Email Notifications',
              'Receive notifications via email',
              _emailNotifications,
              (value) => setState(() => _emailNotifications = value),
            ),
            _buildSettingSection(
              'Application Updates',
              'Get notified about new applications',
              _applicationUpdates,
              (value) => setState(() => _applicationUpdates = value),
            ),
            _buildSettingSection(
              'Exhibition Reminders',
              'Get reminded about upcoming exhibitions',
              _exhibitionReminders,
              (value) => setState(() => _exhibitionReminders = value),
            ),
            _buildSettingSection(
              'Marketing Emails',
              'Receive promotional emails and updates',
              _marketingEmails,
              (value) => setState(() => _marketingEmails = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingSection(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
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
      child: SwitchListTile(
        title: Text(
          title,
          style: const TextStyle(
            color: AppTheme.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: AppTheme.white.withOpacity(0.8),
            fontSize: 14,
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.white,
        activeTrackColor: AppTheme.white.withOpacity(0.3),
        inactiveThumbColor: AppTheme.white.withOpacity(0.6),
        inactiveTrackColor: AppTheme.white.withOpacity(0.1),
      ),
    );
  }
}
