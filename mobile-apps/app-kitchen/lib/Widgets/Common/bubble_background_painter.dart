import 'dart:math';
import 'package:flutter/material.dart';

class BubbleBackgroundPainter extends CustomPainter {
  final int numberOfBubbles;
  final Color bubbleColor;
  final double maxBubbleSize;
  final double minBubbleSize;

  BubbleBackgroundPainter({
    this.numberOfBubbles = 20,
    this.bubbleColor = Colors.white, // Bubbles are typically white or light
    this.maxBubbleSize = 60.0,
    this.minBubbleSize = 10.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(123); // Seed for consistent "randomness" on rebuilds
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < numberOfBubbles; i++) {
      // Vary opacity for a softer look
      final double opacity = random.nextDouble() * 0.3 + 0.05; // Opacity between 0.05 and 0.35
      paint.color = bubbleColor.withOpacity(opacity);

      final double x = random.nextDouble() * size.width;
      final double y = random.nextDouble() * size.height;
      final double radius = random.nextDouble() * (maxBubbleSize - minBubbleSize) + minBubbleSize;

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    // If painter properties (like colors, number of bubbles) change, then repaint.
    // For now, assuming static bubbles, but could be made dynamic.
    if (oldDelegate is BubbleBackgroundPainter) {
      return oldDelegate.numberOfBubbles != numberOfBubbles ||
             oldDelegate.bubbleColor != bubbleColor ||
             oldDelegate.maxBubbleSize != maxBubbleSize ||
             oldDelegate.minBubbleSize != minBubbleSize;
    }
    return false; 
  }
} 