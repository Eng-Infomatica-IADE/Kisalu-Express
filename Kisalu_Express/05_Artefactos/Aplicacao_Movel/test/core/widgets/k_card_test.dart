import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kisalu_express/core/theme/k_colors.dart';
import 'package:kisalu_express/core/theme/k_tokens.dart';
import 'package:kisalu_express/core/widgets/widgets.dart';

import '../../helpers/montar_widget.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Widget montar(Widget filho, {double escalaTexto = 1}) =>
      montarWidget(filho, escalaTexto: escalaTexto, rolavel: true);

  group('KCard', () {
    testWidgets('branco, raio 20, sombra; tocável quando tem onTap', (
      tester,
    ) async {
      var toques = 0;
      await tester.pumpWidget(
        montar(KCard(onTap: () => toques++, child: const Text('Cartão'))),
      );
      final caixa = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(KCard),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      expect((caixa.decoration as BoxDecoration).boxShadow, K.sombraCartao);
      await tester.tap(find.text('Cartão'));
      expect(toques, 1);
    });

    testWidgets('destacado: borda laranja e sem sombra', (tester) async {
      await tester.pumpWidget(
        montar(const KCard(destacado: true, child: Text('Cartão'))),
      );
      final material = tester.widget<Material>(
        find
            .ancestor(of: find.text('Cartão'), matching: find.byType(Material))
            .first,
      );
      final forma = material.shape! as RoundedRectangleBorder;
      expect(forma.side.color, KColors.laranja);
      final caixa = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(KCard),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      expect((caixa.decoration as BoxDecoration).boxShadow, isNull);
    });

    testWidgets('sem onTap não é botão', (tester) async {
      await tester.pumpWidget(montar(const KCard(child: Text('Cartão'))));
      expect(find.byType(InkWell), findsNothing);
    });
  });
}
