import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kisalu_express/core/theme/k_colors.dart';
import 'package:kisalu_express/core/theme/k_icons.dart';
import 'package:kisalu_express/core/widgets/widgets.dart';

import '../../helpers/montar_widget.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Widget montar(Widget filho, {double escalaTexto = 1}) =>
      montarWidget(filho, escalaTexto: escalaTexto, comMargem: false);

  group('KIconButton', () {
    testWidgets('alvo de 48 dp, nome acessível e toque', (tester) async {
      var toques = 0;
      await tester.pumpWidget(
        montar(
          Align(
            alignment: Alignment.topLeft,
            child: KIconButton(
              icone: KIcons.mais,
              rotulo: 'Mais opções',
              onPressed: () => toques++,
            ),
          ),
        ),
      );
      expect(tester.getSize(find.byType(KIconButton)), const Size(48, 48));
      expect(find.bySemanticsLabel('Mais opções'), findsOneWidget);
      await tester.tap(find.byType(KIconButton));
      expect(toques, 1);
    });

    testWidgets('ponto de novidades é anunciado', (tester) async {
      await tester.pumpWidget(
        montar(
          Align(
            alignment: Alignment.topLeft,
            child: KIconButton(
              icone: KIcons.notificacoes,
              rotulo: 'Notificações',
              mostrarPonto: true,
              onPressed: () {},
            ),
          ),
        ),
      );
      expect(
        find.bySemanticsLabel('Notificações, há novidades'),
        findsOneWidget,
      );
    });

    testWidgets('desativado mantém o alvo e não chama a ação', (tester) async {
      await tester.pumpWidget(
        montar(
          const KIconButton(
            icone: KIcons.mais,
            rotulo: 'Mais opções',
            onPressed: null,
          ),
        ),
      );
      expect(tester.getSize(find.byType(KIconButton)).height, 48);
      expect(
        tester.widget<Icon>(find.byIcon(KIcons.mais)).color,
        KColors.neutro500,
      );
      expect(
        tester
            .getSemantics(find.bySemanticsLabel('Mais opções'))
            .flagsCollection
            .isEnabled,
        Tristate.isFalse,
      );
    });
  });

  testWidgets('escuro: quadrado Ébano com ícone branco', (tester) async {
    await tester.pumpWidget(
      montarWidget(
        KIconButton(
          icone: KIcons.voltar,
          rotulo: 'Voltar',
          onPressed: () {},
          escuro: true,
        ),
      ),
    );
    final icone = tester.widget<Icon>(find.byIcon(KIcons.voltar));
    expect(icone.color, KColors.branco);
    final material = tester
        .widgetList<Material>(find.byType(Material))
        .firstWhere((m) => m.color == KColors.ebano);
    expect(material.color, KColors.ebano);
  });
}
