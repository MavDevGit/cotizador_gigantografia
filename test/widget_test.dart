// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cotizador_gigantografia/main.dart';
import 'package:cotizador_gigantografia/app_state/app_state.dart';

void main() {
  testWidgets('App should load without errors', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => AppState(),
        child: const CotizadorApp(),
      ),
    );

    // Verify that the app loads without errors
    expect(find.byType(CotizadorApp), findsOneWidget);
  });
}
