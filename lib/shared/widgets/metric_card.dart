import 'package:flutter/material.dart';

import '../../app/theme.dart';

class MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconBg;
  final Color iconFg;
  final String? footer;
  final String? footerAction;
  final VoidCallback? onTap;
  final bool hero;

  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.iconBg = AppColors.teal50,
    this.iconFg = AppColors.teal600,
    this.footer,
    this.footerAction,
    this.onTap,
    this.hero = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = hero ? AppColors.slate900 : Colors.white;
    final fg = hero ? Colors.white : AppColors.slate900;
    final subFg = hero ? AppColors.slate400 : AppColors.slate500;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(hero ? 30 : 8),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: hero ? Colors.white.withAlpha(25) : iconBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    icon,
                    size: 16,
                    color: hero ? Colors.white : iconFg,
                  ),
                ),
                const Spacer(),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: subFg,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: fg,
              ),
            ),
            if (footer != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(footer!, style: TextStyle(fontSize: 11, color: subFg)),
                  if (footerAction != null) ...[
                    const SizedBox(width: 4),
                    Text(
                      footerAction!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: hero ? Colors.white : AppColors.teal600,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
