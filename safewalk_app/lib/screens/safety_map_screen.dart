import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';

class SafetyMapScreen extends StatelessWidget {
  const SafetyMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SWColors.lavender,
      appBar: AppBar(
        backgroundColor: SWColors.lavender,
        elevation: 0,
        iconTheme: const IconThemeData(color: SWColors.deepPurple),
        title: Text('Safety Map', style: SWText.quicksand(size: 15, color: SWColors.deepPurple)),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(-0.5, -0.4),
                          radius: 0.3,
                          colors: [SWColors.danger.withValues(alpha: 0.18), Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0.2, 0.1),
                          radius: 0.3,
                          colors: [SWColors.orange.withValues(alpha: 0.18), Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0.5, -0.5),
                          radius: 0.25,
                          colors: [SWColors.orange.withValues(alpha: 0.15), Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                  LayoutBuilder(builder: (context, c) {
                    return Stack(
                      children: [
                        _Zone(top: c.maxHeight * 0.17, left: c.maxWidth * 0.15, size: 70,
                            fill: SWColors.danger.withValues(alpha: 0.28), border: SWColors.danger),
                        _Zone(top: c.maxHeight * 0.44, left: c.maxWidth * 0.5, size: 54,
                            fill: SWColors.orange.withValues(alpha: 0.28), border: SWColors.orange),
                        _Zone(top: c.maxHeight * 0.26, left: c.maxWidth * 0.67, size: 46,
                            fill: SWColors.orange.withValues(alpha: 0.28), border: SWColors.orange),
                      ],
                    );
                  }),
                ],
              ),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Legend(color: SWColors.danger, label: 'Red'),
                  const SizedBox(width: 16),
                  _Legend(color: SWColors.orange, label: 'Orange'),
                  const SizedBox(width: 16),
                  _Legend(color: SWColors.safe, label: 'Clear'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Zone extends StatelessWidget {
  const _Zone({required this.top, required this.left, required this.size, required this.fill, required this.border});
  final double top, left, size;
  final Color fill, border;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: fill, border: Border.all(color: border, width: 1.5)),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 9, height: 9, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        const SizedBox(width: 5),
        Text(label, style: SWText.inter(size: 10, weight: FontWeight.w600, color: SWColors.inkSoft)),
      ],
    );
  }
}
