import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';
import '../widgets/sw_icons.dart';
import 'home_screen.dart';

class LaunchScreen extends StatefulWidget {
  const LaunchScreen({super.key});

  @override
  State<LaunchScreen> createState() => _LaunchScreenState();
}

class _LaunchScreenState extends State<LaunchScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1800), _goHome);
  }

  void _goHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _goHome,
      child: Scaffold(
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.0, 0.6],
              colors: [SWColors.deepPurple, SWColors.violet],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SWIcons.heart(colorHex: '#ffffff', size: 58),
                const SizedBox(height: 14),
                Text('SafeWalk', style: SWText.quicksand(size: 24, color: Colors.white)),
                const SizedBox(height: 6),
                Text(
                  'walk together, arrive safe',
                  style: SWText.inter(size: 12, color: Colors.white.withValues(alpha: 0.85), letterSpacing: 0.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
