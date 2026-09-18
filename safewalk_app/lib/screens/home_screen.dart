import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';
import '../widgets/glass_card.dart';
import '../widgets/sw_icons.dart';
import 'active_walk_screen.dart';
import 'guardians_screen.dart';
import 'profile_screen.dart';
import 'safety_map_screen.dart';
import 'verification_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SWColors.lavenderMid,
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(opacity: 0.28, child: SWIcons.pathMotif()),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Good morning 👋', style: SWText.quicksand(size: 19, color: SWColors.deepPurple)),
                  const SizedBox(height: 2),
                  Text('Ready to find your walking group?',
                      style: SWText.inter(size: 12, color: SWColors.inkSoft)),
                  const SizedBox(height: 18),
                  GlassCard(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ActiveWalkScreen()),
                    ),
                    margin: const EdgeInsets.only(bottom: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            SWIcons.findGroup(size: 18),
                            const SizedBox(width: 8),
                            Text('Find a Group',
                                style: SWText.quicksand(size: 15, color: SWColors.deepPurple)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('Match with others heading your way',
                            style: SWText.inter(size: 11, color: SWColors.inkSoft)),
                      ],
                    ),
                  ),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.5,
                    children: [
                      _MiniCard(
                        icon: SWIcons.safetyMap(size: 16),
                        title: 'Safety Map',
                        subtitle: 'Flagged areas nearby',
                        onTap: () => Navigator.of(context)
                            .push(MaterialPageRoute(builder: (_) => const SafetyMapScreen())),
                      ),
                      _MiniCard(
                        icon: SWIcons.guardianLink(size: 16),
                        title: 'Guardian Angels',
                        subtitle: 'Your trusted 4',
                        onTap: () => Navigator.of(context)
                            .push(MaterialPageRoute(builder: (_) => const GuardiansScreen())),
                      ),
                      _MiniCard(
                        icon: SWIcons.verification(size: 16),
                        title: 'Verification',
                        subtitle: 'Selfie & ID status',
                        onTap: () => Navigator.of(context)
                            .push(MaterialPageRoute(builder: (_) => const VerificationScreen())),
                      ),
                      _MiniCard(
                        icon: SWIcons.profile(size: 16),
                        title: 'My Profile',
                        subtitle: 'History & reviews',
                        onTap: () => Navigator.of(context)
                            .push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  const _MiniCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final Widget icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      opacity: 0.55,
      blur: 8,
      borderRadius: 14,
      padding: const EdgeInsets.all(12),
      boxShadow: [
        BoxShadow(color: SWColors.deepPurple.withValues(alpha: 0.08), blurRadius: 14, offset: const Offset(0, 4)),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(9),
            ),
            child: icon,
          ),
          const SizedBox(height: 8),
          Text(title, style: SWText.inter(size: 12, weight: FontWeight.w600, color: SWColors.ink)),
          const SizedBox(height: 3),
          Text(subtitle, style: SWText.inter(size: 10, color: SWColors.inkSoft)),
        ],
      ),
    );
  }
}
