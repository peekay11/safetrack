import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';

class _Resource {
  const _Resource(this.name, this.desc, this.number);
  final String name, desc, number;
}

const _resources = [
  _Resource('SAPS Emergency', 'Police, immediate danger', '10111'),
  _Resource('GBV Command Centre', "24/7 · SMS 'help' to 31531", '0800 428 428'),
  _Resource('Stop Gender Violence', 'All 11 official languages', '0800 150 150'),
  _Resource('Lifeline South Africa', 'Counselling support', '0861 322 322'),
  _Resource('POWA', 'People Opposing Woman Abuse', '011 642 4345'),
];

class ResourcesScreen extends StatelessWidget {
  const ResourcesScreen({super.key});

  Future<void> _call(BuildContext context, String number) async {
    final uri = Uri(scheme: 'tel', path: number.replaceAll(' ', ''));
    final launched = await launchUrl(uri);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Calling $number…')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SWColors.pageBg,
      appBar: AppBar(
        backgroundColor: SWColors.pageBg,
        elevation: 0,
        iconTheme: const IconThemeData(color: SWColors.deepPurple),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
          children: [
            Text('Safety Resources', style: SWText.quicksand(size: 16, color: SWColors.deepPurple)),
            const SizedBox(height: 12),
            for (final r in _resources)
              GestureDetector(
                onTap: () => _call(context, r.number),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 9),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: SWColors.border),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(color: SWColors.deepPurple.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.name, style: SWText.inter(size: 11, weight: FontWeight.w700, color: SWColors.ink)),
                            const SizedBox(height: 2),
                            Text(r.desc, style: SWText.inter(size: 9.5, color: SWColors.inkSoft)),
                          ],
                        ),
                      ),
                      Text(r.number, style: SWText.inter(size: 12, weight: FontWeight.w700, color: SWColors.violet)),
                    ],
                  ),
                ),
              ),
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: SWColors.lavender, borderRadius: BorderRadius.circular(10)),
              child: Text(
                'Women For Change (Purple Movement) offers support and advocacy via their social channels and website rather than a phone line — linked here as a resource, alongside the emergency numbers above.',
                style: SWText.inter(size: 9.5, color: SWColors.inkSoft, height: 1.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
