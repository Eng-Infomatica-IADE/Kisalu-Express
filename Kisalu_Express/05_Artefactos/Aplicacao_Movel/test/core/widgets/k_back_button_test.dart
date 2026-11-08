import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kisalu_express/core/widgets/widgets.dart';

import '../../helpers/montar_widget.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Widget montar(Widget filho, {double escalaTexto = 1}) =>
      montarWidget(filho, escalaTexto: escalaTexto, comMargem: false);

  group('KBackButton', () {
    testWidgets('usa o rótulo Voltar e chama a ação fornecida', (tester) async {
      var toques = 0;
      await tester.pumpWidget(montar(KBackButton(onPressed: () => toques++)));
      await tester.tap(find.bySemanticsLabel('Voltar'));
      expect(toques, 1);
    });
  });
}
