import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';

/// Shown whenever the backend reports `fallback_to_guardian: true` — no
/// group was found, so the Guardian Angel escort fallback fired. Confirms
/// to the user exactly who was (mock) notified via SMS/WhatsApp.
Future<void> showGuardianAlertDialog(
  BuildContext context, {
  required bool isTaxi,
  Map<String, dynamic>? notification,
}) {
  final guardians = ((notification?['notified_guardians'] as List?) ?? []).cast<Map<String, dynamic>>();

  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Guardian Angel alerted', style: SWText.quicksand(size: 15, color: SWColors.deepPurple)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            guardians.isEmpty
                ? "We couldn't find a ${isTaxi ? 'taxi' : 'walking'} group yet, so we've sent your drop-off point via SMS/WhatsApp — but you don't have a Guardian Angel saved to receive it."
                : "We couldn't find a ${isTaxi ? 'taxi' : 'walking'} group yet, so we've sent your drop-off point via SMS/WhatsApp to:",
            style: SWText.inter(size: 12, color: SWColors.inkSoft, height: 1.5),
          ),
          for (final g in guardians)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, size: 14, color: SWColors.safe),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text('${g['name']} · ${g['phone_number']}',
                        style: SWText.inter(size: 11, weight: FontWeight.w600, color: SWColors.ink)),
                  ),
                ],
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text('OK, continue', style: SWText.quicksand(size: 13, color: SWColors.violet)),
        ),
      ],
    ),
  );
}
