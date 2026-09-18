import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';

/// A profile avatar: shows the person's real selfie when one is on file,
/// otherwise a gradient initials badge — used anywhere the app shows who's
/// in a group (roster stacks, chat, profile header).
class SWAvatar extends StatelessWidget {
  const SWAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 40,
    this.verified = false,
    this.ringColor,
  });

  final String name;
  final String? imageUrl;
  final double size;
  final bool verified;
  final Color? ringColor;

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final first = parts.first[0];
    final second = parts.length > 1 ? parts[1][0] : '';
    return (first + second).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    return SizedBox(
      width: size + 6,
      height: size + 6,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: ringColor ?? Colors.white, width: 2.5),
              gradient: hasImage
                  ? null
                  : const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [SWColors.violet, SWColors.pink],
                    ),
              image: hasImage
                  ? DecorationImage(image: NetworkImage(imageUrl!), fit: BoxFit.cover)
                  : null,
              boxShadow: [
                BoxShadow(color: SWColors.deepPurple.withValues(alpha: 0.18), blurRadius: 8, offset: const Offset(0, 3)),
              ],
            ),
            alignment: Alignment.center,
            child: hasImage
                ? null
                : Text(_initials, style: SWText.quicksand(size: size * 0.36, color: Colors.white)),
          ),
          if (verified)
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                padding: const EdgeInsets.all(1.5),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: Icon(Icons.verified_rounded, size: size * 0.34, color: SWColors.safe),
              ),
            ),
        ],
      ),
    );
  }
}
