import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:planticula/features/marketplace/presentation/bloc/marketplace_bloc.dart';
import 'package:planticula/features/marketplace/presentation/widgets/marketplace_empty_message.dart';
import 'package:planticula/features/marketplace/presentation/widgets/marketplace_error_message.dart';
import 'package:planticula/features/marketplace/presentation/widgets/marketplace_listing_card.dart';
import 'package:planticula/features/marketplace/presentation/widgets/marketplace_location_required.dart';

class MarketplaceNearbyTab extends StatelessWidget {
  const MarketplaceNearbyTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MarketplaceBloc, MarketplaceState>(
      builder: (context, state) {
        if (state.isNearbyLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!state.hasLocation) {
          return MarketplaceLocationRequired(
            onRetry: () => context.read<MarketplaceBloc>().add(MarketplaceLoadNearby()),
          );
        }

        if (state.isNearbyEmpty) {
          return const MarketplaceEmptyMessage(
            icon: Icons.storefront,
            title: 'No hay anuncios cercanos',
            subtitle: 'Sé el primero en publicar en tu zona',
          );
        }

        if (state.hasError && state.nearbyStatus == MarketplaceStatus.error) {
          return MarketplaceErrorMessage(
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
              return MarketplaceListingCard(listing: listing);
            },
          ),
        );
      },
    );
  }
}
