import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:planticula/core/constants/app_constants.dart';

/// Main scaffold that wraps shell routes and provides the bottom navigation bar.
///
/// Tab layout:
///   0 → Mi Jardín  (/plants)
///   1 → Herramientas (/tools)
///   2 → Comunidad  (/pest-alerts)
///   3 → Perfil     (/profile)
class MainScaffold extends StatelessWidget {
  final Widget child;

  const MainScaffold({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final currentRoute = GoRouterState.of(context).matchedLocation;
    final selectedIndex = _getSelectedIndex(currentRoute);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) => _onItemTapped(context, index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.local_florist_outlined),
            selectedIcon: Icon(Icons.local_florist_rounded),
            label: 'Mi Jardín',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome_rounded),
            label: 'Herramientas',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups_rounded),
            label: 'Comunidad',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  int _getSelectedIndex(String route) {
    // Tab 0 – Mi Jardín
    if (route.startsWith(AppConstants.routePlants)) return 0;
    // Tab 1 – Herramientas
    if (route.startsWith(AppConstants.routeTools) ||
        route.startsWith(AppConstants.routeSoilAnalysis) ||
        route.startsWith(AppConstants.routeGuides) ||
        route.startsWith(AppConstants.routePlantDisease) ||
        route.startsWith(AppConstants.routePlantIdentificationV2) ||
        route.startsWith(AppConstants.routeSeedIdentification)) {
      return 1;
    }
    // Tab 2 – Comunidad
    if (route.startsWith(AppConstants.routePestAlerts) ||
        route.startsWith(AppConstants.routeMarketplace)) {
      return 2;
    }
    // Tab 3 – Perfil
    if (route.startsWith(AppConstants.routeProfile)) return 3;
    return 0;
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppConstants.routePlants);
        break;
      case 1:
        context.go(AppConstants.routeTools);
        break;
      case 2:
        context.go(AppConstants.routePestAlerts);
        break;
      case 3:
        context.go(AppConstants.routeProfile);
        break;
    }
  }
}
