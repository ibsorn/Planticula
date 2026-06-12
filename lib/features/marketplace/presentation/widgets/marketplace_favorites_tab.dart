import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:planticula/features/marketplace/presentation/bloc/marketplace_bloc.dart';
import 'package:planticula/features/marketplace/presentation/widgets/marketplace_empty_message.dart';
import 'package:planticula/features/marketplace/presentation/widgets/marketplace_listing_card.dart';

class MarketplaceFavoritesTab extends StatelessWidget {
  const MarketplaceFavoritesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MarketplaceBloc, MarketplaceState>(
      builder: (context, state) {
        if (state.isFavoritesLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.favoritesStatus == MarketplaceStatus.empty) {
          return const MarketplaceEmptyMessage(
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
              return MarketplaceListingCard(listing: listing, showFavorite: false);
            },
          ),
        );
      },
    );
  }
}
