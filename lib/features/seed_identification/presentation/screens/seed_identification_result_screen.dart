import 'package:flutter/material.dart';
import 'package:planticula/core/services/seed_identification_ai_service.dart';
import 'package:planticula/core/theme/app_colors.dart';
import 'package:planticula/core/theme/app_dimens.dart';
import 'package:planticula/features/seed_identification/domain/entities/seed_identification_result.dart';

const _seedColor = AppColors.sun;
const _seedColorSoft = AppColors.sunSoft;
const _seedColorDeep = AppColors.sunDeep;

/// Full-screen result shown after a seed identification completes.
class SeedIdentificationResultScreen extends StatelessWidget {
  final SeedIdentificationRecord record;

  const SeedIdentificationResultScreen({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: Text(
              record.displayName,
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
            centerTitle: false,
          ),
          SliverPadding(
            padding: const EdgeInsets.all(AppDimens.lg),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Header card ────────────────────────────────────────────
                _HeaderCard(record: record),
                const SizedBox(height: AppDimens.lg),

                // ── Description ────────────────────────────────────────────
                if (record.description != null &&
                    record.description!.isNotEmpty) ...[
                  _SectionTitle(title: 'Descripción'),
                  const SizedBox(height: AppDimens.sm),
                  Text(
                    record.description!,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppDimens.xl),
                ],

                // ── Germination properties ─────────────────────────────────
                _SectionTitle(title: 'Datos de germinación'),
                const SizedBox(height: AppDimens.md),
                _GerminationPropsGrid(record: record),
                const SizedBox(height: AppDimens.xl),

                // ── Germination tips ───────────────────────────────────────
                if (record.germinationTips.isNotEmpty) ...[
                  _SectionTitle(title: 'Consejos para germinar'),
                  const SizedBox(height: AppDimens.md),
                  ...record.germinationTips.map(
                    (t) => _BulletItem(text: t, color: _seedColor),
                  ),
                  const SizedBox(height: AppDimens.xl),
                ],

                // ── Soil recommendation ────────────────────────────────────
                if (record.soilRecommendation != null &&
                    record.soilRecommendation!.isNotEmpty) ...[
                  _SectionTitle(title: 'Sustrato recomendado'),
                  const SizedBox(height: AppDimens.sm),
                  _InfoCard(
                    icon: Icons.yard_outlined,
                    color: AppColors.soil,
                    text: record.soilRecommendation!,
                  ),
                  const SizedBox(height: AppDimens.xl),
                ],

                // ── Notes ──────────────────────────────────────────────────
                if (record.analysisNotes != null &&
                    record.analysisNotes!.isNotEmpty) ...[
                  _SectionTitle(title: 'Notas del análisis'),
                  const SizedBox(height: AppDimens.sm),
                  Text(
                    record.analysisNotes!,
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
  final SeedIdentificationRecord record;

  const _HeaderCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = AppColors.softOf(context, _seedColor, _seedColorSoft);
    final fg = AppColors.onSoftOf(context, _seedColorDeep, _seedColor);

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
                  color: _seedColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppDimens.radiusCard - 4),
                ),
                child: Icon(Icons.grass_outlined, color: fg, size: 28),
              ),
              const SizedBox(width: AppDimens.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (record.family != null)
                      Text(
                        record.family!,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: fg.withValues(alpha: 0.8),
                        ),
                      ),
                    Text(
                      record.displayName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: fg,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (record.scientificName != null)
                      Text(
                        record.scientificName!,
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
          if (record.confidenceScore != null) ...[
            const SizedBox(height: AppDimens.md),
            Text(
              'Confianza: ${(record.confidenceScore! * 100).toStringAsFixed(0)}%',
              style: theme.textTheme.labelSmall?.copyWith(
                color: fg.withValues(alpha: 0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// Germination properties grid
// =============================================================================

class _GerminationPropsGrid extends StatelessWidget {
  final SeedIdentificationRecord record;

  const _GerminationPropsGrid({required this.record});

  @override
  Widget build(BuildContext context) {
    final items = <_PropItem>[
      if (record.germinationDifficulty != null)
        _PropItem(
          icon: Icons.tune_outlined,
          label: 'Dificultad',
          value: record.germinationDifficulty!.displayName,
          color: _difficultyColor(record.germinationDifficulty!),
        ),
      if (record.germinationTime != null)
        _PropItem(
          icon: Icons.schedule_outlined,
          label: 'Tiempo',
          value: record.germinationTime!.displayName,
          color: _seedColor,
        ),
      if (record.sowingDepth != null)
        _PropItem(
          icon: Icons.vertical_align_bottom_outlined,
          label: 'Profundidad',
          value: record.sowingDepth!.displayName,
          color: AppColors.soil,
        ),
      if (record.bestSowingSeason != null)
        _PropItem(
          icon: Icons.calendar_month_outlined,
          label: 'Temporada',
          value: record.bestSowingSeason!.displayName,
          color: AppColors.primary,
        ),
    ];

    if (items.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: AppDimens.sm,
      runSpacing: AppDimens.sm,
      children: items.map((item) => _PropChip(item: item)).toList(),
    );
  }

  Color _difficultyColor(SeedIdGerminationDifficulty d) {
    switch (d) {
      case SeedIdGerminationDifficulty.easy:
        return AppColors.primary;
      case SeedIdGerminationDifficulty.moderate:
        return AppColors.sun;
      case SeedIdGerminationDifficulty.difficult:
        return AppColors.soil;
      case SeedIdGerminationDifficulty.expert:
        return AppColors.pest;
    }
  }
}

class _PropItem {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _PropItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}

class _PropChip extends StatelessWidget {
  final _PropItem item;

  const _PropChip({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = AppColors.softOf(context, item.color, item.color.withValues(alpha: 0.1));
    final fg = AppColors.onSoftOf(context, item.color, item.color);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.md,
        vertical: AppDimens.sm,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimens.radiusChip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(item.icon, size: 14, color: fg),
          const SizedBox(width: AppDimens.xs),
          Text(
            '${item.label}: ${item.value}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Info card
// =============================================================================

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _InfoCard({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    final bg = AppColors.softOf(context, color, color.withValues(alpha: 0.08));
    final fg = AppColors.onSoftOf(context, color, color);

    return Container(
      padding: const EdgeInsets.all(AppDimens.lg),
      decoration: BoxDecoration(color: bg, borderRadius: AppDimens.cardRadius),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: fg, size: 20),
          const SizedBox(width: AppDimens.md),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: fg),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Shared helpers
// =============================================================================

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

class _BulletItem extends StatelessWidget {
  final String text;
  final Color color;

  const _BulletItem({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: AppDimens.md),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
