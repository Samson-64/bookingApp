
import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Bottom sheet showing a booking's details (and an optional confirm action),
/// shared by the detail sheets on the dashboard, My Bookings and the
/// appointment wizard so their layout stays consistent.
class BookingSummarySheet extends StatelessWidget {
  const BookingSummarySheet({
    super.key,
    required this.title,
    required this.rows,
    this.monoValues = const {},
    this.onConfirm,
    this.confirming = false,
    this.confirmLabel,
    this.bottomPadding = 0,
  });

  final String title;
  final List<(String, String)> rows;

  /// Row labels whose values render in the monospaced reference style.
  final Set<String> monoValues;

  /// When null the sheet shows a Close button instead of a confirm action.
  final VoidCallback? onConfirm;
  final bool confirming;
  final String? confirmLabel;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomPadding),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.slate200,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          for (final (label, value) in rows)
            _SummaryRow(
              label: label,
              value: value,
              mono: monoValues.contains(label),
            ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: onConfirm != null
                ? ElevatedButton(
                    onPressed: confirming ? null : onConfirm,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: confirming
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(confirmLabel ?? 'Confirm'),
                  )
                : OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: const Text('Close'),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    required this.mono,
  });

  final String label;
  final String value;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppColors.slate500),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: mono
                  ? AppType.monoRef.copyWith(
                      color: AppColors.slate900,
                      fontWeight: FontWeight.w600,
                    )
                  : const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate900,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}