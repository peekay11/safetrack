import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';
import '../widgets/map_pin.dart';
import '../widgets/sos_safe_buttons.dart';
import 'chat_screen.dart';
import 'confirm_screen.dart';
import 'ehailing_screen.dart';

class ActiveWalkScreen extends StatelessWidget {
  const ActiveWalkScreen({super.key});

  void _sendSos(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('SOS alert sent', style: SWText.quicksand(size: 16, color: SWColors.danger)),
        content: Text(
          'Your Guardian Angels and walking group have been notified of your location.',
          style: SWText.inter(size: 13, color: SWColors.inkSoft),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('OK', style: SWText.quicksand(size: 13, color: SWColors.violet)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const members = ['Lindiwe', 'Naledi', 'Zanele'];

    return Scaffold(
      backgroundColor: const Color(0xFFEFE9F7),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back, color: SWColors.deepPurple),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => Navigator.of(context)
                        .push(MaterialPageRoute(builder: (_) => const EhailingScreen())),
                    icon: const Icon(Icons.local_taxi, size: 16, color: SWColors.violet),
                    label: Text('E-Hailing', style: SWText.inter(size: 11, weight: FontWeight.w600, color: SWColors.violet)),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context)
                        .push(MaterialPageRoute(builder: (_) => const ChatScreen())),
                    icon: const Icon(Icons.chat_bubble_outline, color: SWColors.violet),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(-0.4, -0.4),
                          radius: 0.8,
                          colors: [SWColors.violet.withValues(alpha: 0.10), Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0.4, 0.2),
                          radius: 0.9,
                          colors: [SWColors.pink.withValues(alpha: 0.08), Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                  const DecoratedBox(decoration: BoxDecoration(color: SWColors.lavender)),
                  LayoutBuilder(builder: (context, c) {
                    return Stack(
                      children: [
                        Positioned(
                          top: c.maxHeight * 0.18,
                          left: c.maxWidth * 0.38,
                          child: const MapPin(color: SWColors.violet),
                        ),
                        Positioned(
                          top: c.maxHeight * 0.32,
                          left: c.maxWidth * 0.23,
                          child: const MapPin(color: SWColors.pink),
                        ),
                        Positioned(
                          top: c.maxHeight * 0.44,
                          left: c.maxWidth * 0.57,
                          child: const MapPin(color: SWColors.pink),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: GestureDetector(
                onTap: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const ChatScreen())),
                child: Row(
                  children: members
                      .map((m) => Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: SWColors.lavenderCard,
                                border: Border.all(color: SWColors.border),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(m,
                                  style: SWText.inter(size: 10, weight: FontWeight.w600, color: SWColors.ink)),
                            ),
                          ))
                      .toList(),
                ),
              ),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SosButton(onTap: () => _sendSos(context)),
                  SafeButton(
                    label: 'I Am Safe',
                    onTap: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const ConfirmScreen()),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
