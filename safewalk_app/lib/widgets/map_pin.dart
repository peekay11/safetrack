import 'package:flutter/material.dart';

/// The teardrop map marker used on the Active Walk and Safety Map screens.
class MapPin extends StatelessWidget {
  const MapPin({super.key, required this.color, this.size = 16});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.785398, // -45deg
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(size / 2),
            topRight: Radius.circular(size / 2),
            bottomRight: Radius.circular(size / 2),
          ),
        ),
      ),
    );
  }
}
