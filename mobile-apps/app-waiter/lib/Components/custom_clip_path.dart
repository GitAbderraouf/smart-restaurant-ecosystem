// File: waiter_app/lib/Components/custom_clip_path.dart
import 'package:flutter/material.dart';

// Custom Clipper from kitchen_app (originally in home.dart / kitchen_screen.dart)
class CustomClipPath extends CustomClipper<Path> {
  final double radius;
  final int teethCount;
  // final double toothHeight; // If you prefer this name

  CustomClipPath({this.radius = 10.0, this.teethCount = 20 /*, this.toothHeight = 10.0 */});

  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height);
    if (teethCount > 0) {
      var curXPos = 0.0;
      var curYPos = size.height;
      // Use radius or a separate toothHeight parameter for the depth of the teeth
      final double actualToothHeight = radius; // Or this.toothHeight
      final increment = size.width / teethCount;

      for (int i = 0; i < teethCount; i++) {
        curXPos += increment;
        curYPos = (i % 2 == 0) ? size.height - actualToothHeight : size.height;
        path.lineTo(curXPos, curYPos);
      }
    } else {
      path.lineTo(size.width, size.height);
    }
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return true; // Or false if properties don't change, or compare properties
  }
}