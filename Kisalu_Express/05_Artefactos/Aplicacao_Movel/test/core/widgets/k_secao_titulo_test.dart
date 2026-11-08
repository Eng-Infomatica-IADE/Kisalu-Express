import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kisalu_express/core/widgets/widgets.dart';

import '../../helpers/montar_widget.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Widget montar(Widget filho, {double escalaTexto = 1}) =>
      montarWidget(filho, escalaTexto: escalaTexto, rolavel: true);

  group('KSecaoTitulo', () {
    testWidgets('título e ligação à direita', (tester) async {
      var toques = 0;
      await tester.pumpWidget(
        montar(
          KSecaoTitulo(
            titulo: 'Trabalhos feitos',
            rotuloAcao: 'Ver todos (41)',
            onAcao: () => toques++,
          ),
        ),
      );
      expect(find.text('Trabalhos feitos'), findsOneWidget);
      await tester.tap(find.text('Ver todos (41)'));
      expect(toques, 1);
    });

    testWidgets('ligação longa a 200 % não transborda', (tester) async {
      await tester.pumpWidget(
        montar(
          KSecaoTitulo(
            titulo: 'Trabalhos feitos',
            rotuloAcao: 'Ver todos (41)',
            onAcao: () {},
          ),
          escalaTexto: 2,
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('aceita um acessório e texto a 200 %', (tester) async {
      await tester.pumpWidget(
        montar(
          const KSecaoTitulo(titulo: 'Perto de si', acessorio: Text('Mapa')),
          escalaTexto: 2,
        ),
      );
      expect(find.text('Mapa'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
