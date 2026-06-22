import 'package:flutter/material.dart';
import 'package:planticula/features/gardens/domain/entities/garden.dart';
import 'package:planticula/features/gardens/domain/entities/garden_group.dart';
import 'package:planticula/features/gardens/presentation/widgets/garden_icon_mapper.dart';

/// Chip horizontal que representa un [GardenGroup].
/// Usado en la barra de filtrado de grupos dentro de un jardín.
class GroupChip extends StatelessWidget {
  final GardenGroup group;
  final Garden parentGarden;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const GroupChip({
    super.key,
    required this.group,
    required this.parentGarden,
    this.isSelected = false,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Color: propio si tiene, sino hereda del jardín padre
    final rawColor = group.color ?? parentGarden.color;
    final hex = rawColor.replaceFirst('#', '');
    final color = Color(int.parse('FF$hex', radix: 16));

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.2)
              : theme.colorScheme.surfaceVariant.withOpacity(0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              GardenIconMapper.forKey(group.icon ?? parentGarden.icon),
              size: 14,
              color: isSelected
                  ? color
                  : theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            const SizedBox(width: 5),
            Text(
              group.name,
              style: theme.textTheme.labelMedium?.copyWith(
                color: isSelected
                    ? color
                    : theme.colorScheme.onSurface.withOpacity(0.75),
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
