import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:planticula/core/constants/app_constants.dart';
import 'package:planticula/features/marketplace/presentation/bloc/marketplace_bloc.dart';
import 'package:planticula/shared/widgets/empty_state.dart';
import 'package:planticula/features/marketplace/presentation/widgets/marketplace_my_listing_card.dart';

class MarketplaceMyListingsTab extends StatelessWidget {
  const MarketplaceMyListingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MarketplaceBloc, MarketplaceState>(
      builder: (context, state) {
        if (state.isMyListingsLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.isMyListingsEmpty) {
          return EmptyState(
            icon: Icons.post_add,
            title: 'No tienes anuncios',
            message: 'Publica tu primera planta o esqueje',
            actionLabel: 'Crear anuncio',
            actionIcon: Icons.add,
            onAction: () => context.push(AppConstants.routeCreateListing),
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
              return MarketplaceMyListingCard(listing: listing);
            },
          ),
        );
      },
    );
  }
}
