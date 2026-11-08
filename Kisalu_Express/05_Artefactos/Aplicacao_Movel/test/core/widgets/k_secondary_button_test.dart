import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kisalu_express/core/theme/k_colors.dart';
import 'package:kisalu_express/core/widgets/widgets.dart';

import '../../helpers/montar_widget.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Widget montar(Widget filho, {double escalaTexto = 1}) =>
      montarWidget(filho, escalaTexto: escalaTexto);

  /// Cor de fundo do AnimatedContainer do botão.
  Color? fundo(WidgetTester tester) {
    final container = tester.widget<AnimatedContainer>(
      find.byType(AnimatedContainer),
    );
    return (container.decoration as BoxDecoration?)?.color;
  }

  Color corDoTexto(WidgetTester tester, String rotulo) =>
      tester.widget<Text>(find.text(rotulo)).style!.color!;

  group('KSecondaryButton', () {
    testWidgets('contorno laranja e fundo branco; premido fica tom claro', (
      tester,
    ) async {
      await tester.pumpWidget(
        montar(KSecondaryButton(rotulo: 'Criar conta', onPressed: () {})),
      );
      final deco =
          tester
                  .widget<AnimatedContainer>(find.byType(AnimatedContainer))
                  .decoration!
              as BoxDecoration;
      expect(deco.color, KColors.branco);
      expect((deco.border! as Border).top.color, KColors.laranja);
      expect(corDoTexto(tester, 'Criar conta'), KColors.laranja);

      final gesto = await tester.startGesture(
        tester.getCenter(find.text('Criar conta')),
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(fundo(tester), KColors.tomClaro);
      await gesto.up();
    });

    testWidgets('sem largura total ocupa só o necessário', (tester) async {
      await tester.pumpWidget(
        montar(
          Align(
            alignment: Alignment.topLeft,
            child: KSecondaryButton(
              rotulo: 'Ver',
              larguraTotal: false,
              onPressed: () {},
            ),
          ),
        ),
      );
      expect(
        tester.getSize(find.byType(AnimatedContainer)).width,
        lessThan(328),
      );
    });

    testWidgets('compacto tem 48 dp', (tester) async {
      await tester.pumpWidget(
        montar(
          Align(
            alignment: Alignment.topLeft,
            child: KSecondaryButton(
              rotulo: 'Ligar',
              compacto: true,
              larguraTotal: false,
              onPressed: () {},
            ),
          ),
        ),
      );
      expect(tester.getSize(find.byType(AnimatedContainer)).height, 48);
    });
  });
}
