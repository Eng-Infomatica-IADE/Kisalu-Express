import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kisalu_express/core/widgets/widgets.dart';

import '../../helpers/montar_widget.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Widget montar(Widget filho, {double escalaTexto = 1}) =>
      montarWidget(filho, escalaTexto: escalaTexto, rolavel: true);

  group('KLinhaChaveValor', () {
    testWidgets('mostra rótulo e valor', (tester) async {
      await tester.pumpWidget(
        montar(
          const Column(
            children: [
              KLinhaChaveValor(
                rotulo: 'Profissional',
                valor: 'Joaquim Manuel ✓',
              ),
              KLinhaChaveValor.preco(rotulo: 'Valor fechado', valor: 12500),
            ],
          ),
        ),
      );
      expect(find.text('Profissional'), findsOneWidget);
      expect(find.text('Joaquim Manuel ✓'), findsOneWidget);
      expect(find.text('12.500 Kz'), findsOneWidget);
    });

    testWidgets('texto a 200 % sem overflow', (tester) async {
      await tester.pumpWidget(
        montar(
          const KLinhaChaveValor(
            rotulo: 'Chegada prevista',
            valor: 'Hoje, 15h40',
          ),
          escalaTexto: 2,
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
