// ===========================================================================
// EJEMPLOS DE USO DE SUPABASE EN LA APP
// ===========================================================================
//
// Este archivo muestra cómo usar el cliente de Supabase en diferentes
// escenarios de la aplicación.
//
// No es necesario importar este archivo - es solo documentación.

/*

// ============================================================================
// 1. ACCEDER AL CLIENTE DE SUPABASE DESDE UN WIDGET
// ============================================================================

import 'package:planticula/core/network/supabase_client.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Opción A: Usar el cliente global
    final client = supabaseClient;

    // Opción B: Verificar si está inicializado
    if (supabaseClient.isInitialized) {
      // Safe to use
    }

    return Container();
  }
}


// ============================================================================
// 2. OPERACIONES DE AUTENTICACIÓN
// ============================================================================

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:planticula/features/auth/presentation/bloc/auth_bloc.dart';

class LoginExample extends StatelessWidget {
  void _login(BuildContext context) {
    // Usar AuthBloc (recomendado)
    context.read<AuthBloc>().add(AuthSignInRequested(
      email: 'user@example.com',
      password: 'password123',
    ));
  }

  void _logout(BuildContext context) {
    context.read<AuthBloc>().add(AuthSignOutRequested());
  }
}


// ============================================================================
// 3. OPERACIONES CRUD CON PLANTS
// ============================================================================

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:planticula/features/plants/presentation/bloc/plants_bloc.dart';
import 'package:planticula/features/plants/domain/entities/plant.dart';

class PlantsExample extends StatelessWidget {
  void _loadPlants(BuildContext context) {
    // Cargar todas las plantas del usuario
    context.read<PlantsBloc>().add(PlantsLoadRequested());
  }

  void _createPlant(BuildContext context) {
    final newPlant = Plant(
      id: '',  // Se genera en Supabase
      name: 'Mi Monstera',
      scientificName: 'Monstera deliciosa',
      location: 'Sala de estar',
      acquiredDate: DateTime.now(),
    );

    context.read<PlantsBloc>().add(PlantCreateRequested(newPlant));
  }

  void _deletePlant(BuildContext context, String plantId) {
    context.read<PlantsBloc>().add(PlantDeleteRequested(plantId));
  }
}


// ============================================================================
// 4. USO DIRECTO DEL CLIENTE SUPABASE (para casos avanzados)
// ============================================================================

import 'package:planticula/core/network/supabase_client.dart';

class DirectSupabaseExample {
  final _client = supabaseClient;

  // Realtime subscriptions
  void subscribeToChanges() {
    _client.realtime
        .channel('public:plants')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'plants',
          callback: (payload) {
            print('Change received: ${payload.toString()}');
          },
        )
        .subscribe();
  }

  // Edge Function invocation
  Future<void> analyzeSoil(String imageUrl) async {
    try {
      final response = await _client.invokeEdgeFunction(
        functionName: 'analyze-soil',
        body: {'image_url': imageUrl},
      );
      print('Analysis: ${response.data}');
    } catch (e) {
      print('Error: $e');
    }
  }

  // Storage operations
  Future<void> uploadImage(String filePath, Uint8List bytes) async {
    await _client.storage
        .from('plant-images')
        .uploadBinary(filePath, bytes);
  }

  String getImageUrl(String path) {
    return _client.storage
        .from('plant-images')
        .getPublicUrl(path);
  }
}


// ============================================================================
// 5. MANEJO DE ERRORES
// ============================================================================

import 'package:planticula/core/network/result.dart';

void handleResult<T>(Result<T> result) {
  result.when(
    success: (data) {
      print('Success: $data');
    },
    failure: (message, code, error) {
      print('Error [$code]: $message');
    },
  );
}


// ============================================================================
// 6. VERIFICAR ESTADO DE AUTENTICACIÓN
// ============================================================================

class AuthCheckExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state.isLoading) {
          return CircularProgressIndicator();
        }

        if (state.isAuthenticated) {
          final user = state.user;
          return Text('Bienvenido, ${user?.displayName ?? user?.email}');
        }

        return Text('Por favor inicia sesión');
      },
    );
  }
}

*/
