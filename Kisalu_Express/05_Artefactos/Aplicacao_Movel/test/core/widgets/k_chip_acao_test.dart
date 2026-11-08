import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kisalu_express/core/theme/k_colors.dart';
import 'package:kisalu_express/core/theme/k_icons.dart';
import 'package:kisalu_express/core/widgets/widgets.dart';

import '../../helpers/montar_widget.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('KChipAcao', () {
    testWidgets('mostra ícone e rótulo laranja e reage ao toque', (
      tester,
    ) async {
      var toques = 0;
      await tester.pumpWidget(
        montarWidget(
          Align(
            alignment: Alignment.topLeft,
            child: KChipAcao(
              rotulo: 'Lista',
              icone: KIcons.pedidos,
              onTap: () => toques++,
            ),
          ),
        ),
      );
      expect(find.text('Lista'), findsOneWidget);
      final icone = tester.widget<Icon>(find.byIcon(KIcons.pedidos));
      expect(icone.color, KColors.laranja);
      final texto = tester.widget<Text>(find.text('Lista'));
      expect(texto.style!.color, KColors.laranja);
      expect(texto.style!.fontWeight, FontWeight.w700);
      await tester.tap(find.text('Lista'));
      expect(toques, 1);
    });

    testWidgets('é um botão com o rótulo como nome e alvo de 48 dp', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      await tester.pumpWidget(
        montarWidget(
          Align(
            alignment: Alignment.topLeft,
            child: KChipAcao(
              rotulo: 'Mapa',
              icone: KIcons.localizacao,
              onTap: () {},
            ),
          ),
        ),
      );
      expect(find.bySemanticsLabel('Mapa'), findsOneWidget);
      expect(
        tester.getSize(find.byType(KChipAcao)).height,
        greaterThanOrEqualTo(48),
      );
      semantica.dispose();
    });

    testWidgets('sem overflow com texto a 200 %', (tester) async {
      await tester.pumpWidget(
        montarWidget(
          KChipAcao(rotulo: 'Lista', icone: KIcons.pedidos, onTap: () {}),
          escalaTexto: 2,
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
