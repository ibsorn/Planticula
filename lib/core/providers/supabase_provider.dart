import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:planticula/core/network/supabase_client.dart';

/// Provider that manages Supabase connection state
/// Use this to access Supabase services and listen to connection changes
class SupabaseProvider extends InheritedWidget {
  final SupabaseClient client;
  final bool isInitialized;
  final String? error;

  const SupabaseProvider({
    super.key,
    required this.client,
    required super.child,
    this.isInitialized = false,
    this.error,
  });

  static SupabaseProvider of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<SupabaseProvider>();
    assert(provider != null, 'No SupabaseProvider found in context');
    return provider!;
  }

  static SupabaseProvider? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<SupabaseProvider>();
  }

  @override
  bool updateShouldNotify(SupabaseProvider oldWidget) {
    return isInitialized != oldWidget.isInitialized ||
        error != oldWidget.error ||
        client != oldWidget.client;
  }
}

/// Widget that initializes Supabase and provides it to the app
class SupabaseInitializer extends StatefulWidget {
  final Widget child;
  final Widget? loadingWidget;
  final Widget Function(String error)? errorBuilder;

  const SupabaseInitializer({
    super.key,
    required this.child,
    this.loadingWidget,
    this.errorBuilder,
  });

  @override
  State<SupabaseInitializer> createState() => _SupabaseInitializerState();
}

class _SupabaseInitializerState extends State<SupabaseInitializer> {
  bool _isInitialized = false;
  String? _error;
  late final SupabaseClient _client;

  @override
  void initState() {
    super.initState();
    _client = SupabaseClient.instance;
    _initializeSupabase();
  }

  Future<void> _initializeSupabase() async {
    try {
      await _client.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null && widget.errorBuilder != null) {
      return widget.errorBuilder!(_error!);
    }

    if (!_isInitialized) {
      return widget.loadingWidget ??
          const MaterialApp(
            home: Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Inicializando...'),
                  ],
                ),
              ),
            ),
          );
    }

    return SupabaseProvider(
      client: _client,
      isInitialized: _isInitialized,
      error: _error,
      child: widget.child,
    );
  }
}

/// Extension to easily access Supabase from BuildContext
extension SupabaseContextExtension on BuildContext {
  SupabaseClient get supabase {
    final provider = SupabaseProvider.maybeOf(this);
    if (provider == null) {
      return SupabaseClient.instance;
    }
    return provider.client;
  }

  bool get isSupabaseInitialized {
    final provider = SupabaseProvider.maybeOf(this);
    return provider?.isInitialized ?? false;
  }

  String? get supabaseError {
    final provider = SupabaseProvider.maybeOf(this);
    return provider?.error;
  }
}
