import 'package:flutter/material.dart';
import 'package:planticula/features/gardens/domain/entities/garden.dart';

/// Mapea las claves de icono de [GardenIcon] a [IconData] de Material.
class GardenIconMapper {
  GardenIconMapper._();

  static IconData forKey(String? key) => switch (key) {
        'balcony'     => Icons.balcony_outlined,
        'terrace'     => Icons.deck_outlined,
        'greenhouse'  => Icons.house_outlined,
        'indoor'      => Icons.living_outlined,
        'potted'      => Icons.local_florist_outlined,
        'vegetable'   => Icons.eco_outlined,
        'flower'      => Icons.local_florist,
        'herb'        => Icons.grass_outlined,
        'forest'      => Icons.park_outlined,
        _             => Icons.yard_outlined, // 'garden' y 'other'
      };

  static IconData forGardenIcon(GardenIcon icon) => forKey(icon.name);

  static List<({String key, IconData icon, String label})> get all => [
        (key: 'garden',    icon: Icons.yard_outlined,          label: 'Jardín'),
        (key: 'balcony',   icon: Icons.balcony_outlined,       label: 'Balcón'),
        (key: 'terrace',   icon: Icons.deck_outlined,          label: 'Terraza'),
        (key: 'greenhouse',icon: Icons.house_outlined,         label: 'Invernadero'),
        (key: 'indoor',    icon: Icons.living_outlined,        label: 'Interior'),
        (key: 'potted',    icon: Icons.local_florist_outlined, label: 'Macetas'),
        (key: 'vegetable', icon: Icons.eco_outlined,           label: 'Huerto'),
        (key: 'flower',    icon: Icons.local_florist,          label: 'Flores'),
        (key: 'herb',      icon: Icons.grass_outlined,         label: 'Hierbas'),
        (key: 'forest',    icon: Icons.park_outlined,          label: 'Bosque'),
        (key: 'other',     icon: Icons.yard_outlined,          label: 'Otro'),
      ];
}
