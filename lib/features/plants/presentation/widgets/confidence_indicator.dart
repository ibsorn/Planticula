import 'package:flutter/material.dart';
import 'package:planticula/core/theme/app_colors.dart';

/// Tamaños disponibles para el indicador de confianza
enum ConfidenceSize { small, medium, large }

/// Widget que muestra visualmente el nivel de confianza
/// de un campo identificado por IA
class ConfidenceIndicator extends StatelessWidget {
  final double confidence;
  final ConfidenceSize size;

  const ConfidenceIndicator({
    super.key,
    required this.confidence,
    this.size = ConfidenceSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    final (color, label) = _getConfidenceInfo(confidence);

    switch (size) {
      case ConfidenceSize.small:
        return _buildSmallIndicator(color);
      case ConfidenceSize.medium:
        return _buildMediumIndicator(color, label);
      case ConfidenceSize.large:
        return _buildLargeIndicator(color, label);
    }
  }

  Widget _buildSmallIndicator(Color color) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildMediumIndicator(Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getIconForConfidence(confidence),
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLargeIndicator(Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getIconForConfidence(confidence),
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            '$label (${(confidence * 100).round()}%)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  (Color, String) _getConfidenceInfo(double confidence) {
    final percentage = (confidence * 100).round();
    if (confidence >= 0.8) {
      return (AppColors.success, 'Seguro $percentage%');
    } else if (confidence >= 0.6) {
      return (AppColors.warning, 'Probable $percentage%');
    } else {
      return (AppColors.error, 'Revisar $percentage%');
    }
  }

  IconData _getIconForConfidence(double confidence) {
    if (confidence >= 0.8) {
      return Icons.verified;
    } else if (confidence >= 0.6) {
      return Icons.help_outline;
    } else {
      return Icons.warning_amber_outlined;
    }
  }
}

/// Widget extendido que muestra el indicador con tooltip
class ConfidenceIndicatorWithTooltip extends StatelessWidget {
  final double confidence;
  final ConfidenceSize size;
  final String? tooltipText;

  const ConfidenceIndicatorWithTooltip({
    super.key,
    required this.confidence,
    this.size = ConfidenceSize.medium,
    this.tooltipText,
  });

  @override
  Widget build(BuildContext context) {
    final tooltip = tooltipText ?? _buildDefaultTooltip(confidence);

    return Tooltip(
      message: tooltip,
      child: ConfidenceIndicator(
        confidence: confidence,
        size: size,
      ),
    );
  }

  String _buildDefaultTooltip(double confidence) {
    final percentage = (confidence * 100).round();
    if (confidence >= 0.8) {
      return 'La IA está muy segura de esta identificación ($percentage%).';
    } else if (confidence >= 0.6) {
      return 'La IA cree que probablemente es correcto ($percentage%), pero revisa por si acaso.';
    } else {
      return 'La IA no está segura ($percentage%). Por favor, verifica y corrige este dato.';
    }
  }
}
