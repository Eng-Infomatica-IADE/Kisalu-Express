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

  group('KCategoryTile', () {
    testWidgets('ícone + rótulo, 64 dp, selecionada a laranja', (tester) async {
      var toques = 0;
      await tester.pumpWidget(
        montar(
          Row(
            children: [
              KCategoryTile(
                icone: KIcons.canalizador,
                rotulo: 'Canalizador',
                selecionada: true,
                onTap: () => toques++,
              ),
              KCategoryTile(
                icone: KIcons.eletricista,
                rotulo: 'Eletricista',
                onTap: () {},
              ),
            ],
          ),
        ),
      );
      expect(find.text('Canalizador'), findsOneWidget);
      final materiais = tester
          .widgetList<Material>(
            find.descendant(
              of: find.byType(KCategoryTile),
              matching: find.byType(Material),
            ),
          )
          .toList();
      expect(materiais[0].color, KColors.laranja);
      expect(materiais[1].color, KColors.tomClaro);
      final quadrado = find.descendant(
        of: find.byType(InkWell).first,
        matching: find.byType(SizedBox),
      );
      expect(tester.getSize(quadrado.first), const Size(64, 64));
      await tester.tap(find.text('Canalizador'));
      expect(toques, 1);
      expect(find.bySemanticsLabel('Canalizador'), findsOneWidget);
    });
  });
}
