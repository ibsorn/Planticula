import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:planticula/core/constants/app_constants.dart';
import 'package:planticula/features/marketplace/domain/entities/marketplace_listing.dart';
import 'package:planticula/features/marketplace/presentation/bloc/marketplace_bloc.dart';

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
    } catch (_) {
      // Continuar sin ubicación
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
        builder: (_, controller) => _FilterSheet(
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
        title: const Text('Marketplace'),
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
                _NearbyTab(),
                _MyListingsTab(),
                _FavoritesTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppConstants.routeCreateListing),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _NearbyTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MarketplaceBloc, MarketplaceState>(
      builder: (context, state) {
        if (state.isNearbyLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!state.hasLocation) {
          return _LocationRequiredMessage(
            onRetry: () => context.read<MarketplaceBloc>().add(MarketplaceLoadNearby()),
          );
        }

        if (state.isNearbyEmpty) {
          return const _EmptyMessage(
            icon: Icons.storefront,
            title: 'No hay anuncios cercanos',
            subtitle: 'Sé el primero en publicar en tu zona',
          );
        }

        if (state.hasError && state.nearbyStatus == MarketplaceStatus.error) {
          return _ErrorMessage(
            message: state.errorMessage!,
            onRetry: () => context.read<MarketplaceBloc>().add(MarketplaceLoadNearby()),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            context.read<MarketplaceBloc>().add(MarketplaceLoadNearby());
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: state.nearbyListings.length,
            itemBuilder: (context, index) {
              final listing = state.nearbyListings[index];
              return _ListingCard(listing: listing);
            },
          ),
        );
      },
    );
  }
}

class _MyListingsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MarketplaceBloc, MarketplaceState>(
      builder: (context, state) {
        if (state.isMyListingsLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.isMyListingsEmpty) {
          return _EmptyMessage(
            icon: Icons.post_add,
            title: 'No tienes anuncios',
            subtitle: 'Publica tu primera planta o esqueje',
            action: FilledButton.icon(
              onPressed: () => context.push(AppConstants.routeCreateListing),
              icon: const Icon(Icons.add),
              label: const Text('Crear anuncio'),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            context.read<MarketplaceBloc>().add(MarketplaceLoadMyListings());
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: state.myListings.length,
            itemBuilder: (context, index) {
              final listing = state.myListings[index];
              return _MyListingCard(listing: listing);
            },
          ),
        );
      },
    );
  }
}

class _FavoritesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MarketplaceBloc, MarketplaceState>(
      builder: (context, state) {
        if (state.isFavoritesLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.favoritesStatus == MarketplaceStatus.empty) {
          return const _EmptyMessage(
            icon: Icons.favorite_border,
            title: 'Sin favoritos',
            subtitle: 'Guarda los anuncios que te interesen',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            context.read<MarketplaceBloc>().add(MarketplaceLoadFavorites());
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: state.favoriteListings.length,
            itemBuilder: (context, index) {
              final listing = state.favoriteListings[index];
              return _ListingCard(listing: listing, showFavorite: false);
            },
          ),
        );
      },
    );
  }
}

class _ListingCard extends StatelessWidget {
  final MarketplaceListing listing;
  final bool showFavorite;

