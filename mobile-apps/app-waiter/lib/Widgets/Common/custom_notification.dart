import 'package:flutter/material.dart';
import 'package:waiter_app/Themes/colors.dart';

enum NotificationType {
  info,
  success,
  warning,
  error,
}

class CustomNotification {
  static void show({
    required BuildContext context,
    required String message,
    NotificationType type = NotificationType.info,
    Duration duration = const Duration(seconds: 2),
    bool showProgressIndicator = false,
    VoidCallback? onTap,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    Color backgroundColor;
    Color iconColor;
    IconData icon;

    // Set properties based on notification type
    switch (type) {
      case NotificationType.success:
        backgroundColor = AppColors.success.withOpacity(0.95);
        iconColor = Colors.white;
        icon = Icons.check_circle;
        break;
      case NotificationType.warning:
        backgroundColor = AppColors.warning.withOpacity(0.95);
        iconColor = Colors.black87;
        icon = Icons.warning_amber;
        break;
      case NotificationType.error:
        backgroundColor = AppColors.error.withOpacity(0.95);
        iconColor = Colors.white;
        icon = Icons.error;
        break;
      case NotificationType.info:
      default:
        backgroundColor = Colors.black87;
        iconColor = Colors.white;
        icon = Icons.info;
        break;
    }

    // Dismiss any existing SnackBar
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: InkWell(
          onTap: onTap,
          child: Row(
            children: [
              // Icon
              Icon(
                icon,
                color: iconColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              
              // Message and optional progress indicator
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message,
                      style: TextStyle(
                        color: iconColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (showProgressIndicator) ...[
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        backgroundColor: iconColor.withOpacity(0.3),
                        valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Optional action button
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    onAction();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: iconColor,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    actionLabel,
                    style: TextStyle(
                      color: iconColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(8),
        duration: duration,
        elevation: 4,
      ),
    );
  }
} 