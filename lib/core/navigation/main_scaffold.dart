import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:planticula/core/constants/app_constants.dart';

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
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Hoy',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_florist_outlined),
            selectedIcon: Icon(Icons.local_florist_rounded),
            label: 'Mi Jardín',
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
    if (route.startsWith(AppConstants.routeToday)) return 0;
    if (route.startsWith(AppConstants.routePlants)) return 1;
    if (route.startsWith(AppConstants.routePestAlerts) ||
        route.startsWith(AppConstants.routeMarketplace)) {
      return 2;
    }
    if (route.startsWith(AppConstants.routeProfile) ||
        route.startsWith(AppConstants.routeGuides) ||
        route.startsWith(AppConstants.routeSoilAnalysis)) {
      return 3;
    }
    return 0;
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppConstants.routeToday);
        break;
      case 1:
        context.go(AppConstants.routePlants);
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
