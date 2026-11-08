import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kisalu_express/core/theme/k_colors.dart';
import 'package:kisalu_express/core/theme/k_icons.dart';
import 'package:kisalu_express/core/theme/k_tokens.dart';
import 'package:kisalu_express/core/widgets/widgets.dart';
import 'package:kisalu_express/models/estado_pedido.dart';

import '../../helpers/montar_widget.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Widget montar(Widget filho, {double escalaTexto = 1}) =>
      montarWidget(filho, escalaTexto: escalaTexto);

  group('KStatusBadge', () {
    final casos = {
      EstadoPedido.novo: ('NOVO', KColors.tomClaro, KColors.brasa),
      EstadoPedido.emCurso: ('EM CURSO', KColors.tomClaro, KColors.brasa),
      EstadoPedido.concluido: (
        'CONCLUÍDO',
        KColors.sucessoFundo,
        KColors.sucesso,
      ),
      EstadoPedido.cancelado: ('CANCELADO', KColors.erroFundo, KColors.erro),
    };
    for (final MapEntry(key: estado, value: (texto, fundo, cor))
        in casos.entries) {
      testWidgets('$texto: texto em maiúsculas e cores do guia', (
        tester,
      ) async {
        await tester.pumpWidget(montar(KStatusBadge.estado(estado)));
        expect(find.text(texto), findsOneWidget);
        expect(tester.widget<Text>(find.text(texto)).style!.color, cor);
        final caixa = tester.widget<Container>(find.byType(Container));
        expect((caixa.decoration! as BoxDecoration).color, fundo);
      });
    }

    testWidgets('propostas no singular e no plural', (tester) async {
      await tester.pumpWidget(
        montar(
          Column(
            children: [KStatusBadge.propostas(1), KStatusBadge.propostas(3)],
          ),
        ),
      );
      expect(find.text('1 PROPOSTA'), findsOneWidget);
      expect(find.text('3 PROPOSTAS'), findsOneWidget);
    });

    testWidgets('verificado tem escudo', (tester) async {
      await tester.pumpWidget(montar(KStatusBadge.verificado()));
      expect(find.text('VERIFICADO'), findsOneWidget);
      expect(find.byIcon(KIcons.verificado), findsOneWidget);
    });
  });

  testWidgets('verificado é uma pílula', (tester) async {
    await tester.pumpWidget(montarWidget(KStatusBadge.verificado()));
    final caixa = tester.widget<Container>(find.byType(Container).first);
    final decoracao = caixa.decoration! as BoxDecoration;
    expect(decoracao.borderRadius, BorderRadius.circular(K.raioPilula));
  });

  testWidgets('envio: ENVIADO verde e FALTA em tom claro', (tester) async {
    await tester.pumpWidget(
      montarWidget(
        Column(
          children: [
            KStatusBadge.envio(enviado: true),
            KStatusBadge.envio(enviado: false, compacta: true),
          ],
        ),
      ),
    );
    expect(find.text('ENVIADO'), findsOneWidget);
    expect(find.text('FALTA'), findsOneWidget);
    final cores = tester
        .widgetList<Container>(find.byType(Container))
        .map((c) => (c.decoration! as BoxDecoration).color)
        .toList();
    // ENVIADO em verde sobre branco, com contorno (AA).
    expect(cores, [KColors.branco, KColors.tomClaro]);
  });
}
