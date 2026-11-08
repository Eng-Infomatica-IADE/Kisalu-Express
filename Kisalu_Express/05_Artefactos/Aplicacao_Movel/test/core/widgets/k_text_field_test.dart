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

  /// Cor da borda atual do TextField (enabled).
  Color corDaBorda(WidgetTester tester) {
    final decoracao = tester
        .widget<TextField>(find.byType(TextField))
        .decoration!;
    return (decoracao.enabledBorder! as OutlineInputBorder).borderSide.color;
  }

  group('KTextField', () {
    testWidgets('rótulo visível, ajuda, ícone e 52 dp', (tester) async {
      await tester.pumpWidget(
        montar(
          const KTextField(
            rotulo: 'Telemóvel',
            icone: KIcons.telefone,
            dica: '+244 9__ ___ ___',
            ajuda: 'Enviamos um código por SMS.',
          ),
        ),
      );
      expect(find.text('Telemóvel'), findsOneWidget);
      expect(find.text('Enviamos um código por SMS.'), findsOneWidget);
      expect(find.byIcon(KIcons.telefone), findsOneWidget);
      expect(corDaBorda(tester), KColors.areia400);
      expect(
        tester.getSize(find.byType(TextField)).height,
        greaterThanOrEqualTo(52),
      );
    });

    testWidgets('foco: borda laranja; ao sair chama onSaiu', (tester) async {
      var saidas = 0;
      await tester.pumpWidget(
        montar(
          Column(
            children: [
              KTextField(rotulo: 'Telemóvel', onSaiu: () => saidas++),
              const KTextField(rotulo: 'Outro'),
            ],
          ),
        ),
      );
      await tester.tap(find.byType(TextField).first);
      await tester.pump();
      expect(
        (tester
                    .widget<TextField>(find.byType(TextField).first)
                    .decoration!
                    .enabledBorder!
                as OutlineInputBorder)
            .borderSide
            .color,
        KColors.laranja,
      );
      expect(saidas, 0);
      await tester.tap(find.byType(TextField).last);
      await tester.pump();
      expect(saidas, 1);
    });

    testWidgets('erro: borda e mensagem com ícone na cor de erro', (
      tester,
    ) async {
      await tester.pumpWidget(
        montar(
          const KTextField(
            rotulo: 'Telemóvel',
            erro: 'Faltam 3 números. Um número angolano tem 9 dígitos.',
            ajuda: 'Enviamos um código por SMS.',
          ),
        ),
      );
      expect(corDaBorda(tester), KColors.erro);
      expect(find.byIcon(KIcons.aviso), findsOneWidget);
      // O erro substitui a ajuda.
      expect(find.text('Enviamos um código por SMS.'), findsNothing);
      final mensagem = tester.widget<Text>(
        find.text('Faltam 3 números. Um número angolano tem 9 dígitos.'),
      );
      expect(mensagem.style!.color, KColors.erro);
    });

    testWidgets('sucesso: borda verde e ícone de concluído', (tester) async {
      await tester.pumpWidget(
        montar(
          const KTextField(rotulo: 'Código SMS', sucesso: 'Número confirmado.'),
        ),
      );
      expect(corDaBorda(tester), KColors.sucesso);
      expect(find.byIcon(KIcons.concluido), findsOneWidget);
    });

    testWidgets('desativado: fundo areia e não editável', (tester) async {
      await tester.pumpWidget(
        montar(const KTextField(rotulo: 'Morada', ativo: false)),
      );
      final campo = tester.widget<TextField>(find.byType(TextField));
      expect(campo.enabled, isFalse);
      expect(campo.decoration!.fillColor, KColors.areia100);
    });

    testWidgets('área de texto com contador que acompanha o texto', (
      tester,
    ) async {
      await tester.pumpWidget(
        montar(
          const KTextField(
            rotulo: 'Descreva o problema',
            linhas: 3,
            maxCaracteres: 300,
          ),
        ),
      );
      expect(find.text('0 / 300'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Cano a pingar');
      await tester.pump();
      expect(find.text('13 / 300'), findsOneWidget);
    });

    testWidgets('o rótulo faz parte do nome acessível do campo', (
      tester,
    ) async {
      await tester.pumpWidget(montar(const KTextField(rotulo: 'Telemóvel')));
      expect(find.bySemanticsLabel(RegExp('Telemóvel')), findsOneWidget);
    });

    testWidgets('texto a 200 % sem overflow', (tester) async {
      await tester.pumpWidget(
        montar(
          const KTextField(
            rotulo: 'Ponto de referência',
            icone: KIcons.localizacao,
            ajuda: 'Ajuda o profissional a encontrar a sua casa.',
            maxCaracteres: 120,
          ),
          escalaTexto: 2,
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('rótulo oculto mantém o nome acessível e o limite', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      montarWidget(
        KTextField(
          rotulo: 'Comentário (opcional)',
          rotuloVisivel: false,
          controller: controller,
          linhas: 3,
          maxCaracteres: 5,
          mostrarContador: false,
        ),
      ),
    );
    expect(find.text('Comentário (opcional)'), findsNothing);
    expect(find.text('0 / 5'), findsNothing);
    expect(find.bySemanticsLabel(RegExp('Comentário')), findsWidgets);
    await tester.enterText(find.byType(TextField), '123456789');
    expect(controller.text, '12345');
    handle.dispose();
  });
}
