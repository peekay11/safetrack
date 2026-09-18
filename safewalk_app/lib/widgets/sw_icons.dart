import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Raw SVG markup lifted straight from the SafeWalk UI direction mock,
/// rendered as-is so the iconography matches exactly.
class SWIcons {
  SWIcons._();

  static const _heartPath =
      'M12 21s-7.5-4.6-10.2-9.1C0.1 9.2 1.1 5.6 4.4 4.4c2-0.7 4.1 0 5.4 1.6L12 8.3l2.2-2.3c1.3-1.6 3.4-2.3 5.4-1.6 3.3 1.2 4.3 4.8 2.6 7.5C19.5 16.4 12 21 12 21z';

  static String _svg(String inner, {double size = 24}) =>
      '<svg xmlns="http://www.w3.org/2000/svg" width="$size" height="$size" viewBox="0 0 24 24">$inner</svg>';

  static SvgPicture heart({required String colorHex, double size = 24}) {
    return SvgPicture.string(
      _svg('<path d="$_heartPath" fill="$colorHex"/>', size: size),
      width: size,
      height: size,
    );
  }

  static SvgPicture findGroup({String stroke = '#7B2CBF', double size = 18}) {
    return SvgPicture.string(
      _svg(
        '<g fill="none" stroke="$stroke" stroke-width="2">'
        '<circle cx="9" cy="7" r="3"/><circle cx="17" cy="7" r="3"/>'
        '<path d="M3 20c0-3 3-5 6-5s6 2 6 5"/><path d="M13 20c0-3 2.5-5 5-5"/>'
        '</g>',
        size: size,
      ),
      width: size,
      height: size,
    );
  }

  static SvgPicture safetyMap({String stroke = '#7B2CBF', double size = 16}) {
    return SvgPicture.string(
      _svg(
        '<path d="M12 2 L20 6 V12 C20 17 16.5 20.5 12 22 C7.5 20.5 4 17 4 12 V6 Z" '
        'fill="none" stroke="$stroke" stroke-width="2"/>',
        size: size,
      ),
      width: size,
      height: size,
    );
  }

  static SvgPicture guardianLink({String stroke = '#7B2CBF', double size = 16}) {
    return SvgPicture.string(
      _svg(
        '<path d="M20.8 4.6a4.8 4.8 0 0 0-6.8 0L12 6.6l-2-2a4.8 4.8 0 1 0-6.8 6.8L12 20l8.8-8.6a4.8 4.8 0 0 0 0-6.8Z" '
        'fill="none" stroke="$stroke" stroke-width="2"/>',
        size: size,
      ),
      width: size,
      height: size,
    );
  }

  static SvgPicture verification({String stroke = '#7B2CBF', double size = 16}) {
    return SvgPicture.string(
      _svg(
        '<g fill="none" stroke="$stroke" stroke-width="2">'
        '<rect x="4" y="6" width="16" height="13" rx="2"/>'
        '<circle cx="12" cy="12.5" r="3.2"/>'
        '<path d="M9 6 L10 4 H14 L15 6"/>'
        '</g>',
        size: size,
      ),
      width: size,
      height: size,
    );
  }

  static SvgPicture profile({String stroke = '#7B2CBF', double size = 16}) {
    return SvgPicture.string(
      _svg(
        '<g fill="none" stroke="$stroke" stroke-width="2">'
        '<circle cx="12" cy="8" r="3.5"/>'
        '<path d="M5 20c0-4 3-6.5 7-6.5s7 2.5 7 6.5"/>'
        '</g>',
        size: size,
      ),
      width: size,
      height: size,
    );
  }

  static SvgPicture send({String fill = '#ffffff', double size = 14}) {
    return SvgPicture.string(
      _svg('<path d="M3 12L21 3L14 21L11 13L3 12Z" fill="$fill"/>', size: size),
      width: size,
      height: size,
    );
  }

  /// The scattered path/heart motif watermark behind the Home screen.
  static SvgPicture pathMotif({double opacity = 0.28}) {
    const transforms = <List<double>>[
      [28, 50, -18, 0.9],
      [190, 40, 35, 1.3],
      [90, 95, 60, 0.7],
      [225, 140, -40, 1.0],
      [15, 180, 15, 1.1],
      [130, 220, -70, 0.8],
      [215, 255, 20, 1.2],
      [55, 300, -25, 0.85],
      [175, 330, 50, 1.0],
      [10, 370, -55, 0.75],
      [105, 395, 10, 1.15],
      [230, 410, -15, 0.9],
      [60, 455, 65, 1.05],
      [165, 470, -30, 0.8],
      [20, 505, 40, 1.1],
      [200, 510, -45, 0.95],
    ];
    const path =
        'M11.5 6.5c-1.2-2.3-4-3-6-1.4-2 1.6-2.3 4.5-0.6 6.5C6.6 13.6 11.5 17 11.5 17s4.9-3.4 6.6-5.4c1.7-2 1.4-4.9-0.6-6.5-2-1.6-4.8-0.9-6 1.4Z';
    final paths = transforms.map((t) {
      final tx = t[0], ty = t[1], rot = t[2], scale = t[3];
      return '<path transform="translate($tx,$ty) rotate($rot) scale($scale)" d="$path"/>';
    }).join();
    final svg =
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 260 550">'
        '<g fill="#7B2CBF" opacity="$opacity">$paths</g></svg>';
    return SvgPicture.string(svg, fit: BoxFit.cover);
  }
}
