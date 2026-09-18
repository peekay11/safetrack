import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/colors.dart';

/// Frosted glass card used on the Home screen (primary + mini cards),
/// matching the `backdrop-filter: blur(...)` translucent cards in the mock.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.opacity = 0.6,
    this.blur = 10,
    this.borderRadius = 18,
    this.padding = const EdgeInsets.all(18),
    this.margin,
    this.boxShadow,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double opacity;
  final double blur;
  final double borderRadius;
  final EdgeInsets padding;
  final EdgeInsets? margin;
  final List<BoxShadow>? boxShadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: boxShadow ??
            [
              BoxShadow(
                color: SWColors.deepPurple.withValues(alpha: 0.14),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Material(
            color: Colors.white.withValues(alpha: opacity),
            child: InkWell(
              onTap: onTap,
              child: Container(
                padding: padding,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(borderRadius),
                  border: Border.all(color: Colors.white.withValues(alpha: opacity)),
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
