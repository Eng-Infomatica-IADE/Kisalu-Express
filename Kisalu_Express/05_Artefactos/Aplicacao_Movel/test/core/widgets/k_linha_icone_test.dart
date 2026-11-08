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

  testWidgets('KLinhaIcone mostra o texto e quebra a 200 %', (tester) async {
    await tester.pumpWidget(
      montar(
        const KLinhaIcone(
          icone: KIcons.localizacao,
          texto: 'Talatona · perto da cantina do Sr. Zé',
        ),
        escalaTexto: 2,
      ),
    );
    expect(find.text('Talatona · perto da cantina do Sr. Zé'), findsOneWidget);
    expect(find.byIcon(KIcons.localizacao), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
