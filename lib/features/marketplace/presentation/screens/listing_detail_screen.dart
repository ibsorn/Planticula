import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:planticula/features/marketplace/domain/entities/marketplace_listing.dart';
import 'package:planticula/features/marketplace/presentation/bloc/marketplace_bloc.dart';

class ListingDetailScreen extends StatelessWidget {
  final String listingId;

  const ListingDetailScreen({super.key, required this.listingId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bloc = context.read<MarketplaceBloc>();

    // Find listing in current state
    final state = bloc.state;
    final listing = _findListing(state);

    if (listing == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Anuncio')),
        body: const Center(child: Text('Anuncio no encontrado')),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Photo carousel in SliverAppBar
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: listing.photoUrls.isNotEmpty
                  ? PageView.builder(
                      itemCount: listing.photoUrls.length,
                      itemBuilder: (context, index) {
                        return Image.network(
                          listing.photoUrls[index],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: Icon(Icons.image_not_supported,
                                size: 64, color: theme.colorScheme.onSurface.withAlpha(77)),
                          ),
                        );
                      },
                    )
                  : Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Icon(Icons.local_florist,
                          size: 80, color: theme.colorScheme.onSurface.withAlpha(77)),
                    ),
            ),
            actions: [
              if (listing.isFavorited != null)
                IconButton(
                  icon: Icon(
                    listing.isFavorited == true ? Icons.favorite : Icons.favorite_border,
                    color: listing.isFavorited == true ? Colors.red : null,
                  ),
                  onPressed: () {
                    bloc.add(MarketplaceToggleFavorite(listing.id));
                  },
                ),
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + price
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(listing.title,
                            style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 12),
                      _PriceBadge(listing: listing),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Type badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Color(listing.typeColor).withAlpha(26),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(listing.typeBadge,
                        style: TextStyle(
                            fontSize: 12, color: Color(listing.typeColor))),
                  ),
                  const SizedBox(height: 16),

                  // Category + status
                  Row(
                    children: [
                      Icon(listing.category.icon as IconData,
                          size: 18, color: theme.colorScheme.primary),
                      const SizedBox(width: 6),
                      Text(listing.category.displayName,
                          style: theme.textTheme.bodyMedium),
                      const Spacer(),
                      _StatusChip(status: listing.status),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),

                  // Description
                  Text('Descripcion',
                      style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(listing.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.5)),
                  const SizedBox(height: 16),

                  // Trade for (if applicable)
                  if (listing.listingType == ListingType.trade &&
                      listing.tradeFor != null) ...[
                    const Divider(),
                    const SizedBox(height: 12),
                    Text('Acepta intercambio por:',
                        style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(listing.tradeFor!,
                        style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 16),
                  ],

                  const Divider(),
                  const SizedBox(height: 12),

                  // Location info
                  _InfoRow(
                    icon: Icons.location_on,
                    label: listing.locationName ?? 'Ubicacion no disponible',
                    subtitle: listing.distanceDisplay,
                  ),
                  const SizedBox(height: 12),

                  // Seller info
                  _InfoRow(
                    icon: Icons.person,
                    label: listing.sellerName ?? 'Vendedor',
                  ),
                  const SizedBox(height: 12),

                  // Stats
                  Row(
                    children: [
                      _StatChip(
                          icon: Icons.visibility, value: listing.viewCount),
                      const SizedBox(width: 16),
                      _StatChip(
                          icon: Icons.favorite, value: listing.favoriteCount),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Created date
                  _InfoRow(
                    icon: Icons.calendar_today,
                    label: 'Publicado el ${_formatDate(listing.createdAt)}',
                  ),
                  const SizedBox(height: 80), // space for FAB
                ],
              ),
            ),
          ),
        ],
      ),
      // Contact button
      floatingActionButton: listing.isAvailable
          ? FloatingActionButton.extended(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Funcion de contacto disponible proximamente'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.chat),
              label: const Text('Contactar'),
            )
          : null,
    );
  }

  MarketplaceListing? _findListing(MarketplaceState state) {
    // Search in all available lists
    for (final listing in state.nearbyListings) {
      if (listing.id == listingId) return listing;
    }
    for (final listing in state.myListings) {
      if (listing.id == listingId) return listing;
    }
    for (final listing in state.favoriteListings) {
      if (listing.id == listingId) return listing;
    }
    return null;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _PriceBadge extends StatelessWidget {
  final MarketplaceListing listing;

  const _PriceBadge({required this.listing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        listing.priceDisplay,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final ListingStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case ListingStatus.active:
        color = Colors.green;
        break;
      case ListingStatus.reserved:
        color = Colors.orange;
        break;
      case ListingStatus.sold:
        color = Colors.red;
        break;
      case ListingStatus.inactive:
        color = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Text(status.displayName,
          style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;

  const _InfoRow({required this.icon, required this.label, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.onSurface.withAlpha(153)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.bodyMedium),
              if (subtitle != null)
                Text(subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(128))),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final int value;

  const _StatChip({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurface.withAlpha(128)),
        const SizedBox(width: 4),
        Text('$value',
            style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(153))),
      ],
    );
  }
}
