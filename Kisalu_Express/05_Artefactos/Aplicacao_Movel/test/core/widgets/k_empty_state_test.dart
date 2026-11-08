import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kisalu_express/core/theme/k_icons.dart';
import 'package:kisalu_express/core/widgets/widgets.dart';

import '../../helpers/montar_widget.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Widget montar(Widget filho, {double escalaTexto = 1}) =>
      montarWidget(filho, escalaTexto: escalaTexto, rolavel: true);

  group('KEmptyState', () {
    testWidgets('círculo com ícone, título, mensagem e ação', (tester) async {
      var toques = 0;
      await tester.pumpWidget(
        montar(
          KEmptyState(
            icone: KIcons.codigoQr,
            titulo: 'Ainda não tem serviços para confirmar',
            mensagem: 'Quando aceitar uma proposta, o código QR aparece aqui.',
            rotuloAcao: 'Ver os meus pedidos',
            onAcao: () => toques++,
          ),
        ),
      );
      expect(find.byIcon(KIcons.codigoQr), findsOneWidget);
      expect(
        find.text('Ainda não tem serviços para confirmar'),
        findsOneWidget,
      );
      await tester.tap(find.text('Ver os meus pedidos'));
      expect(toques, 1);
    });

    testWidgets('texto a 200 % sem overflow', (tester) async {
      await tester.pumpWidget(
        montar(
          const KEmptyState(
            icone: KIcons.codigoQr,
            titulo: 'Ainda não tem serviços para confirmar',
            mensagem: 'Quando aceitar uma proposta, o código QR aparece aqui.',
            rotuloAcao: 'Ver os meus pedidos',
          ),
          escalaTexto: 2,
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
