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

  BoxDecoration decoracao(WidgetTester tester, String rotulo) =>
      tester
              .widget<AnimatedContainer>(
                find.ancestor(
                  of: find.text(rotulo),
                  matching: find.byType(AnimatedContainer),
                ),
              )
              .decoration!
          as BoxDecoration;

  group('KSegmentedControl', () {
    testWidgets('opção ativa em branco a negrito e muda ao tocar', (
      tester,
    ) async {
      var valor = false;
      await tester.pumpWidget(
        montar(
          StatefulBuilder(
            builder: (context, setState) => KSegmentedControl<bool>(
              opcoes: const [
                (false, 'Sou cliente'),
                (true, 'Sou profissional'),
              ],
              valor: valor,
              onMudar: (v) => setState(() => valor = v),
            ),
          ),
        ),
      );
      expect(decoracao(tester, 'Sou cliente').color, KColors.branco);
      expect(
        tester.widget<Text>(find.text('Sou cliente')).style!.fontWeight,
        FontWeight.w700,
      );
      await tester.tap(find.text('Sou profissional'));
      await tester.pumpAndSettle();
      expect(valor, isTrue);
      expect(decoracao(tester, 'Sou profissional').color, KColors.branco);
      expect(decoracao(tester, 'Sou cliente').color, isNull);
    });

    testWidgets('altura total ≥ 48 dp', (tester) async {
      await tester.pumpWidget(
        montar(
          KSegmentedControl<int>(
            opcoes: const [(0, 'A'), (1, 'B')],
            valor: 0,
            onMudar: (_) {},
          ),
        ),
      );
      expect(
        tester.getSize(find.byType(KSegmentedControl<int>)).height,
        greaterThanOrEqualTo(48),
      );
    });
  });
}
