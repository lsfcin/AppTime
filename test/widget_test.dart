import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:apptime/main.dart';
import 'package:apptime/services/storage_service.dart';

void main() {
  testWidgets('App smoke test — navega entre as 3 tabs', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.init();

    await tester.pumpWidget(AppTimeApp(storage: storage));
    await tester.pumpAndSettle();

    expect(find.text('Início'), findsWidgets);

    await tester.tap(find.byIcon(Icons.bar_chart_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Análise'), findsWidgets);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Configurações'), findsWidgets);
  });
}
