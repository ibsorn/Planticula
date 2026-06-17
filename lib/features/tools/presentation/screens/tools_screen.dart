import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:planticula/core/constants/app_constants.dart';
import 'package:planticula/core/theme/app_colors.dart';
import 'package:planticula/core/theme/app_dimens.dart';

/// Hub screen for advanced AI tools.
///
/// Layout:
///   - [Hero card]  Identificar Planta  — más grande, destacada
///   - [Grid 2 cols] Análisis Sustrato · Diagnóstico Plantas
///   - [Grid 2 cols] Identificar Semilla · Guías de Cuidado
class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar.large(
            title: Text('Herramientas'),
            centerTitle: false,
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.lg,
              vertical: AppDimens.md,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(
                  'Funciones avanzadas para cuidar mejor tus plantas',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                  ),
                ),
                const SizedBox(height: AppDimens.xl),

                // ── Hero card — Identificar Planta ─────────────────────────
                _HeroToolCard(
                  icon: Icons.local_florist_outlined,
                  title: 'Identificar Planta',
                  description:
                      'Fotografía cualquier planta y la IA te dirá su nombre, familia botánica, cuidados, toxicidad y características en segundos.',
                  accent: AppColors.primary,
                  deep: AppColors.primaryDeep,
                  soft: AppColors.primarySoft,
                  onTap: () =>
                      context.push(AppConstants.routePlantIdentificationV2),
                ),
                const SizedBox(height: AppDimens.md),

                // ── Grid row 1: Sustrato + Diagnóstico ─────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _CompactToolCard(
                        icon: Icons.science_outlined,
                        title: 'Análisis de Sustrato',
                        description:
                            'Analiza la tierra de tus plantas: pH, humedad y tipo de suelo.',
                        accent: AppColors.soil,
                        deep: AppColors.soilDeep,
                        soft: AppColors.soilSoft,
                        onTap: () =>
                            context.push(AppConstants.routeSoilAnalysis),
                      ),
                    ),
                    const SizedBox(width: AppDimens.md),
                    Expanded(
                      child: _CompactToolCard(
                        icon: Icons.bug_report_outlined,
                        title: 'Diagnóstico de Plantas',
                        description:
                            'Detecta plagas, enfermedades y carencias con remedios caseros.',
                        accent: AppColors.pest,
                        deep: AppColors.pestDeep,
                        soft: AppColors.pestSoft,
                        onTap: () =>
                            context.push(AppConstants.routePlantDisease),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimens.md),

                // ── Grid row 2: Semilla + Guías ────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _CompactToolCard(
                        icon: Icons.grass_outlined,
                        title: 'Identificar Semilla',
                        description:
                            'Identifica semillas y obtén instrucciones de germinación.',
                        accent: AppColors.sun,
                        deep: AppColors.sunDeep,
                        soft: AppColors.sunSoft,
                        onTap: () =>
                            context.push(AppConstants.routeSeedIdentification),
                      ),
                    ),
                    const SizedBox(width: AppDimens.md),
                    Expanded(
                      child: _CompactToolCard(
                        icon: Icons.menu_book_outlined,
                        title: 'Guías de Cuidado',
                        description:
                            'Consejos de riego, luz, temperatura y plagas.',
                        accent: AppColors.primary,
                        deep: AppColors.primaryDeep,
                        soft: AppColors.primarySoft,
                        onTap: () => context.push(AppConstants.routeGuides),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimens.xxl),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Hero card — large, full-width, used for the main feature
// =============================================================================

class _HeroToolCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color accent;
  final Color deep;
  final Color soft;
  final VoidCallback onTap;

  const _HeroToolCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.accent,
    required this.deep,
    required this.soft,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = AppColors.softOf(context, accent, soft);
    final fg = AppColors.onSoftOf(context, deep, accent);

    return Material(
      color: bg,
      borderRadius: AppDimens.cardRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppDimens.cardRadius,
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppDimens.md),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.22),
                      borderRadius:
                          BorderRadius.circular(AppDimens.radiusCard - 4),
                    ),
                    child: Icon(icon, color: fg, size: 32),
                  ),
                  const SizedBox(width: AppDimens.lg),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: fg,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 18,
                    color: fg.withValues(alpha: 0.6),
                  ),
                ],
              ),
              const SizedBox(height: AppDimens.md),
              Text(
                description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: fg.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Compact card — used in the 2-column grid
// =============================================================================

class _CompactToolCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color accent;
  final Color deep;
  final Color soft;
  final VoidCallback onTap;

  const _CompactToolCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.accent,
    required this.deep,
    required this.soft,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = AppColors.softOf(context, accent, soft);
    final fg = AppColors.onSoftOf(context, deep, accent);

    return Material(
      color: bg,
      borderRadius: AppDimens.cardRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppDimens.cardRadius,
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimens.sm),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.18),
                  borderRadius:
                      BorderRadius.circular(AppDimens.radiusCard - 6),
                ),
                child: Icon(icon, color: fg, size: 22),
              ),
              const SizedBox(height: AppDimens.md),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppDimens.xs),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: fg.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