  const _ListingCard({
    required this.listing,
    this.showFavorite = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          context.push('/listing/${listing.id}');
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen
            _ListingImage(listing: listing, size: 120),

            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tipo badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Color(listing.typeColor).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        listing.typeBadge,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(listing.typeColor),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Título
                    Text(
                      listing.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Precio
                    Text(
                      listing.priceDisplay,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    const SizedBox(height: 8),

                    // Footer
                    Row(
                      children: [
                        Icon(
                          Icons.category,
                          size: 14,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          listing.category.displayName,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        const Spacer(),
                        if (listing.distanceDisplay != null)
                          Row(
                            children: [
                              Icon(
                                Icons.near_me,
                                size: 14,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                listing.distanceDisplay!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Favorito
            if (showFavorite)
              IconButton(
                icon: Icon(
                  listing.isFavorited == true
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: listing.isFavorited == true ? Colors.red : null,
                ),
                onPressed: () {
                  context.read<MarketplaceBloc>().add(
                    MarketplaceToggleFavorite(listing.id),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _MyListingCard extends StatelessWidget {
  final MarketplaceListing listing;

  const _MyListingCard({required this.listing});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          context.push('/listing/${listing.id}');
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ListingImage(listing: listing, size: 120),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(listing.status),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        listing.status.displayName,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),

                    Text(
                      listing.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    Text(
                      listing.priceDisplay,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    const SizedBox(height: 8),

                    // Stats
                    Row(
                      children: [
                        Icon(Icons.visibility, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text('${listing.viewCount}'),
                        const SizedBox(width: 16),
                        Icon(Icons.favorite, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text('${listing.favoriteCount}'),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Actions
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'sold':
                    context.read<MarketplaceBloc>().add(
                      MarketplaceChangeStatus(listingId: listing.id, status: ListingStatus.sold),
                    );
                    break;
                  case 'reserve':
                    context.read<MarketplaceBloc>().add(
                      MarketplaceChangeStatus(listingId: listing.id, status: ListingStatus.reserved),
                    );
                    break;
                  case 'activate':
                    context.read<MarketplaceBloc>().add(
                      MarketplaceChangeStatus(listingId: listing.id, status: ListingStatus.active),
                    );
                    break;
                  case 'delete':
                    _showDeleteDialog(context, listing.id);
                    break;
                }
              },
              itemBuilder: (context) => [
                if (listing.status == ListingStatus.active)
                  const PopupMenuItem(value: 'reserve', child: Text('Marcar reservado')),
                if (listing.status == ListingStatus.active || listing.status == ListingStatus.reserved)
                  const PopupMenuItem(value: 'sold', child: Text('Marcar vendido')),
                if (listing.status != ListingStatus.active)
                  const PopupMenuItem(value: 'activate', child: Text('Reactivar')),
                const PopupMenuItem(value: 'delete', child: Text('Eliminar', style: TextStyle(color: Colors.red))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(ListingStatus status) {
    switch (status) {
      case ListingStatus.active:
        return Colors.green;
      case ListingStatus.reserved:
        return Colors.orange;
      case ListingStatus.sold:
        return Colors.blue;
      case ListingStatus.inactive:
        return Colors.grey;
    }
  }

  void _showDeleteDialog(BuildContext context, String listingId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar anuncio'),
        content: const Text('¿Estás seguro? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              context.read<MarketplaceBloc>().add(MarketplaceDeleteListing(listingId));
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

class _ListingImage extends StatelessWidget {
  final MarketplaceListing listing;
  final double size;

  const _ListingImage({required this.listing, required this.size});

  @override
  Widget build(BuildContext context) {
    final hasPhotos = listing.photoUrls.isNotEmpty;

    return Container(
      width: size,
      height: size,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: hasPhotos
          ? Image.network(
              listing.photoUrls.first,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildPlaceholder(context),
            )
          : _buildPlaceholder(context),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    IconData icon;
    switch (listing.category) {
      case ListingCategory.cutting:
        icon = Icons.cut;
        break;
      case ListingCategory.plant:
        icon = Icons.local_florist;
        break;
      case ListingCategory.substrate:
        icon = Icons.landscape;
        break;
      case ListingCategory.tool:
        icon = Icons.build;
        break;
    }

    return Center(
      child: Icon(
        icon,
        size: 40,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  final ScrollController scrollController;
  final ValueChanged<MarketplaceFilterChanged> onApply;

  const _FilterSheet({required this.scrollController, required this.onApply});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  double _radiusKm = 10;
  List<ListingCategory> _selectedCategories = [];
  List<ListingType> _selectedTypes = [];
  double? _maxPrice;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        controller: widget.scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filtros',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                TextButton(
                  onPressed: _reset,
                  child: const Text('Restablecer'),
                ),
              ],
            ),
            const Divider(),

            // Radio
            Text('Distancia máxima: ${_radiusKm.toStringAsFixed(1)} km'),
            Slider(
              value: _radiusKm,
              min: 1,
              max: 50,
              divisions: 49,
              label: '${_radiusKm.toStringAsFixed(1)} km',
              onChanged: (v) => setState(() => _radiusKm = v),
            ),
            const SizedBox(height: 16),

            // Categorías
            Text('Categorías', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ListingCategory.values.map((cat) {
                final isSelected = _selectedCategories.contains(cat);
                return FilterChip(
                  label: Text(cat.displayName),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedCategories.add(cat);
                      } else {
                        _selectedCategories.remove(cat);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Tipo
            Text('Tipo de transacción', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ListingType.values.map((type) {
                final isSelected = _selectedTypes.contains(type);
                return FilterChip(
                  label: Text(type.displayName),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedTypes.add(type);
                      } else {
                        _selectedTypes.remove(type);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Precio máximo
            Text('Precio máximo', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.euro),
                hintText: 'Sin límite',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) {
                setState(() => _maxPrice = double.tryParse(v));
              },
            ),
            const SizedBox(height: 24),

            // Aplicar
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  widget.onApply(MarketplaceFilterChanged(
                    radiusKm: _radiusKm,
                    categories: _selectedCategories.isEmpty ? null : _selectedCategories,
                    listingTypes: _selectedTypes.isEmpty ? null : _selectedTypes,
                    maxPrice: _maxPrice,
                  ));
                  Navigator.pop(context);
                },
                child: const Text('Aplicar filtros'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _reset() {
    setState(() {
      _radiusKm = 10;
      _selectedCategories = [];
      _selectedTypes = [];
      _maxPrice = null;
    });
  }
}

class _EmptyMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  const _EmptyMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
            ),
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorMessage({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text('Error', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationRequiredMessage extends StatelessWidget {
  final VoidCallback onRetry;

  const _LocationRequiredMessage({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 64, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            const Text('Ubicación requerida'),
            const SizedBox(height: 8),
            const Text(
              'Necesitamos tu ubicación para mostrar anuncios cercanos',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.my_location),
              label: const Text('Obtener ubicación'),
            ),
          ],
        ),
      ),
    );
  }
}
