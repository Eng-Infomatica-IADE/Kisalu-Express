import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kisalu_express/core/theme/k_colors.dart';
import 'package:kisalu_express/core/widgets/widgets.dart';

import '../../helpers/montar_widget.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Widget montar(Widget filho, {double escalaTexto = 1}) =>
      montarWidget(filho, escalaTexto: escalaTexto);

  /// Cor de fundo do AnimatedContainer do botão.
  Color? fundo(WidgetTester tester) {
    final container = tester.widget<AnimatedContainer>(
      find.byType(AnimatedContainer),
    );
    return (container.decoration as BoxDecoration?)?.color;
  }

  Color corDoTexto(WidgetTester tester, String rotulo) =>
      tester.widget<Text>(find.text(rotulo)).style!.color!;

  group('KPrimaryButton', () {
    testWidgets('normal: laranja, 52 dp, largura total, chama onPressed', (
      tester,
    ) async {
      var toques = 0;
      await tester.pumpWidget(
        montar(
          KPrimaryButton(rotulo: 'Pedir serviço', onPressed: () => toques++),
        ),
      );
      expect(fundo(tester), KColors.laranja);
      expect(corDoTexto(tester, 'Pedir serviço'), KColors.branco);
      final tamanho = tester.getSize(find.byType(AnimatedContainer));
      expect(tamanho.height, greaterThanOrEqualTo(52));
      expect(tamanho.width, 328);
      await tester.tap(find.text('Pedir serviço'));
      expect(toques, 1);
    });

    testWidgets('premido fica Brasa', (tester) async {
      await tester.pumpWidget(
        montar(KPrimaryButton(rotulo: 'Pedir serviço', onPressed: () {})),
      );
      final gesto = await tester.startGesture(
        tester.getCenter(find.text('Pedir serviço')),
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(fundo(tester), KColors.brasa);
      await gesto.up();
      await tester.pump(const Duration(milliseconds: 200));
      expect(fundo(tester), KColors.laranja);
    });

    testWidgets('desativado: areia e não reage', (tester) async {
      await tester.pumpWidget(
        montar(
          const KPrimaryButton(rotulo: 'A aguardar rede…', onPressed: null),
        ),
      );
      expect(fundo(tester), KColors.areia200);
      expect(corDoTexto(tester, 'A aguardar rede…'), KColors.neutro500);
      final semantica = tester.getSemantics(find.byType(KPrimaryButton));
      expect(semantica.flagsCollection.isEnabled, Tristate.isFalse);
    });

    testWidgets('a carregar: mostra spinner, não reage e anuncia', (
      tester,
    ) async {
      var toques = 0;
      await tester.pumpWidget(
        montar(
          KPrimaryButton(
            rotulo: 'Pedir serviço',
            aCarregar: true,
            onPressed: () => toques++,
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Pedir serviço'), findsNothing);
      await tester.tap(find.byType(KPrimaryButton));
      expect(toques, 0);
      expect(
        find.bySemanticsLabel('Pedir serviço, a carregar'),
        findsOneWidget,
      );
    });

    testWidgets('destrutivo usa a cor de erro', (tester) async {
      await tester.pumpWidget(
        montar(
          KPrimaryButton(
            rotulo: 'Cancelar pedido',
            destrutivo: true,
            onPressed: () {},
          ),
        ),
      );
      expect(fundo(tester), KColors.erro);
    });

    testWidgets('foco por teclado mostra anel e Enter ativa', (tester) async {
      var toques = 0;
      await tester.pumpWidget(
        montar(
          KPrimaryButton(rotulo: 'Pedir serviço', onPressed: () => toques++),
        ),
      );
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(find.byType(Positioned), findsOneWidget); // anel de foco
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(toques, 1);
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic;
    });

    testWidgets('texto a 200 % quebra linha sem overflow', (tester) async {
      await tester.pumpWidget(
        montar(
          KPrimaryButton(rotulo: 'Confirmar proposta agora', onPressed: () {}),
          escalaTexto: 2,
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
