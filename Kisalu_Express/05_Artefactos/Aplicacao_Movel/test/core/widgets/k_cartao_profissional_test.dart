import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kisalu_express/core/theme/k_icons.dart';
import 'package:kisalu_express/core/widgets/widgets.dart';
import 'package:kisalu_express/data/mock/mock_profissionais.dart';

import '../../helpers/montar_widget.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('KCartaoProfissional', () {
    testWidgets('mostra nome, categoria, distância, avaliação e "Ver"', (
      tester,
    ) async {
      await tester.pumpWidget(
        montarWidget(
          KCartaoProfissional(
            profissional: MockProfissionais.joaquim,
            onAbrir: () {},
          ),
        ),
      );
      expect(find.text('JM'), findsOneWidget);
      expect(
        find.textContaining('Joaquim Manuel', findRichText: true),
        findsOneWidget,
      );
      expect(find.text('Canalizador · 1,2 km'), findsOneWidget);
      expect(find.textContaining('4,8', findRichText: true), findsOneWidget);
      expect(find.text('Ver'), findsOneWidget);
    });

    testWidgets('o cartão inteiro abre o perfil', (tester) async {
      var toques = 0;
      await tester.pumpWidget(
        montarWidget(
          KCartaoProfissional(
            profissional: MockProfissionais.ana,
            onAbrir: () => toques++,
          ),
        ),
      );
      await tester.tap(find.textContaining('Ana Cardoso', findRichText: true));
      expect(toques, 1);
    });

    testWidgets('o selo Verificado só aparece nos verificados', (tester) async {
      await tester.pumpWidget(
        montarWidget(
          Column(
            children: [
              KCartaoProfissional(
                profissional: MockProfissionais.joaquim,
                onAbrir: () {},
              ),
              KCartaoProfissional(
                profissional: MockProfissionais.paulo,
                onAbrir: () {},
              ),
            ],
          ),
          rolavel: true,
        ),
      );
      expect(find.byIcon(KIcons.verificado), findsOneWidget);
    });

    testWidgets('encolhe à altura do conteúdo dentro de espaço livre', (
      tester,
    ) async {
      await tester.pumpWidget(
        montarWidget(
          SizedBox(
            height: 400,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: KCartaoProfissional(
                profissional: MockProfissionais.joaquim,
                onAbrir: () {},
              ),
            ),
          ),
        ),
      );
      expect(
        tester.getSize(find.byType(KCartaoProfissional)).height,
        lessThan(160),
      );
    });

    testWidgets('sem overflow com texto a 200 %', (tester) async {
      await tester.pumpWidget(
        montarWidget(
          KCartaoProfissional(
            profissional: MockProfissionais.joaquim,
            onAbrir: () {},
          ),
          escalaTexto: 2,
          rolavel: true,
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
