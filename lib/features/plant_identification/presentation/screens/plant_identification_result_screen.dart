import 'package:flutter/material.dart';
import 'package:planticula/core/services/plant_identification_standalone_ai_service.dart';
import 'package:planticula/core/theme/app_colors.dart';
import 'package:planticula/core/theme/app_dimens.dart';
import 'package:planticula/features/plant_identification/domain/entities/plant_identification_result.dart';

/// Full-screen result shown after a plant identification completes.
class PlantIdentificationResultScreen extends StatelessWidget {
  final PlantIdentificationRecord record;

  const PlantIdentificationResultScreen({super.key, required this.record});

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

                // ── Characteristics ────────────────────────────────────────
                if (record.characteristics.isNotEmpty) ...[
                  _SectionTitle(title: 'Características'),
                  const SizedBox(height: AppDimens.md),
                  ...record.characteristics.map(
                    (c) => _BulletItem(text: c, color: AppColors.primary),
                  ),
                  const SizedBox(height: AppDimens.xl),
                ],

                // ── Care tips ──────────────────────────────────────────────
                if (record.careTips.isNotEmpty) ...[
                  _SectionTitle(title: 'Consejos de cuidado'),
                  const SizedBox(height: AppDimens.md),
                  ...record.careTips.map(
                    (t) => _BulletItem(text: t, color: AppColors.water),
                  ),
                  const SizedBox(height: AppDimens.xl),
                ],

                // ── Care properties ────────────────────────────────────────
                _SectionTitle(title: 'Propiedades de cuidado'),
                const SizedBox(height: AppDimens.md),
                _CarePropertiesGrid(record: record),
                const SizedBox(height: AppDimens.xl),

                // ── Toxicity ───────────────────────────────────────────────
                if (record.toxicToPets != null || record.toxicToHumans != null) ...[
                  _SectionTitle(title: 'Toxicidad'),
                  const SizedBox(height: AppDimens.md),
                  _ToxicityCard(record: record),
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
  final PlantIdentificationRecord record;

  const _HeaderCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = AppColors.softOf(context, AppColors.primary, AppColors.primarySoft);
    final fg = AppColors.onSoftOf(context, AppColors.primaryDeep, AppColors.primary);

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
                  color: AppColors.primary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppDimens.radiusCard - 4),
                ),
                child: Icon(Icons.local_florist_outlined, color: fg, size: 28),
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
// Care properties grid
// =============================================================================

class _CarePropertiesGrid extends StatelessWidget {
  final PlantIdentificationRecord record;

  const _CarePropertiesGrid({required this.record});

  @override
  Widget build(BuildContext context) {
    final items = <_PropItem>[
      if (record.careLevel != null)
        _PropItem(
          icon: Icons.spa_outlined,
          label: 'Cuidado',
          value: record.careLevel!.displayName,
          color: _careLevelColor(record.careLevel!),
        ),
      if (record.wateringFrequency != null)
        _PropItem(
          icon: Icons.water_drop_outlined,
          label: 'Riego',
          value: record.wateringFrequency!.displayName,
          color: AppColors.water,
        ),
      if (record.lightRequirement != null)
        _PropItem(
          icon: Icons.wb_sunny_outlined,
          label: 'Luz',
          value: record.lightRequirement!.displayName,
          color: AppColors.sun,
        ),
      if (record.humidityRequirement != null)
        _PropItem(
          icon: Icons.water_outlined,
          label: 'Humedad',
          value: record.humidityRequirement!.displayName,
          color: AppColors.water,
        ),
    ];

    if (items.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: AppDimens.sm,
      runSpacing: AppDimens.sm,
      children: items.map((item) => _PropChip(item: item)).toList(),
    );
  }

  Color _careLevelColor(PlantIdCareLevel level) {
    switch (level) {
      case PlantIdCareLevel.easy:
        return AppColors.primary;
      case PlantIdCareLevel.moderate:
        return AppColors.sun;
      case PlantIdCareLevel.difficult:
        return AppColors.soil;
      case PlantIdCareLevel.expert:
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
// Toxicity card
// =============================================================================

class _ToxicityCard extends StatelessWidget {
  final PlantIdentificationRecord record;

  const _ToxicityCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        if (record.toxicToPets != null)
          _ToxicityRow(
            icon: Icons.pets_outlined,
            label: 'Mascotas',
            isToxic: record.toxicToPets!,
            theme: theme,
          ),
        if (record.toxicToPets != null && record.toxicToHumans != null)
          const SizedBox(height: AppDimens.sm),
        if (record.toxicToHumans != null)
          _ToxicityRow(
            icon: Icons.person_outlined,
            label: 'Personas',
            isToxic: record.toxicToHumans!,
            theme: theme,
          ),
      ],
    );
  }
}

class _ToxicityRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isToxic;
  final ThemeData theme;

  const _ToxicityRow({
    required this.icon,
    required this.label,
    required this.isToxic,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final color = isToxic ? AppColors.pest : AppColors.primary;
    final bg = isToxic ? AppColors.pestSoft : AppColors.primarySoft;
    final text = isToxic ? 'Tóxica' : 'No tóxica';

    return Container(
      padding: const EdgeInsets.all(AppDimens.md),
      decoration: BoxDecoration(
        color: AppColors.softOf(context, color, bg),
        borderRadius: AppDimens.cardRadius,
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.onSoftOf(context, color, color), size: 20),
          const SizedBox(width: AppDimens.md),
          Text(
            '$label: ',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.onSoftOf(context, color, color),
            ),
          ),
          Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.onSoftOf(context, color, color),
              fontWeight: FontWeight.w600,
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
