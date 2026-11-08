import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kisalu_express/core/theme/k_colors.dart';
import 'package:kisalu_express/core/widgets/widgets.dart';

import '../../helpers/montar_widget.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('KPilulaAcao', () {
    testWidgets('sem ação é só indicação visual, escondida do leitor', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      await tester.pumpWidget(montarWidget(const KPilulaAcao(rotulo: 'Ver')));
      expect(find.text('Ver'), findsOneWidget);
      expect(find.bySemanticsLabel('Ver'), findsNothing);
      semantica.dispose();
    });

    testWidgets('com ação é um botão com alvo de 48 dp', (tester) async {
      var toques = 0;
      await tester.pumpWidget(
        montarWidget(
          Align(
            alignment: Alignment.topLeft,
            child: KPilulaAcao(rotulo: 'Ver', onPressed: () => toques++),
          ),
          comMargem: false,
        ),
      );
      final alvo = tester.getSize(
        find
            .descendant(
              of: find.byType(KPilulaAcao),
              matching: find.byType(ConstrainedBox),
            )
            .first,
      );
      expect(alvo.height, greaterThanOrEqualTo(48));
      expect(alvo.width, greaterThanOrEqualTo(48));
      await tester.tap(find.text('Ver'));
      expect(toques, 1);
    });

    testWidgets('usa o nome descritivo quando existe', (tester) async {
      final semantica = tester.ensureSemantics();
      await tester.pumpWidget(
        montarWidget(
          KPilulaAcao(
            rotulo: 'Ver pedido',
            rotuloSemantico: 'Ver pedido Fuga de água',
            onPressed: () {},
          ),
        ),
      );
      expect(find.bySemanticsLabel('Ver pedido Fuga de água'), findsOneWidget);
      semantica.dispose();
    });

    testWidgets('tom claro com texto Brasa a negrito', (tester) async {
      await tester.pumpWidget(montarWidget(const KPilulaAcao(rotulo: 'Ver')));
      final caixa = tester.widget<Container>(find.byType(Container).first);
      expect((caixa.decoration! as BoxDecoration).color, KColors.tomClaro);
      final texto = tester.widget<Text>(find.text('Ver'));
      expect(texto.style!.color, KColors.brasa);
      expect(texto.style!.fontWeight, FontWeight.w700);
    });

    testWidgets('larga: mais padding e texto de 14 sp', (tester) async {
      await tester.pumpWidget(
        montarWidget(const KPilulaAcao(rotulo: 'Ver pedido', larga: true)),
      );
      expect(tester.widget<Text>(find.text('Ver pedido')).style!.fontSize, 14);
    });

    testWidgets('sem overflow com texto a 200 %', (tester) async {
      await tester.pumpWidget(
        montarWidget(
          const KPilulaAcao(rotulo: 'Ver pedido', larga: true),
          escalaTexto: 2,
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
