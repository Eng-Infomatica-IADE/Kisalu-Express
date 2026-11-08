import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kisalu_express/data/repositories/kisalu_repository.dart';
import 'package:kisalu_express/data/repositories/mock_kisalu_repository.dart';
import 'package:kisalu_express/features/confirmacao_profissional/views/ler_qr_view.dart';

import '../../../helpers/ecra_apoio.dart';

class _SemRede extends MockKisaluRepository {
  @override
  Future<String?> codigoClientePredefinido() => throw const SemRedeException();
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> abrir(
    WidgetTester t, {
    double escala = 1,
    KisaluRepository? repo,
  }) => montarEcra(
    t,
    const LerQrView(),
    escala: escala,
    repo: repo,
    destinos: ['/inicio', '/servico-confirmado/:pedidoId'],
  );

  testWidgets('mostra os textos-chave do Figma', (t) async {
    await abrir(t);
    for (final s in [
      'Peça ao cliente o código de 6 dígitos que aparece no ecrã dele.',
      'Código de confirmação',
      'Código do cliente',
      '482 173',
    ]) {
      expect(find.text(s), findsOneWidget, reason: s);
    }
    expect(find.text('Confirmar serviço'), findsNWidgets(2)); // título e botão
    expect(t.takeException(), isNull);
  });

  testWidgets('o visor é só desenho, sem câmara: tem nome acessível', (
    t,
  ) async {
    await abrir(t);
    expect(find.bySemanticsLabel(RegExp('^Visor da câmara')), findsOneWidget);
  });

  testWidgets('qualquer código válido confirma e abre o ecrã 17', (t) async {
    await abrir(t);
    await t.tap(find.widgetWithText(GestureDetector, 'Confirmar serviço'));
    await t.pumpAndSettle();
    expect(find.text('DESTINO /servico-confirmado/tp1'), findsOneWidget);
  });

  testWidgets('código escrito à mão com espaços também confirma', (t) async {
    await abrir(t);
    await t.enterText(find.byType(TextField), '123 456');
    await t.tap(find.widgetWithText(GestureDetector, 'Confirmar serviço'));
    await t.pumpAndSettle();
    expect(find.text('DESTINO /servico-confirmado/tp1'), findsOneWidget);
  });

  testWidgets('000000 mostra a mensagem e fica no ecrã', (t) async {
    await abrir(t);
    await t.enterText(find.byType(TextField), '000000');
    await t.tap(find.widgetWithText(GestureDetector, 'Confirmar serviço'));
    await t.pumpAndSettle();
    expect(
      find.text('O código não está certo. Confirme com o cliente.'),
      findsOneWidget,
    );
    expect(find.textContaining('DESTINO'), findsNothing);
  });

  testWidgets('formato inválido mostra a mensagem que ensina', (t) async {
    await abrir(t);
    await t.enterText(find.byType(TextField), '482');
    await t.tap(find.widgetWithText(GestureDetector, 'Confirmar serviço'));
    await t.pumpAndSettle();
    expect(
      find.text('Faltam 3 números. O código tem 6 dígitos.'),
      findsOneWidget,
    );
    await t.enterText(find.byType(TextField), '');
    await t.pump();
    expect(find.textContaining('Faltam'), findsNothing);
    await t.tap(find.widgetWithText(GestureDetector, 'Confirmar serviço'));
    await t.pumpAndSettle();
    expect(
      find.text('Escreva o código que o cliente lhe disse.'),
      findsOneWidget,
    );
  });

  testWidgets('o botão de voltar vai para o Início', (t) async {
    await abrir(t);
    await t.tap(find.bySemanticsLabel('Voltar'));
    await t.pumpAndSettle();
    expect(find.text('DESTINO /inicio'), findsOneWidget);
  });

  testWidgets('falha ao carregar mostra o estado de erro', (t) async {
    await abrir(t, repo: _SemRede());
    expect(find.text('Não foi possível carregar'), findsOneWidget);
  });

  testWidgets('sem overflow com texto a 200 %', (t) async {
    await abrir(t, escala: 2);
    expect(t.takeException(), isNull);
  });

  testWidgets('v3.1: mostra o serviço, o cliente e o valor', (t) async {
    await abrir(t);
    expect(
      find.text('Fuga de água na cozinha · Maria K. · 12.500 Kz'),
      findsOneWidget,
    );
  });
}
