import 'package:flutter/material.dart';

class SplatterModel {
  final int id;
  final Alignment alignment;
  final Color color;

  SplatterModel({
    required this.id,
    required this.alignment,
    required this.color,
  });
}

class Particle {
  final double angle;
  final double distance;
  final double size;

  Particle({
    required this.angle,
    required this.distance,
    required this.size,
  });
}
