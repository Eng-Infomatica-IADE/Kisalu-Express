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

  group('KSearchField', () {
    testWidgets('lupa laranja, dica e nome acessível', (tester) async {
      await tester.pumpWidget(montar(const KSearchField()));
      expect(find.text('Que serviço precisa hoje?'), findsOneWidget);
      final lupa = tester.widget<Icon>(find.byIcon(KIcons.pesquisa));
      expect(lupa.color, KColors.laranja);
      expect(
        find.bySemanticsLabel(RegExp('Pesquisar serviço')),
        findsOneWidget,
      );
    });

    testWidgets('só leitura funciona como atalho', (tester) async {
      var toques = 0;
      await tester.pumpWidget(
        montar(KSearchField(soLeitura: true, onTap: () => toques++)),
      );
      await tester.tap(find.byType(TextField));
      expect(toques, 1);
    });
  });
}
