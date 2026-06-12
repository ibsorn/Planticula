import 'package:flutter/material.dart';
import 'package:planticula/features/marketplace/domain/entities/marketplace_listing.dart';

class MarketplaceListingImage extends StatelessWidget {
  final MarketplaceListing listing;
  final double size;

  const MarketplaceListingImage({
    super.key,
    required this.listing,
    required this.size,
  });

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
