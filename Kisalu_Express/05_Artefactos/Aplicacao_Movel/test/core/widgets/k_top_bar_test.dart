import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kisalu_express/core/theme/k_colors.dart';
import 'package:kisalu_express/core/theme/k_icons.dart';
import 'package:kisalu_express/core/theme/k_theme.dart';
import 'package:kisalu_express/core/widgets/widgets.dart';

import '../../helpers/montar_widget.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Widget montar(Widget filho, {double escalaTexto = 1}) =>
      montarWidget(filho, escalaTexto: escalaTexto, comMargem: false);

  group('KTopBar', () {
    testWidgets('mostra voltar, título como cabeçalho e ação', (tester) async {
      var acoes = 0;
      var voltas = 0;
      await tester.pumpWidget(
        montar(
          KTopBar(
            titulo: 'O meu pedido',
            onVoltar: () => voltas++,
            acao: KIconButton(
              icone: KIcons.mais,
              rotulo: 'Mais opções',
              onPressed: () => acoes++,
            ),
          ),
        ),
      );
      expect(find.text('O meu pedido'), findsOneWidget);
      expect(find.bySemanticsLabel('Voltar'), findsOneWidget);
      expect(
        tester.getSemantics(find.text('O meu pedido')).flagsCollection.isHeader,
        isTrue,
      );
      expect(
        tester.getSize(find.byType(KTopBar)).height,
        greaterThanOrEqualTo(64),
      );
      await tester.tap(find.bySemanticsLabel('Voltar'));
      await tester.tap(find.bySemanticsLabel('Mais opções'));
      expect((voltas, acoes), (1, 1));
    });

    testWidgets('sem voltar quando mostrarVoltar é false', (tester) async {
      await tester.pumpWidget(
        montar(const KTopBar(titulo: 'Os seus pedidos', mostrarVoltar: false)),
      );
      expect(find.byType(KBackButton), findsNothing);
    });

    testWidgets('título longo a 200 % quebra linha sem overflow', (
      tester,
    ) async {
      await tester.pumpWidget(
        montar(
          const KTopBar(titulo: 'Confirmar serviço com o profissional'),
          escalaTexto: 2,
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('voltar por omissão regressa ao ecrã anterior', (tester) async {
      final router = GoRouter(
        initialLocation: '/a',
        routes: [
          GoRoute(path: '/a', builder: (_, _) => const Text('Ecrã A')),
          GoRoute(
            path: '/b',
            builder: (_, _) => const Scaffold(body: KTopBar(titulo: 'Ecrã B')),
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp.router(theme: KTheme.light(), routerConfig: router),
      );
      router.push('/b');
      await tester.pumpAndSettle();
      expect(find.text('Ecrã B'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Voltar'));
      await tester.pumpAndSettle();
      expect(find.text('Ecrã A'), findsOneWidget);
    });
  });

  testWidgets('escuro: título branco e voltar claro', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: KTheme.light(),
        home: const Scaffold(
          body: KTopBar(titulo: 'Confirmar serviço', escuro: true),
        ),
      ),
    );
    final titulo = tester.widget<Text>(find.text('Confirmar serviço'));
    expect(titulo.style!.color, KColors.branco);
    expect(
      tester.widget<Icon>(find.byIcon(KIcons.voltar)).color,
      KColors.branco,
    );
  });

  testWidgets('tituloCentrado centra o texto', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: KTheme.light(),
        home: const Scaffold(
          body: KTopBar(titulo: 'Perto de si', tituloCentrado: true),
        ),
      ),
    );
    expect(
      tester.widget<Text>(find.text('Perto de si')).textAlign,
      TextAlign.center,
    );
  });
}
