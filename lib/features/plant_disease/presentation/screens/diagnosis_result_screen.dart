import 'package:flutter/material.dart';
import 'package:planticula/core/theme/app_colors.dart';
import 'package:planticula/core/theme/app_dimens.dart';
import 'package:planticula/features/plant_disease/domain/entities/plant_disease_diagnosis.dart';

/// Full-screen result screen shown after a diagnosis completes.
///
/// Displays:
/// - Problem name, type and severity
/// - AI description
/// - Ordered remedies (homemade → organic → chemical)
/// - Prevention tips
class DiagnosisResultScreen extends StatelessWidget {
  final PlantDiseaseDiagnosis diagnosis;

  const DiagnosisResultScreen({super.key, required this.diagnosis});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isHealthy = diagnosis.isHealthy;
    final severityColor = diagnosis.severity != null
        ? Color(diagnosis.severity!.colorValue)
        : AppColors.primary;
    final headerColor = isHealthy ? AppColors.primary : severityColor;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── AppBar ──────────────────────────────────────────────────────────
          SliverAppBar.large(
            title: Text(
              isHealthy ? 'Planta Sana' : 'Diagnóstico',
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
            centerTitle: false,
          ),

          SliverPadding(
            padding: const EdgeInsets.all(AppDimens.lg),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Header card ────────────────────────────────────────────
                _HeaderCard(
                  diagnosis: diagnosis,
                  headerColor: headerColor,
                ),
                const SizedBox(height: AppDimens.lg),

                // ── Description ────────────────────────────────────────────
                if (diagnosis.description != null &&
                    diagnosis.description!.isNotEmpty) ...[
                  _SectionTitle(title: 'Descripción'),
                  const SizedBox(height: AppDimens.sm),
                  Text(
                    diagnosis.description!,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppDimens.xl),
                ],

                // ── Remedies ───────────────────────────────────────────────
                if (diagnosis.remedies.isNotEmpty) ...[
                  _SectionTitle(
                    title: isHealthy
                        ? 'Consejos de mantenimiento'
                        : 'Remedios recomendados',
                    subtitle: isHealthy
                        ? null
                        : 'Métodos caseros primero, más accesibles y económicos',
                  ),
                  const SizedBox(height: AppDimens.md),
                  ...diagnosis.remedies
                      .map((r) => _RemedyCard(remedy: r))
                      .toList(),
                  const SizedBox(height: AppDimens.xl),
                ],

                // ── Prevention ─────────────────────────────────────────────
                if (diagnosis.preventionTips != null &&
                    diagnosis.preventionTips!.isNotEmpty) ...[
                  _SectionTitle(title: 'Prevención'),
                  const SizedBox(height: AppDimens.sm),
                  _InfoCard(
                    icon: Icons.shield_outlined,
                    color: AppColors.primary,
                    text: diagnosis.preventionTips!,
                  ),
                  const SizedBox(height: AppDimens.xl),
                ],

                // ── Notes ──────────────────────────────────────────────────
                if (diagnosis.analysisNotes != null &&
                    diagnosis.analysisNotes!.isNotEmpty) ...[
                  _SectionTitle(title: 'Notas del análisis'),
                  const SizedBox(height: AppDimens.sm),
                  Text(
                    diagnosis.analysisNotes!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: AppDimens.xxl),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Header card
// =============================================================================

class _HeaderCard extends StatelessWidget {
  final PlantDiseaseDiagnosis diagnosis;
  final Color headerColor;

  const _HeaderCard({required this.diagnosis, required this.headerColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = AppColors.softOf(context, headerColor, headerColor.withValues(alpha: 0.1));
    final fg = AppColors.onSoftOf(context, headerColor, headerColor);

    return Container(
      padding: const EdgeInsets.all(AppDimens.xl),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppDimens.cardRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimens.md),
                decoration: BoxDecoration(
                  color: headerColor.withValues(alpha: 0.18),
                  borderRadius:
                      BorderRadius.circular(AppDimens.radiusCard - 4),
                ),
                child: Icon(
                  _iconForType(diagnosis.diagnosisType),
                  color: fg,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppDimens.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (diagnosis.diagnosisType != null)
                      Text(
                        diagnosis.diagnosisType!.displayName,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: fg.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    Text(
                      diagnosis.displayProblemName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: fg,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (diagnosis.scientificName != null &&
                        diagnosis.scientificName!.isNotEmpty)
                      Text(
                        diagnosis.scientificName!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: fg.withValues(alpha: 0.7),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (diagnosis.severity != null) ...[
            const SizedBox(height: AppDimens.md),
            Row(
              children: [
                _SeverityBadge(severity: diagnosis.severity!),
                if (diagnosis.confidenceScore != null) ...[
                  const SizedBox(width: AppDimens.sm),
                  Text(
                    'Confianza: ${(diagnosis.confidenceScore! * 100).toStringAsFixed(0)}%',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: fg.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  IconData _iconForType(DiagnosisType? type) {
    switch (type) {
      case DiagnosisType.pest:
        return Icons.bug_report_outlined;
      case DiagnosisType.disease:
        return Icons.coronavirus_outlined;
      case DiagnosisType.deficiency:
        return Icons.water_drop_outlined;
      case DiagnosisType.environmentalStress:
        return Icons.wb_sunny_outlined;
      case DiagnosisType.healthy:
        return Icons.check_circle_outline;
      default:
        return Icons.help_outline;
    }
  }
}

// =============================================================================
// Remedy card
// =============================================================================

class _RemedyCard extends StatelessWidget {
  final DiagnosisRemedy remedy;

  const _RemedyCard({required this.remedy});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final (color, bgColor) = switch (remedy.type) {
      RemedyType.homemade => (AppColors.primary, AppColors.primarySoft),
      RemedyType.organic  => (const Color(0xFF8B5CF6), const Color(0xFFF3E8FF)),
      RemedyType.chemical => (AppColors.warning, AppColors.warningSoft),
    };
    final bg = AppColors.softOf(context, color, bgColor);
    final fg = AppColors.onSoftOf(context, color, color);

    return Card(
      margin: const EdgeInsets.only(bottom: AppDimens.md),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            padding: const EdgeInsets.all(AppDimens.sm),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(AppDimens.radiusCard - 8),
            ),
            child: Text(remedy.type.emoji, style: const TextStyle(fontSize: 18)),
          ),
          title: Text(
            remedy.title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Row(
            children: [
              Text(
                remedy.type.displayName,
                style: theme.textTheme.labelSmall?.copyWith(color: fg),
              ),
              const SizedBox(width: AppDimens.sm),
              Text(
                '· Eficacia: ${remedy.effectiveness.displayName}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimens.lg,
                0,
                AppDimens.lg,
                AppDimens.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    remedy.description,
                    style: theme.textTheme.bodySmall,
                  ),
                  if (remedy.ingredients != null &&
                      remedy.ingredients!.isNotEmpty) ...[
                    const SizedBox(height: AppDimens.md),
                    _SubSection(
                      icon: Icons.shopping_basket_outlined,
                      title: 'Ingredientes',
                      content: remedy.ingredients!,
                      color: fg,
                    ),
                  ],
                  if (remedy.instructions != null &&
                      remedy.instructions!.isNotEmpty) ...[
                    const SizedBox(height: AppDimens.md),
                    _SubSection(
                      icon: Icons.checklist_outlined,
                      title: 'Instrucciones',
                      content: remedy.instructions!,
                      color: fg,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Small reusable widgets
// =============================================================================

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;

  const _SectionTitle({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        if (subtitle != null)
          Text(
            subtitle!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
      ],
    );
  }
}

class _SubSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;
  final Color color;

  const _SubSection({
    required this.icon,
    required this.title,
    required this.content,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: AppDimens.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(content, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _InfoCard({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = AppColors.softOf(context, color, color.withValues(alpha: 0.1));
    final fg = AppColors.onSoftOf(context, color, color);

    return Container(
      padding: const EdgeInsets.all(AppDimens.lg),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppDimens.cardRadius,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: fg, size: 20),
          const SizedBox(width: AppDimens.md),
          Expanded(
            child: Text(text, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _SeverityBadge extends StatelessWidget {
  final ProblemSeverity severity;

  const _SeverityBadge({required this.severity});

  @override
  Widget build(BuildContext context) {
    final color = Color(severity.colorValue);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.md,
        vertical: AppDimens.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppDimens.radiusChip),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: color),
          const SizedBox(width: 4),
          Text(
            severity.displayName,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
