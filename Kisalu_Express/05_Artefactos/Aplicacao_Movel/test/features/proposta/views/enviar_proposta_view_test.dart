import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kisalu_express/data/repositories/kisalu_repository.dart';
import 'package:kisalu_express/data/repositories/mock_kisalu_repository.dart';
import 'package:kisalu_express/features/proposta/views/enviar_proposta_view.dart';
import 'package:kisalu_express/models/nova_proposta.dart';

import '../../../helpers/ecra_apoio.dart';

class _SemRede extends MockKisaluRepository {
  @override
  Future<void> enviarProposta(NovaProposta proposta) =>
      throw const SemRedeException();
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> abrir(
    WidgetTester t, {
    double escala = 1,
    KisaluRepository? repo,
    String id = 'pp1',
  }) => montarEcra(
    t,
    EnviarPropostaView(pedidoId: id),
    escala: escala,
    repo: repo,
    destinos: ['/inicio'],
    comScaffold: false,
  );

  testWidgets('mostra os textos-chave do Figma', (t) async {
    await abrir(t);
    for (final s in [
      'Enviar proposta',
      'Fuga de água na cozinha',
      'Cano a pingar debaixo do lava-loiça. Precisa de reparação hoje.',
      'Talatona · 3,4 km',
      'O que inclui o preço?',
      'Mão de obra',
      'Material',
      'Deslocação',
      'Quando pode chegar?',
      '40 min',
      '1 h',
      '2 h',
      'Hoje, 16:00',
      'Valor fechado',
      '12.500 Kz',
    ]) {
      expect(find.text(s), findsWidgets, reason: s);
    }
    expect(find.text('Enviar proposta'), findsNWidgets(2)); // título e botão
    expect(find.text('8.000'), findsOneWidget);
    expect(find.text('3.500'), findsOneWidget);
    expect(find.text('1.000'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('o pedido só mostra zona e distância, sem morada nem contacto', (
    t,
  ) async {
    await abrir(t);
    expect(find.textContaining('+244'), findsNothing);
    expect(find.textContaining('Maria'), findsNothing);
    expect(find.textContaining('Rua'), findsNothing);
  });

  testWidgets('editar um componente recalcula o valor fechado', (t) async {
    await abrir(t);
    await t.enterText(find.widgetWithText(TextField, '3.500'), '5000');
    await t.pump();
    expect(find.text('14.000 Kz'), findsOneWidget);
    await t.enterText(find.widgetWithText(TextField, '1.000'), '0');
    await t.pump();
    expect(find.text('13.000 Kz'), findsOneWidget);
  });

  testWidgets('o campo só aceita dígitos, pontos e espaços', (t) async {
    await abrir(t);
    final campo = find.byType(TextField).first;
    await t.enterText(campo, '9a0b00');
    expect(t.widget<TextField>(campo).controller!.text, '9000');
  });

  testWidgets('campo vazio mostra o erro que ensina ao enviar', (t) async {
    await abrir(t);
    await t.enterText(find.widgetWithText(TextField, '8.000'), '');
    await t.tap(find.widgetWithText(GestureDetector, 'Enviar proposta').last);
    await t.pumpAndSettle();
    expect(
      find.text('Escreva o valor de mão de obra. Se não cobra, escreva 0.'),
      findsOneWidget,
    );
    expect(find.text('DESTINO /inicio'), findsNothing);
  });

  testWidgets('valor total abaixo do mínimo mostra o aviso', (t) async {
    await abrir(t);
    await t.enterText(find.widgetWithText(TextField, '8.000'), '100');
    await t.enterText(find.widgetWithText(TextField, '3.500'), '0');
    await t.enterText(find.widgetWithText(TextField, '1.000'), '0');
    await t.pump();
    await t.tap(find.widgetWithText(GestureDetector, 'Enviar proposta').last);
    await t.pumpAndSettle();
    expect(find.textContaining('O valor mínimo é 500 Kz.'), findsOneWidget);
  });

  testWidgets('escolher uma chegada diferente', (t) async {
    final repo = MockKisaluRepository();
    await abrir(t, repo: repo);
    await t.tap(find.text('2 h'));
    await t.pumpAndSettle();
    await t.tap(find.widgetWithText(GestureDetector, 'Enviar proposta').last);
    await t.pumpAndSettle();
    expect(repo.propostasEnviadas.single.chegada, ChegadaProposta.duasHoras);
  });

  testWidgets('enviar volta ao Início com a confirmação', (t) async {
    final repo = MockKisaluRepository();
    await abrir(t, repo: repo);
    await t.tap(find.widgetWithText(GestureDetector, 'Enviar proposta').last);
    await t.pumpAndSettle();
    expect(find.text('DESTINO /inicio'), findsOneWidget);
    expect(
      find.text('Proposta enviada. O cliente já a pode ver.'),
      findsOneWidget,
    );
    expect(repo.propostasEnviadas.single.valorFechado, 12500);
  });

  testWidgets('falha de rede ao enviar fica no ecrã', (t) async {
    await abrir(t, repo: _SemRede());
    await t.tap(find.widgetWithText(GestureDetector, 'Enviar proposta').last);
    await t.pumpAndSettle();
    expect(find.textContaining('Não enviámos a proposta.'), findsOneWidget);
    expect(find.text('DESTINO /inicio'), findsNothing);
  });

  testWidgets('pedido desconhecido mostra "Não encontrado"', (t) async {
    await abrir(t, id: 'zzz');
    expect(find.text('Não encontrado'), findsOneWidget);
    expect(find.text('Ir para o início'), findsOneWidget);
  });

  testWidgets('sem overflow com texto a 200 %', (t) async {
    await abrir(t, escala: 2);
    expect(t.takeException(), isNull);
  });

  testWidgets('v3.1: avisa do compromisso e diz que a hora é a pedida', (
    t,
  ) async {
    await abrir(t);
    expect(
      find.text(
        'O cliente vê o total e o que inclui. Depois de aceite, o valor '
        'fechado não muda.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Hora pedida, '), findsOneWidget);
  });
}
