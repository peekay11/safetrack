import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../theme/colors.dart';
import 'sw_avatar.dart';

/// A real OpenStreetMap-tiled map (open-source, no API key) used wherever
/// the app needs to show live pins — safety flags, group members, a
/// destination — instead of a decorative placeholder.
class SafeWalkMap extends StatelessWidget {
  const SafeWalkMap({
    super.key,
    required this.center,
    required this.markers,
    this.zoom = 15,
    this.onTap,
    this.mapController,
  });

  final LatLng center;
  final List<Marker> markers;
  final double zoom;
  final void Function(LatLng point)? onTap;
  final MapController? mapController;

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: zoom,
        onTap: onTap == null ? null : (_, point) => onTap!(point),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.safewalk.safewalk',
          maxZoom: 19,
        ),
        MarkerLayer(markers: markers),
        const Positioned(
          right: 4,
          bottom: 4,
          child: _Attribution(),
        ),
      ],
    );
  }
}

/// Builds a teardrop pin marker at [point] in [color], matching the app's
/// existing MapPin look.
Marker pinMarker({
  required LatLng point,
  required Color color,
  double size = 30,
  VoidCallback? onTap,
}) {
  return Marker(
    point: point,
    width: size,
    height: size,
    alignment: Alignment.topCenter,
    child: GestureDetector(
      onTap: onTap,
      child: Transform.rotate(
        angle: -0.785398,
        child: Container(
          width: size * 0.7,
          height: size * 0.7,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(size * 0.35),
              topRight: Radius.circular(size * 0.35),
              bottomRight: Radius.circular(size * 0.35),
            ),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 4, offset: const Offset(0, 2)),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Builds a real profile-photo pin at [point] — used for group members and
/// the current user, so the map shows actual faces instead of generic dots.
Marker avatarMarker({
  required LatLng point,
  required String name,
  String? imageUrl,
  Color ringColor = SWColors.pink,
  bool verified = false,
  double size = 38,
  VoidCallback? onTap,
}) {
  return Marker(
    point: point,
    width: size + 10,
    height: size + 10,
    alignment: Alignment.center,
    child: GestureDetector(
      onTap: onTap,
      child: SWAvatar(name: name, imageUrl: imageUrl, size: size, ringColor: ringColor, verified: verified),
    ),
  );
}

class _Attribution extends StatelessWidget {
  const _Attribution();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        '© OpenStreetMap contributors',
        style: TextStyle(fontSize: 8, color: SWColors.inkSoft),
      ),
    );
  }
}
