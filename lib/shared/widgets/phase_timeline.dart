import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';

/// One stage of the growth journey shown in [PhaseTimeline].
class PhaseStep {
  final String emoji;
  final String label;

  const PhaseStep({required this.emoji, required this.label});
}

/// Default plant growth journey: seedling -> juvenile -> adult.
const List<PhaseStep> kGrowthPhaseSteps = [
  PhaseStep(emoji: '🌱', label: 'Plántula'),
  PhaseStep(emoji: '🌿', label: 'Juvenil'),
  PhaseStep(emoji: '🌳', label: 'Adulta'),
];

/// Visual growth journey with an animated progress bar.
///
/// [currentIndex] is the active stage; [stageProgress] (0-1) is the progress
/// within the current stage. When [onStepTap] is set the steps become
/// selectable (used in the create-plant wizard).
class PhaseTimeline extends StatelessWidget {
  final List<PhaseStep> steps;
  final int currentIndex;
  final double stageProgress;
  final ValueChanged<int>? onStepTap;

  const PhaseTimeline({
    super.key,
    this.steps = kGrowthPhaseSteps,
    required this.currentIndex,
    this.stageProgress = 0,
    this.onStepTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final inactive = isDark
        ? Colors.white.withValues(alpha: 0.25)
        : Colors.black.withValues(alpha: 0.12);

    // Overall progress along the whole journey.
    final total = steps.length <= 1
        ? 1.0
        : ((currentIndex + stageProgress.clamp(0.0, 1.0)) / (steps.length - 1))
            .clamp(0.0, 1.0);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var i = 0; i < steps.length; i++)
              _PhaseDot(
                step: steps[i],
                state: i < currentIndex
                    ? _DotState.done
                    : i == currentIndex
                        ? _DotState.active
                        : _DotState.pending,
                onTap: onStepTap == null ? null : () => onStepTap!(i),
              ),
          ],
        ),
        const SizedBox(height: AppDimens.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppDimens.radiusChip),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: total),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => LinearProgressIndicator(
              value: value,
              minHeight: 8,
              color: AppColors.primary,
              backgroundColor: inactive,
            ),
          ),
        ),
      ],
    );
  }
}

enum _DotState { done, active, pending }

class _PhaseDot extends StatelessWidget {
  final PhaseStep step;
  final _DotState state;
  final VoidCallback? onTap;

  const _PhaseDot({required this.step, required this.state, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = state != _DotState.pending;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: active ? 1 : 0.4,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(AppDimens.sm),
              decoration: BoxDecoration(
                color: state == _DotState.active
                    ? AppColors.softOf(
                        context, AppColors.primary, AppColors.primarySoft)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Text(step.emoji, style: const TextStyle(fontSize: 24)),
            ),
            const SizedBox(height: 2),
            Text(
              step.label,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight:
                    state == _DotState.active ? FontWeight.w700 : null,
                color: state == _DotState.active
                    ? theme.colorScheme.primary
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
