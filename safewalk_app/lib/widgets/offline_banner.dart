import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';

/// Shown whenever a screen has fallen back to demo/mock data because the
/// backend request failed — keeps that fact visible instead of silently
/// passing off sample data as real.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({
    super.key,
    this.message = "Showing demo data — couldn't reach the SafeWalk server.",
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: SWColors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SWColors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, size: 14, color: SWColors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: SWText.inter(size: 9.5, weight: FontWeight.w600, color: SWColors.orange)),
          ),
          if (onRetry != null)
            GestureDetector(
              onTap: onRetry,
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text('Retry',
                    style: SWText.inter(size: 9.5, weight: FontWeight.w700, color: SWColors.deepPurple)),
              ),
            ),
        ],
      ),
    );
  }
}
