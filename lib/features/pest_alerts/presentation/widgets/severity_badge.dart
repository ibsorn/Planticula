import 'package:flutter/material.dart';
import 'package:planticula/features/pest_alerts/domain/entities/pest_alert.dart';

class SeverityBadge extends StatelessWidget {
  final Severity severity;

  const SeverityBadge({super.key, required this.severity});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Color(severity.colorValue),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        severity.displayName,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
