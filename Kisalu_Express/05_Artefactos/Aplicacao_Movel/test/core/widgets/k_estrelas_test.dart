import 'dart:ui' show SemanticsAction;

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
      montarWidget(filho, escalaTexto: escalaTexto, rolavel: true);

  group('KEstrelas', () {
    testWidgets('só leitura: valor na semântica e sem gestos', (tester) async {
      await tester.pumpWidget(montar(const KEstrelas(valor: 5)));
      expect(find.byIcon(KIcons.estrela), findsNWidgets(5));
      expect(
        tester.getSemantics(find.byType(KEstrelas)).value,
        '5 de 5 estrelas',
      );
      expect(find.byType(GestureDetector), findsNothing);
    });

    testWidgets('cores: preenchidas ouro, resto areia300', (tester) async {
      await tester.pumpWidget(montar(const KEstrelas(valor: 4)));
      final icones = tester.widgetList<Icon>(find.byIcon(KIcons.estrela));
      expect(icones.map((i) => i.color), [
        KColors.ouro,
        KColors.ouro,
        KColors.ouro,
        KColors.ouro,
        KColors.areia300,
      ]);
    });

    testWidgets('interativa: alvos de 48 dp e devolve a nota', (tester) async {
      final notas = <int>[];
      await tester.pumpWidget(
        montar(KEstrelas(valor: 4, onAlterar: notas.add)),
      );
      final primeira = find.byType(GestureDetector).first;
      expect(tester.getSize(primeira), const Size(48, 48));
      await tester.tap(find.byType(GestureDetector).at(1));
      expect(notas, [2]);
      expect(
        tester.getSemantics(find.byType(KEstrelas)).value,
        '4 de 5 estrelas',
      );
    });

    testWidgets('interativa: aumentar e diminuir por semântica', (
      tester,
    ) async {
      final notas = <int>[];
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        montar(KEstrelas(valor: 3, onAlterar: notas.add)),
      );
      tester.semantics.performAction(
        find.semantics.byLabel('Avaliação'),
        SemanticsAction.increase,
      );
      tester.semantics.performAction(
        find.semantics.byLabel('Avaliação'),
        SemanticsAction.decrease,
      );
      expect(notas, [4, 2]);
      handle.dispose();
    });
  });
}
