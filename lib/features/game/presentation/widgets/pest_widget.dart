import 'package:flutter/material.dart';
import '../../domain/entities/pest_model.dart';

class PestWidget extends StatefulWidget {
  final PestModel pest;
  final VoidCallback onTap;

  const PestWidget({super.key, required this.pest, required this.onTap});

  @override
  State<PestWidget> createState() => _PestWidgetState();
}

class _PestWidgetState extends State<PestWidget> with SingleTickerProviderStateMixin {
  late AnimationController _entranceController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: widget.pest.startOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entranceController, curve: Curves.easeOutBack));

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _entranceController, curve: Curves.bounceOut));

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: widget.pest.alignment,
      child: SlideTransition(
        position: _slideAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: GestureDetector(
            onTapDown: (_) => widget.onTap(),
            child: SizedBox(
              width: widget.pest.size,
              height: widget.pest.size,
              child: Image.asset(widget.pest.imagePath),
            ),
          ),
        ),
      ),
    );
  }
}
