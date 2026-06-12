import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:planticula/features/marketplace/domain/entities/marketplace_listing.dart';
import 'package:planticula/features/marketplace/presentation/bloc/marketplace_bloc.dart';
import 'package:planticula/features/marketplace/presentation/widgets/marketplace_listing_image.dart';

class MarketplaceListingCard extends StatelessWidget {
  final MarketplaceListing listing;
  final bool showFavorite;

  const MarketplaceListingCard({
    super.key,
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
            MarketplaceListingImage(listing: listing, size: 120),

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
