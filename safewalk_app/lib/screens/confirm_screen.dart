import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';
import '../widgets/sw_icons.dart';

class ConfirmScreen extends StatelessWidget {
  const ConfirmScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final now = TimeOfDay.now();
    final timeLabel =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, SWColors.lavender],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SWIcons.heart(colorHex: '#4C1D8C', size: 64),
                  const SizedBox(height: 18),
                  Text("You're safe",
                      style: SWText.quicksand(size: 18, color: SWColors.deepPurple),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text(
                    "Your group and Guardian Angels have been notified that you've arrived.",
                    style: SWText.inter(size: 12, color: SWColors.inkSoft, height: 1.6),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(
                      color: SWColors.lavenderCard,
                      border: Border.all(color: SWColors.border),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text('Checked in · $timeLabel',
                        style: SWText.inter(size: 11, weight: FontWeight.w600, color: SWColors.deepPurple)),
                  ),
                  const SizedBox(height: 28),
                  TextButton(
                    onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                    child: Text('Back to Home',
                        style: SWText.quicksand(size: 13, color: SWColors.violet)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
