import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';

/// Exception for missing Supabase configuration
class SupabaseConfigException implements Exception {
  final String message;
  SupabaseConfigException(this.message);

  @override
  String toString() => 'SupabaseConfigException: $message';
}

/// Centralized Supabase client with singleton pattern
/// NO hardcoded credentials - all loaded from environment variables
class SupabaseClient {
  static SupabaseClient? _instance;
  Supabase? _supabase;
  final Logger _logger = Logger();
  bool _isInitialized = false;

  SupabaseClient._();

  static SupabaseClient get instance {
    _instance ??= SupabaseClient._();
    return _instance!;
  }

  /// Returns true if Supabase has been initialized
  bool get isInitialized => _isInitialized;

  /// Internal Supabase instance - throws if not initialized
  Supabase get _requireSupabase {
    if (_supabase == null) {
      throw SupabaseConfigException(
        'Supabase not initialized. Call initialize() first.',
      );
    }
    return _supabase!;
  }

  // Public accessors to Supabase services
  GoTrueClient get auth => _requireSupabase.client.auth;
  SupabaseQueryBuilder from(String table) => _requireSupabase.client.from(table);
  SupabaseStorageClient get storage => _requireSupabase.client.storage;
  FunctionsClient get functions => _requireSupabase.client.functions;
  RealtimeClient get realtime => _requireSupabase.client.realtime;

  /// Initialize Supabase with environment variables from .env file
  /// Call this in main() before runApp()
  ///
  /// Required environment variables:
  /// - SUPABASE_URL: Your Supabase project URL
  /// - SUPABASE_ANON_KEY: Your Supabase anon/public key
  ///
  /// IMPORTANT: Never commit .env file with real credentials to git!
  Future<void> initialize() async {
    if (_isInitialized) {
      _logger.w('Supabase already initialized');
      return;
    }

    try {
      // Load environment variables
      await dotenv.load(fileName: '.env');

      final url = dotenv.env['SUPABASE_URL'];
      final anonKey = dotenv.env['SUPABASE_ANON_KEY'];

      if (url == null || url.isEmpty) {
        throw SupabaseConfigException(
          'SUPABASE_URL not found in .env file.\n'
          'Please copy .env.example to .env and fill in your credentials.',
        );
      }

      if (anonKey == null || anonKey.isEmpty) {
        throw SupabaseConfigException(
          'SUPABASE_ANON_KEY not found in .env file.\n'
          'Please copy .env.example to .env and fill in your credentials.',
        );
      }

      // Validate URL format
      if (!url.startsWith('https://')) {
        throw SupabaseConfigException(
          'Invalid SUPABASE_URL. Must start with https://',
        );
      }

      _supabase = await Supabase.initialize(
        url: url,
        anonKey: anonKey,
        debug: kDebugMode,
        // Enable persistence for offline support
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      );

      _isInitialized = true;
      _logger.i('✅ Supabase initialized successfully');
      _logger.i('   Project URL: $url');
    } on SupabaseConfigException {
      rethrow;
    } catch (e, stackTrace) {
      _logger.e(
        '❌ Failed to initialize Supabase',
        error: e,
        stackTrace: stackTrace,
      );
      throw SupabaseConfigException(
        'Failed to initialize Supabase: ${e.toString()}',
      );
    }
  }

  // ============== Auth State Helpers ==============

  /// Check if user is authenticated
  bool get isAuthenticated => auth.currentUser != null;

  /// Get current user
  User? get currentUser => auth.currentUser;

  /// Get current session
  Session? get currentSession => auth.currentSession;

  /// Listen to auth state changes
  Stream<supabase.AuthState> get onAuthStateChange => auth.onAuthStateChange;

  // ============== Edge Functions ==============

  /// Invoke an Edge Function
  /// This is the preferred way to access external services
  /// to keep secrets server-side
  ///
  /// Example:
  /// ```dart
  /// final response = await supabaseClient.invokeEdgeFunction(
  ///   functionName: 'analyze-soil',
  ///   body: {'image_url': imageUrl},
  /// );
  /// ```
  Future<FunctionResponse<T>> invokeEdgeFunction<T>({
    required String functionName,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await functions.invoke(
        functionName,
        body: body,
        headers: headers,
      );
      _logger.d('✅ Edge Function $functionName invoked successfully');
      return response as FunctionResponse<T>;
    } catch (e, stackTrace) {
      _logger.e(
        '❌ Edge Function $functionName failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  // ============== Helper Methods ==============

  /// Sign out user and clear session
  Future<void> signOut() async {
    await auth.signOut();
    _logger.i('👋 User signed out');
  }

  /// Refresh the current session
  Future<void> refreshSession() async {
    await auth.refreshSession();
    _logger.d('🔄 Session refreshed');
  }

  /// Get the current JWT token (useful for Edge Functions)
  String? get currentJwtToken => currentSession?.accessToken;

  /// Dispose and cleanup (useful for testing)
  void dispose() {
    _supabase?.dispose();
    _supabase = null;
    _isInitialized = false;
    _logger.w('🗑️ Supabase client disposed');
  }
}

/// Global accessor for convenience
SupabaseClient get supabaseClient => SupabaseClient.instance;
