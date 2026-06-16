import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:planticula/core/constants/app_constants.dart';
import 'package:planticula/core/theme/app_colors.dart';
import 'package:planticula/core/theme/app_dimens.dart';

/// Hub screen for advanced tools: soil analysis and care guides.
///
/// Each tool is presented as a tappable card that navigates to its
/// own feature screen. New tools can be added here as the app grows.
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
                _ToolCard(
                  icon: Icons.science_outlined,
                  title: 'Análisis de Sustrato',
                  description:
                      'Fotografía la tierra de tus plantas para obtener un análisis de pH, humedad y tipo de suelo.',
                  accent: AppColors.soil,
                  deep: AppColors.soilDeep,
                  soft: AppColors.soilSoft,
                  onTap: () => context.go(AppConstants.routeSoilAnalysis),
                ),
                const SizedBox(height: AppDimens.md),
                _ToolCard(
                  icon: Icons.bug_report_outlined,
                  title: 'Diagnóstico de Plantas',
                  description:
                      'Fotografía hojas, tallos o raíces afectadas y la IA identificará plagas, enfermedades o carencias con remedios caseros.',
                  accent: AppColors.pest,
                  deep: AppColors.pestDeep,
                  soft: AppColors.pestSoft,
                  onTap: () => context.go(AppConstants.routePlantDisease),
                ),
                const SizedBox(height: AppDimens.md),
                _ToolCard(
                  icon: Icons.menu_book_outlined,
                  title: 'Guías de Cuidado',
                  description:
                      'Consulta consejos sobre riego, luz, temperatura, plagas y más para mantener tus plantas sanas.',
                  accent: AppColors.primary,
                  deep: AppColors.primaryDeep,
                  soft: AppColors.primarySoft,
                  onTap: () => context.go(AppConstants.routeGuides),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color accent;
  final Color deep;
  final Color soft;
  final VoidCallback onTap;

  const _ToolCard({
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimens.md),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppDimens.radiusCard - 4),
                ),
                child: Icon(icon, color: fg, size: 28),
              ),
              const SizedBox(width: AppDimens.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: fg,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppDimens.xs),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: fg.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDimens.sm),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: fg.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
