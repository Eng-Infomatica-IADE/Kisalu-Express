import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kisalu_express/core/theme/k_tokens.dart';
import 'package:kisalu_express/core/widgets/widgets.dart';

import '../../helpers/montar_widget.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Widget montar(Widget filho, {double escalaTexto = 1}) =>
      montarWidget(filho, escalaTexto: escalaTexto);

  group('KAvatar', () {
    test('iniciais', () {
      expect(KAvatar.iniciais('Joaquim Manuel'), 'JM');
      expect(KAvatar.iniciais('Maria S.'), 'MS');
      expect(KAvatar.iniciais('Ana'), 'A');
      expect(KAvatar.iniciais('élio  costa'), 'ÉC');
    });

    testWidgets('círculo tom claro do tamanho pedido, sem semântica', (
      tester,
    ) async {
      await tester.pumpWidget(
        montar(
          const Align(
            alignment: Alignment.topLeft,
            child: KAvatar(nome: 'Joaquim Manuel', tamanho: K.avatarGrande),
          ),
        ),
      );
      expect(find.text('JM'), findsOneWidget);
      expect(tester.getSize(find.byType(KAvatar)), const Size(88, 88));
      expect(find.bySemanticsLabel('JM'), findsNothing);
    });
  });
}
