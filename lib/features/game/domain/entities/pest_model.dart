import 'package:flutter/material.dart';

class PestModel {
  final int id;
  final Alignment alignment;
  final Offset startOffset;
  final double size;
  final Color color;
  bool isHit;

  PestModel({
    required this.id,
    required this.alignment,
    required this.startOffset,
    required this.color,
    this.size = 150.0,
    this.isHit = false,
  });
}
