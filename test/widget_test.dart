import 'package:flutter_test/flutter_test.dart';

import 'package:planticula/main.dart';

void main() {
  testWidgets('App smoke test - shows error screen without Supabase config', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(
      supabaseInitialized: false,
      supabaseError: 'Test: Supabase not configured',
    ));

    expect(find.text('Error de Configuración'), findsOneWidget);
  });
}
