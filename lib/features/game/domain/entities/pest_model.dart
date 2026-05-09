import 'package:flutter/material.dart';

class PestModel {
  final int id;
  final Alignment alignment;
  final Offset startOffset;
  final double size;
  final Color color;
  final double driftSpeedMultiplier;
  bool isHit;

  PestModel({
    required this.id,
    required this.alignment,
    required this.startOffset,
    required this.color,
    this.size = 96.0,
    this.driftSpeedMultiplier = 1.0,
    this.isHit = false,
  });
}

class HitRecord {
  final double x;
  final double y;
  final DateTime time;

  const HitRecord({
    required this.x,
    required this.y,
    required this.time,
  });
}
