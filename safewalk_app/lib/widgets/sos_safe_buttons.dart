import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';

class SosButton extends StatelessWidget {
  const SosButton({super.key, required this.onTap, this.size = 62});

  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: SWColors.danger,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: SWColors.danger.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Text(
          'SOS',
          style: SWText.quicksand(size: size > 58 ? 13 : 11, weight: FontWeight.w700, color: Colors.white),
        ),
      ),
    );
  }
}

class SafeButton extends StatelessWidget {
  const SafeButton({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SWColors.safe,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Text(
            label,
            style: SWText.quicksand(size: 12, weight: FontWeight.w700, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
