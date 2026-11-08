import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kisalu_express/core/state/estado_ui.dart';
import 'package:kisalu_express/core/widgets/widgets.dart';

import '../../helpers/montar_widget.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Widget montar(Widget filho, {double escalaTexto = 1}) =>
      montarWidget(filho, escalaTexto: escalaTexto, rolavel: true);

  group('KEstadoBuilder', () {
    Widget construir(EstadoUi<List<String>> estado, {VoidCallback? onTentar}) =>
        montar(
          KEstadoBuilder<List<String>>(
            estado: estado,
            onTentar: onTentar,
            rotuloNaoEncontrado: 'Ver os meus pedidos',
            sucesso: (_, dados) => Text(dados.join(',')),
            vazio: (_) => const Text('lista vazia'),
          ),
        );

    testWidgets('a carregar mostra esqueletos', (tester) async {
      await tester.pumpWidget(construir(const Carregar()));
      expect(find.byType(KSkeleton), findsWidgets);
    });

    testWidgets('sucesso e vazio', (tester) async {
      await tester.pumpWidget(construir(const Sucesso(['a', 'b'])));
      expect(find.text('a,b'), findsOneWidget);
      await tester.pumpWidget(construir(const Vazio()));
      expect(find.text('lista vazia'), findsOneWidget);
    });

    testWidgets('erro mostra a mensagem e tenta outra vez', (tester) async {
      var tentativas = 0;
      await tester.pumpWidget(
        construir(
          const Erro('Sem ligação. Confirme a sua rede e tente outra vez.'),
          onTentar: () => tentativas++,
        ),
      );
      expect(find.text('Não foi possível carregar'), findsOneWidget);
      expect(
        find.text('Sem ligação. Confirme a sua rede e tente outra vez.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Tentar outra vez'));
      expect(tentativas, 1);
    });

    testWidgets('não encontrado tem estado próprio', (tester) async {
      await tester.pumpWidget(
        construir(
          const Erro(
            'Não encontrámos este pedido. Veja os seus pedidos.',
            naoEncontrado: true,
          ),
        ),
      );
      expect(find.text('Não encontrado'), findsOneWidget);
      expect(find.text('Ver os meus pedidos'), findsOneWidget);
      expect(find.text('Tentar outra vez'), findsNothing);
    });
  });
}
