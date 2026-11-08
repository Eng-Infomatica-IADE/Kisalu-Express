import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kisalu_express/core/theme/k_colors.dart';
import 'package:kisalu_express/core/theme/k_icons.dart';
import 'package:kisalu_express/core/widgets/widgets.dart';

import '../../helpers/montar_widget.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('KMensagemErro', () {
    testWidgets('mostra ícone de aviso e o texto a vermelho', (tester) async {
      await tester.pumpWidget(
        montarWidget(const KMensagemErro('Escolha pelo menos um serviço.')),
      );
      expect(find.text('Escolha pelo menos um serviço.'), findsOneWidget);
      expect(
        tester.widget<Icon>(find.byIcon(KIcons.aviso)).color,
        KColors.erro,
      );
      expect(
        tester
            .widget<Text>(find.text('Escolha pelo menos um serviço.'))
            .style!
            .color,
        KColors.erro,
      );
    });

    testWidgets('é anunciada pelo leitor de ecrã (região viva)', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      await tester.pumpWidget(
        montarWidget(const KMensagemErro('Faltam 3 números.')),
      );
      expect(
        tester.getSemantics(find.text('Faltam 3 números.')),
        matchesSemantics(label: 'Faltam 3 números.', isLiveRegion: true),
      );
      semantica.dispose();
    });

    testWidgets('quebra linha com texto a 200 % e sem overflow', (
      tester,
    ) async {
      await tester.pumpWidget(
        montarWidget(
          const KMensagemErro(
            'Escreva o valor de mão de obra. Se não cobra, escreva 0.',
          ),
          escalaTexto: 2,
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
