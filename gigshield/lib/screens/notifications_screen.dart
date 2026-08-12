import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/notification_service.dart';
import '../models/notification_model.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () => NotificationService().markAllAsRead(),
            child: const Text('Mark all as read', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: NotificationService(),
        builder: (context, _) {
          final notifications = NotificationService().notifications;

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none_rounded, size: 64, color: AppColors.textMuted.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  const Text(
                    'No notifications yet',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notif = notifications[index];
              return _buildNotificationCard(context, notif);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, GigKavachNotification notif) {
    final dateFormat = DateFormat('MMM d, hh:mm a');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: notif.isRead 
              ? AppColors.textMuted.withValues(alpha: 0.1)
              : notif.color.withValues(alpha: 0.3),
        ),
      ),
      child: InkWell(
        onTap: () => NotificationService().markAsRead(notif.id),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: notif.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(notif.icon, color: notif.color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          notif.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: notif.isRead ? AppColors.textPrimary : AppColors.textPrimary,
                          ),
                        ),
                        if (!notif.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: notif.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notif.message,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      dateFormat.format(notif.timestamp),
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
