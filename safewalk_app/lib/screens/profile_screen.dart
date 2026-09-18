import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../services/api_client.dart';
import '../services/api_service.dart';
import '../services/app_session.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';
import '../widgets/sw_avatar.dart';
import '../widgets/sw_icons.dart';
import 'auth_screen.dart';
import 'resources_screen.dart';
import 'verification_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final res = await Api.me();
      await AppSession.instance.updateCurrentUser(res['user'] as Map<String, dynamic>);
      if (mounted) setState(() {});
    } on ApiException {
      // Fall back to the cached profile already held in AppSession.
    }
  }

  Future<void> _signOut() async {
    await AppSession.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AppSession.instance.currentUser;

    return Scaffold(
      backgroundColor: SWColors.pageBg,
      appBar: AppBar(
        backgroundColor: SWColors.pageBg,
        elevation: 0,
        iconTheme: const IconThemeData(color: SWColors.deepPurple),
        actions: [
          IconButton(
            tooltip: 'Safety Resources',
            icon: SWIcons.safetyMap(stroke: '#7B2CBF', size: 20),
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const ResourcesScreen())),
          ),
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout, color: SWColors.deepPurple, size: 20),
            onPressed: _signOut,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
          children: [
            Row(
              children: [
                SWAvatar(
                  name: user?.fullName ?? '?',
                  imageUrl: ApiConfig.mediaUrl(user?.selfieUrl),
                  size: 60,
                  verified: user?.verified ?? false,
                  ringColor: SWColors.lavenderMid,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.fullName ?? 'Your Name', style: SWText.quicksand(size: 15, color: SWColors.ink)),
                      const SizedBox(height: 3),
                      Text(
                        user?.phoneNumber ?? '',
                        style: SWText.inter(size: 11, color: SWColors.inkSoft),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        (user?.verified ?? false) ? '✅ Verified' : '⏳ Not yet verified',
                        style: SWText.inter(size: 11, color: SWColors.inkSoft),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (user?.selfieUrl == null) ...[
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const VerificationScreen()))
                    .then((_) => _refresh()),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [SWColors.violet, SWColors.pink]),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(color: SWColors.deepPurple.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Add a profile photo',
                                style: SWText.quicksand(size: 12.5, color: Colors.white)),
                            const SizedBox(height: 2),
                            Text('So your walking group can recognise you',
                                style: SWText.inter(size: 9.5, color: Colors.white.withValues(alpha: 0.9))),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 22),
            Text('Walk History', style: SWText.quicksand(size: 13, color: SWColors.deepPurple)),
            const SizedBox(height: 10),
            _HistoryCard(dest: 'Pimville Taxi Rank', date: '2 Jul 2026', members: 'With: Lindiwe, Naledi, You'),
            _HistoryCard(dest: 'Dobsonville Mall', date: '1 Jul 2026', members: 'With: Zanele, You'),
          ],
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.dest, required this.date, required this.members});
  final String dest, date, members;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: SWColors.border),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: SWColors.deepPurple.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(dest, style: SWText.inter(size: 12, weight: FontWeight.w700, color: SWColors.ink)),
          const SizedBox(height: 2),
          Text(date, style: SWText.inter(size: 10, color: SWColors.inkSoft)),
          const SizedBox(height: 4),
          Text(members, style: SWText.inter(size: 10, color: SWColors.inkSoft)),
        ],
      ),
    );
  }
}
