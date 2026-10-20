import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

class EmptyStateCard extends StatelessWidget {
  const EmptyStateCard({
    super.key,
    required this.title,
    required this.description,
    this.icon = Icons.inbox_outlined,
    this.buttonText,
    this.onPressed,
    this.compact = false,
  });

  final String title;
  final String description;
  final IconData icon;
  final String? buttonText;
  final VoidCallback? onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: compact ? 24 : 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: compact ? 42 : 52,
            height: compact ? 42 : 52,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF5FC),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFF4F83B7), size: compact ? 22 : 28),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.45,
            ),
            textAlign: TextAlign.center,
          ),
          if (buttonText != null && onPressed != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onPressed,
              child: Text(buttonText!),
            ),
          ],
        ],
      ),
    );
  }
}
