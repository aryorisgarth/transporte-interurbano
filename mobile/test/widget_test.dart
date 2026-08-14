import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transporte_mobile/features/consulta/presentation/landing_page.dart';

void main() {
  testWidgets('Landing muestra roles públicos', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: LandingPage()));
    await tester.pump();

    expect(find.text('Pasajero'), findsOneWidget);
    expect(find.text('Consultar viajes'), findsOneWidget);
    expect(find.text('Entrar como cajero'), findsOneWidget);
  });
}
