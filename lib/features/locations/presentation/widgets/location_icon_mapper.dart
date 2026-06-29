import 'package:flutter/material.dart';
import 'package:planticula/features/locations/domain/entities/location.dart';

/// Mapea las claves de icono de una [Location] a [IconData] de Material.
class LocationIconMapper {
  LocationIconMapper._();

  static IconData forKey(String? key) => switch (key) {
        'balcony'    => Icons.balcony_outlined,
        'terrace'    => Icons.deck_outlined,
        'greenhouse' => Icons.house_outlined,
        'indoor'     => Icons.living_outlined,
        'potted'     => Icons.local_florist_outlined,
        'vegetable'  => Icons.eco_outlined,
        'flower'     => Icons.local_florist,
        'herb'       => Icons.grass_outlined,
        'forest'     => Icons.park_outlined,
        'bench'      => Icons.table_restaurant_outlined,
        'zone'       => Icons.grid_view_outlined,
        'site'       => Icons.maps_home_work_outlined,
        _            => Icons.yard_outlined, // 'garden' y 'other'
      };

  /// Icono por defecto según el nivel de la localización.
  static IconData forKind(LocationKind kind) => switch (kind) {
        LocationKind.site  => Icons.maps_home_work_outlined,
        LocationKind.zone  => Icons.grid_view_outlined,
        LocationKind.bench => Icons.table_restaurant_outlined,
      };

  static List<({String key, IconData icon, String label})> get all => const [
        (key: 'garden',     icon: Icons.yard_outlined,             label: 'Jardín'),
        (key: 'greenhouse', icon: Icons.house_outlined,            label: 'Invernadero'),
        (key: 'site',       icon: Icons.maps_home_work_outlined,   label: 'Vivero'),
        (key: 'zone',       icon: Icons.grid_view_outlined,        label: 'Zona'),
        (key: 'bench',      icon: Icons.table_restaurant_outlined, label: 'Mesa'),
        (key: 'balcony',    icon: Icons.balcony_outlined,          label: 'Balcón'),
        (key: 'terrace',    icon: Icons.deck_outlined,             label: 'Terraza'),
        (key: 'indoor',     icon: Icons.living_outlined,           label: 'Interior'),
        (key: 'potted',     icon: Icons.local_florist_outlined,    label: 'Macetas'),
        (key: 'vegetable',  icon: Icons.eco_outlined,              label: 'Huerto'),
        (key: 'flower',     icon: Icons.local_florist,             label: 'Flores'),
        (key: 'herb',       icon: Icons.grass_outlined,            label: 'Hierbas'),
        (key: 'forest',     icon: Icons.park_outlined,             label: 'Bosque'),
      ];
}
