import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kisalu_express/core/widgets/widgets.dart';

import '../../helpers/montar_widget.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Widget montar(Widget filho, {double escalaTexto = 1}) =>
      montarWidget(filho, escalaTexto: escalaTexto);

  group('KPriceText', () {
    testWidgets('formata em Kz e anuncia kwanzas', (tester) async {
      await tester.pumpWidget(montar(const KPriceText(12500)));
      expect(find.text('12.500 Kz'), findsOneWidget);
      expect(find.bySemanticsLabel('12.500 kwanzas'), findsOneWidget);
      final texto = tester.widget<Text>(find.text('12.500 Kz'));
      expect(texto.style!.fontSize, KPriceText.cartao);
      expect(texto.style!.fontWeight, FontWeight.w800);
      expect(texto.overflow, isNot(TextOverflow.ellipsis));
    });

    testWidgets('preço grande a 200 % quebra linha sem overflow', (
      tester,
    ) async {
      await tester.pumpWidget(
        montar(
          const Row(
            children: [
              Expanded(child: Text('Valor fechado')),
              Flexible(
                child: KPriceText(1250000, tamanho: KPriceText.destaque),
              ),
            ],
          ),
          escalaTexto: 2,
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
