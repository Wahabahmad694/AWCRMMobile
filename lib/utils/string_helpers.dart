import 'package:flutter/material.dart';
import 'app_colors.dart';

class StringHelpers {
  StringHelpers._();

  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  static String titleCase(String text) {
    if (text.isEmpty) return text;
    return text
        .replaceAll(RegExp(r'[_-\s]+'), ' ')
        .split(' ')
        .map((w) => capitalize(w))
        .join(' ');
  }

  static String initials(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return 'AW';
    final parts = clean.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return clean.substring(0, clean.length >= 2 ? 2 : 1).toUpperCase();
  }

  /// Color pair for status badges (textColor, backgroundColor)
  static (Color, Color) statusColors(String status) {
    final s = status.toLowerCase().replaceAll(' ', '_');
    switch (s) {
      case 'active':
      case 'confirmed':
      case 'paid':
      case 'fulfilled':
      case 'completed':
      case 'success':
        return (AppColors.greenIcon, AppColors.greenIconBg);

      case 'pending':
      case 'processing':
      case 'draft':
      case 'partially_paid':
      case 'in_progress':
        return (AppColors.orangeIcon, AppColors.orangeIconBg);

      case 'cancelled':
      case 'void':
      case 'expired':
      case 'failed':
      case 'disabled':
      case 'overdue':
        return (AppColors.redIcon, AppColors.redIconBg);

      case 'trialing':
      case 'lead':
      case 'customer':
      case 'note':
        return (AppColors.blueIcon, AppColors.blueIconBg);

      case 'returned':
      case 'refunded':
      case 'reversed':
        return (AppColors.violetIcon, AppColors.violetIconBg);

      default:
        return (AppColors.textSecondary, AppColors.border);
    }
  }
}
