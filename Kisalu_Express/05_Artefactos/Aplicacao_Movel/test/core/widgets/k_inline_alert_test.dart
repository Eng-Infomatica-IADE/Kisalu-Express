import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kisalu_express/core/theme/k_colors.dart';
import 'package:kisalu_express/core/theme/k_icons.dart';
import 'package:kisalu_express/core/widgets/widgets.dart';

import '../../helpers/montar_widget.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Widget montar(Widget filho, {double escalaTexto = 1}) =>
      montarWidget(filho, escalaTexto: escalaTexto, rolavel: true);

  group('KInlineAlert', () {
    testWidgets('erro: fundo, ícone, título a negrito e mensagem', (
      tester,
    ) async {
      await tester.pumpWidget(
        montar(
          const KInlineAlert(
            tipo: KAlertaTipo.erro,
            titulo: 'Sem ligação.',
            mensagem: 'O seu pedido ficou guardado como rascunho.',
          ),
        ),
      );
      expect(
        find.textContaining('Sem ligação. O seu pedido ficou guardado'),
        findsOneWidget,
      );
      expect(find.byIcon(KIcons.aviso), findsOneWidget);
      final caixa = tester.widget<Container>(
        find.descendant(
          of: find.byType(KInlineAlert),
          matching: find.byType(Container),
        ),
      );
      expect((caixa.decoration! as BoxDecoration).color, KColors.erroFundo);
    });

    testWidgets('sucesso usa ícone de concluído', (tester) async {
      await tester.pumpWidget(
        montar(
          const KInlineAlert(
            tipo: KAlertaTipo.sucesso,
            titulo: 'Pedido publicado.',
            mensagem: 'Já avisámos 8 canalizadores perto de si.',
          ),
        ),
      );
      expect(find.byIcon(KIcons.concluido), findsOneWidget);
    });
  });
}
