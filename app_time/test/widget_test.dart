import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:app_time/main.dart';

void main() {
  testWidgets('SetupScreen renderiza', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: SetupScreen()));

    expect(find.text('Configuração AppTime'), findsOneWidget);
    expect(find.text('INICIAR MONITORAMENTO'), findsOneWidget);
  });
}
