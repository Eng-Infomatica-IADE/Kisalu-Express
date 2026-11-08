import 'dart:ui' show Tristate;

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

  BoxDecoration decoracao(WidgetTester tester, String rotulo) =>
      tester
              .widget<AnimatedContainer>(
                find.ancestor(
                  of: find.text(rotulo),
                  matching: find.byType(AnimatedContainer),
                ),
              )
              .decoration!
          as BoxDecoration;

  group('KChip', () {
    testWidgets('filtro: normal com contorno, selecionado Ébano', (
      tester,
    ) async {
      await tester.pumpWidget(
        montar(
          Wrap(
            children: [
              KChip(rotulo: 'Todos', selecionado: true, onSelecionar: (_) {}),
              KChip(rotulo: 'Em curso', onSelecionar: (_) {}),
            ],
          ),
        ),
      );
      expect(decoracao(tester, 'Todos').color, KColors.ebano);
      expect(decoracao(tester, 'Todos').border, isNull);
      expect(decoracao(tester, 'Em curso').color, KColors.branco);
      expect(
        (decoracao(tester, 'Em curso').border! as Border).top.color,
        KColors.areia400,
      );
    });

    testWidgets('etiqueta selecionada fica laranja', (tester) async {
      await tester.pumpWidget(
        montar(
          KChip(
            rotulo: 'Pontual',
            variante: KChipVariante.etiqueta,
            selecionado: true,
            onSelecionar: (_) {},
          ),
        ),
      );
      expect(decoracao(tester, 'Pontual').color, KColors.laranja);
    });

    testWidgets('tocar devolve o novo estado e o alvo tem 48 dp', (
      tester,
    ) async {
      final estados = <bool>[];
      await tester.pumpWidget(
        montar(
          Align(
            alignment: Alignment.topLeft,
            child: KChip(rotulo: 'Rápido', onSelecionar: estados.add),
          ),
        ),
      );
      expect(tester.getSize(find.byType(KChip)).height, 48);
      await tester.tap(find.text('Rápido'));
      expect(estados, [true]);
    });

    testWidgets('anuncia estado selecionado ao leitor de ecrã', (tester) async {
      await tester.pumpWidget(
        montar(KChip(rotulo: 'Todos', selecionado: true, onSelecionar: (_) {})),
      );
      expect(
        tester.getSemantics(find.byType(KChip)).flagsCollection.isSelected,
        Tristate.isTrue,
      );
    });

    testWidgets('desativado: areia, sem contorno, não reage', (tester) async {
      await tester.pumpWidget(montar(const KChip(rotulo: 'Cancelados')));
      expect(decoracao(tester, 'Cancelados').color, KColors.areia100);
      expect(
        tester.widget<Text>(find.text('Cancelados')).style!.color,
        KColors.neutro500,
      );
    });

    testWidgets('informativo não é botão', (tester) async {
      await tester.pumpWidget(
        montar(
          const KChip(
            rotulo: 'Fugas de água',
            variante: KChipVariante.informativo,
          ),
        ),
      );
      expect(decoracao(tester, 'Fugas de água').color, KColors.branco);
      expect(find.byType(GestureDetector), findsNothing);
    });

    testWidgets('texto a 200 % sem overflow', (tester) async {
      await tester.pumpWidget(
        montar(
          Wrap(
            children: [
              KChip(rotulo: 'Trabalho limpo', onSelecionar: (_) {}),
              KChip(rotulo: 'Preço justo', onSelecionar: (_) {}),
            ],
          ),
          escalaTexto: 2,
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
