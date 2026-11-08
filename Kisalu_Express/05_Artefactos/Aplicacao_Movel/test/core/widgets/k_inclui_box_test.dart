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

  group('KIncluiBox', () {
    testWidgets('mostra "Inclui:" e o texto', (tester) async {
      await tester.pumpWidget(
        montar(const KIncluiBox(texto: 'mão de obra · material · deslocação')),
      );
      expect(
        find.textContaining(
          'Inclui: mão de obra · material · deslocação',
          findRichText: true,
        ),
        findsOneWidget,
      );
    });

    testWidgets('aviso aparece a vermelho', (tester) async {
      await tester.pumpWidget(
        montar(
          const KIncluiBox(
            texto: 'mão de obra · deslocação',
            aviso: 'Material não incluído.',
          ),
        ),
      );
      final rico = tester.widget<RichText>(
        find.descendant(
          of: find.byType(KIncluiBox),
          matching: find.byType(RichText),
        ),
      );
      TextSpan? aviso;
      rico.text.visitChildren((span) {
        if (span is TextSpan && (span.text ?? '').contains('Material')) {
          aviso = span;
        }
        return true;
      });
      expect(aviso!.text, contains('Material não incluído.'));
      expect(aviso!.style!.color, KColors.erro);
    });
  });
}
