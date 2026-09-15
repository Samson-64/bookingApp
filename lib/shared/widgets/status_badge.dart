import 'package:flutter/material.dart';
import '../../app/theme.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final double fontSize;

  const StatusBadge({super.key, required this.status, this.fontSize = 11});

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = _style(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 6, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  (Color, Color, String) _style(String s) {
    return switch (s) {
      'PENDING' => (AppColors.amber50, AppColors.amber600, 'Pending'),
      'CONFIRMED' => (AppColors.emerald50, AppColors.emerald600, 'Confirmed'),
      'COMPLETED' => (const Color(0xFFDBEAFE), AppColors.indigo600, 'Completed'),
      'CANCELLED' => (AppColors.rose50, AppColors.rose600, 'Cancelled'),
      _ => (AppColors.slate100, AppColors.slate500, s),
    };
  }
}
