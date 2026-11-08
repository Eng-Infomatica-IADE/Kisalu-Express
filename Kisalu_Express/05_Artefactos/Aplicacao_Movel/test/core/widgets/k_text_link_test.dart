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

  Color corDoTexto(WidgetTester tester, String rotulo) =>
      tester.widget<Text>(find.text(rotulo)).style!.color!;

  group('KTextLink', () {
    testWidgets('laranja, alvo ≥ 48 dp e chama onPressed', (tester) async {
      var toques = 0;
      await tester.pumpWidget(
        montar(
          Align(
            alignment: Alignment.topLeft,
            child: KTextLink(
              rotulo: 'Avaliar mais tarde',
              onPressed: () => toques++,
            ),
          ),
        ),
      );
      expect(corDoTexto(tester, 'Avaliar mais tarde'), KColors.laranja);
      final tamanho = tester.getSize(find.byType(AnimatedContainer));
      expect(tamanho.height, greaterThanOrEqualTo(48));
      await tester.tap(find.text('Avaliar mais tarde'));
      expect(toques, 1);
    });

    testWidgets('destrutivo usa a cor de erro', (tester) async {
      await tester.pumpWidget(
        montar(
          Align(
            alignment: Alignment.topLeft,
            child: KTextLink(
              rotulo: 'O trabalho tem um problema?',
              destrutivo: true,
              onPressed: () {},
            ),
          ),
        ),
      );
      expect(corDoTexto(tester, 'O trabalho tem um problema?'), KColors.erro);
    });

    testWidgets('desativado fica neutro', (tester) async {
      await tester.pumpWidget(
        montar(
          const Align(
            alignment: Alignment.topLeft,
            child: KTextLink(rotulo: 'Mais tarde', onPressed: null),
          ),
        ),
      );
      expect(corDoTexto(tester, 'Mais tarde'), KColors.neutro500);
    });
  });

  testWidgets('grande usa 15 sp, normal 14 sp', (tester) async {
    await tester.pumpWidget(
      montarWidget(
        const Column(
          children: [
            KTextLink(rotulo: 'Normal', onPressed: null),
            KTextLink(rotulo: 'Grande', onPressed: null, grande: true),
          ],
        ),
      ),
    );
    expect(tester.widget<Text>(find.text('Normal')).style!.fontSize, 14);
    expect(tester.widget<Text>(find.text('Grande')).style!.fontSize, 15);
  });
}
