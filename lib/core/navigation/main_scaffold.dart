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
            icon: Icon(Icons.local_florist_outlined),
            selectedIcon: Icon(Icons.local_florist),
            label: 'Plantas',
          ),
          NavigationDestination(
            icon: Icon(Icons.warning_amber_outlined),
            selectedIcon: Icon(Icons.warning_amber),
            label: 'Alertas',
          ),
          NavigationDestination(
            icon: Icon(Icons.store_outlined),
            selectedIcon: Icon(Icons.store),
            label: 'Mercado',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Guias',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  int _getSelectedIndex(String route) {
    if (route.startsWith(AppConstants.routePlants)) return 0;
    if (route.startsWith(AppConstants.routePestAlerts)) return 1;
    if (route.startsWith(AppConstants.routeMarketplace)) return 2;
    if (route.startsWith('/guides')) return 3;
    if (route.startsWith(AppConstants.routeProfile)) return 4;
    if (route.startsWith('/soil-analysis')) return 4; // Profile area
    return 0;
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppConstants.routePlants);
        break;
      case 1:
        context.go(AppConstants.routePestAlerts);
        break;
      case 2:
        context.go(AppConstants.routeMarketplace);
        break;
      case 3:
        context.go('/guides');
        break;
      case 4:
        context.go(AppConstants.routeProfile);
        break;
    }
  }
}
