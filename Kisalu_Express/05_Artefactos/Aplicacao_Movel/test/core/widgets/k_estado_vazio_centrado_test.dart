import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kisalu_express/core/widgets/widgets.dart';

void main() {
  testWidgets('centra o filho na área visível', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: KEstadoVazioCentrado(filho: Text('vazio'))),
      ),
    );
    final area = tester.getCenter(find.byType(Scaffold));
    final filho = tester.getCenter(find.text('vazio'));
    expect(filho.dy, closeTo(area.dy, 1));
  });

  testWidgets('rola em vez de transbordar se não couber', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: KEstadoVazioCentrado(filho: SizedBox(height: 2000)),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });
}
