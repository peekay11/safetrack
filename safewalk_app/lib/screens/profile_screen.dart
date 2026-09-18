import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';
import '../widgets/sw_icons.dart';
import 'resources_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(color: SWColors.lavenderMid, shape: BoxShape.circle),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Your Name', style: SWText.quicksand(size: 15, color: SWColors.ink)),
                    const SizedBox(height: 3),
                    Text('✅ Verified · ⭐ 4.9 rating', style: SWText.inter(size: 11, color: SWColors.inkSoft)),
                  ],
                ),
              ],
            ),
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
