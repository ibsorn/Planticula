import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:planticula/features/marketplace/domain/entities/marketplace_listing.dart';
import 'package:planticula/features/marketplace/presentation/bloc/marketplace_bloc.dart';
import 'package:planticula/features/marketplace/presentation/widgets/marketplace_listing_image.dart';

class MarketplaceMyListingCard extends StatelessWidget {
  final MarketplaceListing listing;

  const MarketplaceMyListingCard({
    super.key,
    required this.listing,
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
            MarketplaceListingImage(listing: listing, size: 120),

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
