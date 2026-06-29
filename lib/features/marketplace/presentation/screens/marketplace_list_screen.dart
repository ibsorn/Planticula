import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:planticula/core/constants/app_constants.dart';
import 'package:planticula/features/marketplace/presentation/bloc/marketplace_bloc.dart';
import 'package:planticula/features/marketplace/presentation/widgets/marketplace_favorites_tab.dart';
import 'package:planticula/features/marketplace/presentation/widgets/marketplace_filter_sheet.dart';
import 'package:planticula/features/marketplace/presentation/widgets/marketplace_my_listings_tab.dart';
import 'package:planticula/features/marketplace/presentation/widgets/marketplace_nearby_tab.dart';
import 'package:planticula/core/theme/app_colors.dart';
import 'package:planticula/core/utils/logger.dart';
import 'package:planticula/shared/widgets/community_switcher.dart';

class MarketplaceListScreen extends StatefulWidget {
  const MarketplaceListScreen({super.key});

  @override
  State<MarketplaceListScreen> createState() => _MarketplaceListScreenState();
}

class _MarketplaceListScreenState extends State<MarketplaceListScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _getLocationAndLoad();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      final bloc = context.read<MarketplaceBloc>();
      switch (_tabController.index) {
        case 0:
          bloc.add(MarketplaceLoadNearby());
          break;
        case 1:
          bloc.add(MarketplaceLoadMyListings());
          break;
        case 2:
          bloc.add(MarketplaceLoadFavorites());
          break;
      }
    }
  }

  Future<void> _getLocationAndLoad() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition();
        if (mounted) {
          context.read<MarketplaceBloc>().add(MarketplaceUpdateUserLocation(
            latitude: position.latitude,
            longitude: position.longitude,
          ));
        }
      }
    } catch (e) {
      Logger.w('Location fetch failed for marketplace, continuing without location: $e');
    } finally {
      // location load complete
    }
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) => MarketplaceFilterSheet(
          scrollController: controller,
          onApply: (filter) {
            context.read<MarketplaceBloc>().add(filter);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comunidad 👥'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilters,
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => context.push(AppConstants.routeCreateListing),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Cercanos', icon: Icon(Icons.near_me)),
            Tab(text: 'Mis anuncios', icon: Icon(Icons.inventory)),
            Tab(text: 'Favoritos', icon: Icon(Icons.favorite)),
          ],
        ),
      ),
      body: Column(
        children: [
          const CommunitySwitcher(selected: 1),
          // Search bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar plantas, esquejes, herramientas...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context.read<MarketplaceBloc>().add(
                            const MarketplaceSearchQueryChanged(''),
                          );
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (query) {
                context.read<MarketplaceBloc>().add(
                  MarketplaceSearchQueryChanged(query),
                );
              },
            ),
          ),

          // Contenido
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                const MarketplaceNearbyTab(),
                const MarketplaceMyListingsTab(),
                const MarketplaceFavoritesTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppConstants.routeCreateListing),
        backgroundColor: AppColors.market,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Vender o regalar'),
      ),
    );
  }
}
