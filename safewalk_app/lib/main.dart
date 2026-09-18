import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/launch_screen.dart';
import 'theme/colors.dart';

void main() {
  runApp(const SafeWalkApp());
}

class SafeWalkApp extends StatelessWidget {
  const SafeWalkApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: SWColors.pageBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: SWColors.violet,
        primary: SWColors.violet,
        secondary: SWColors.pink,
        error: SWColors.danger,
      ),
      textTheme: GoogleFonts.interTextTheme(),
    );

    return MaterialApp(
      title: 'SafeWalk',
      debugShowCheckedModeBanner: false,
      theme: base,
      home: const LaunchScreen(),
    );
  }
}
