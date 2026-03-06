import 'package:flutter/material.dart';

import '../../../domain/entities/drawing_entity.dart';

/// Grid tile showing a thumbnail of a failed drawing from the Data Flywheel.
class DrawingCard extends StatelessWidget {
  const DrawingCard({required this.entity, super.key, this.onTap});

  final DrawingEntity entity;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          color: Colors.white,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.memory(
                entity.imageBytes,
                fit: BoxFit.contain,
              ),
              Positioned(
                right: 6,
                bottom: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _formatDate(entity.capturedAt),
                    style: const TextStyle(
                        color: Colors.white, fontSize: 10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}';
}
