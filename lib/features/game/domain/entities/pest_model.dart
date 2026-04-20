import 'package:flutter/material.dart';

class PestModel {
  final int id;
  final Alignment alignment;
  final Offset startOffset;
  final double size;
  final String imagePath;
  bool isHit;

  PestModel({
    required this.id,
    required this.alignment,
    required this.startOffset,
    required this.imagePath,
    this.size = 120.0,
    this.isHit = false,
  });
}
