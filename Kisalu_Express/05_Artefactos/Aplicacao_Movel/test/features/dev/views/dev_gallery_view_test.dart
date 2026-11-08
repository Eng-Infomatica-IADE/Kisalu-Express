import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kisalu_express/core/router/app_router.dart';
import 'package:kisalu_express/core/router/app_routes.dart';

void main() {
  // Nos testes não há rede: as fontes caem no fallback do sistema.
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('a galeria abre os componentes do design system', (tester) async {
    final router = createRouter(initialLocation: AppRoutes.dev);
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Componentes'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Componentes (dev)'), findsOneWidget);
    expect(find.text('Botão primário'), findsOneWidget);
    expect(find.text('Pedir serviço'), findsOneWidget);
  });
}
