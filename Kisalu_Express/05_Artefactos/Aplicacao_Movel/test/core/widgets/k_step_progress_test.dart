import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kisalu_express/core/theme/k_colors.dart';
import 'package:kisalu_express/core/widgets/widgets.dart';

import '../../helpers/montar_widget.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Widget montar(Widget filho, {double escalaTexto = 1}) =>
      montarWidget(filho, escalaTexto: escalaTexto, rolavel: true);

  group('KStepProgress', () {
    testWidgets('barras concluídas a laranja e legenda acessível', (
      tester,
    ) async {
      await tester.pumpWidget(
        montar(
          const KStepProgress(total: 4, atual: 3, legenda: 'Rever o pedido'),
        ),
      );
      expect(find.text('Passo 3 de 4 · Rever o pedido'), findsOneWidget);
      final barras = tester
          .widgetList<Container>(
            find.descendant(
              of: find.byType(KStepProgress),
              matching: find.byType(Container),
            ),
          )
          .map((c) => (c.decoration! as BoxDecoration).color)
          .toList();
      expect(barras, [
        KColors.laranja,
        KColors.laranja,
        KColors.laranja,
        KColors.areia200,
      ]);
      expect(
        find.bySemanticsLabel('Passo 3 de 4 · Rever o pedido'),
        findsOneWidget,
      );
    });
  });
}
