import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kisalu_express/core/theme/k_icons.dart';
import 'package:kisalu_express/core/widgets/widgets.dart';

import '../../helpers/montar_widget.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Widget montar(Widget filho, {double escalaTexto = 1}) =>
      montarWidget(filho, escalaTexto: escalaTexto);

  group('KRatingInline', () {
    testWidgets('uma estrela + "4,8" + "(126)" e rótulo acessível', (
      tester,
    ) async {
      await tester.pumpWidget(
        montar(const KRatingInline(valor: 4.8, numAvaliacoes: 126)),
      );
      expect(find.byIcon(KIcons.estrela), findsOneWidget);
      expect(find.textContaining('4,8'), findsOneWidget);
      expect(find.textContaining('(126)'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Avaliação 4,8 em 5, 126 avaliações'),
        findsOneWidget,
      );
    });

    testWidgets('sufixo de chegada', (tester) async {
      await tester.pumpWidget(
        montar(const KRatingInline(valor: 4.6, sufixo: 'chega em 1 h')),
      );
      expect(find.textContaining('4,6 · chega em 1 h'), findsOneWidget);
    });
  });
}
