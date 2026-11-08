import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kisalu_express/data/repositories/kisalu_repository.dart';
import 'package:kisalu_express/data/repositories/mock_kisalu_repository.dart';
import 'package:kisalu_express/features/inicio_profissional/views/inicio_profissional_view.dart';
import 'package:kisalu_express/models/painel_profissional.dart';

import '../../../helpers/ecra_apoio.dart';

class _SemRede extends MockKisaluRepository {
  @override
  Future<PainelProfissional> painelProfissional() =>
      throw const SemRedeException();
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> abrir(
    WidgetTester t, {
    double escala = 1,
    KisaluRepository? repo,
  }) => montarEcra(
    t,
    const InicioProfissionalView(),
    escala: escala,
    repo: repo,
    destinos: ['/enviar-proposta/:pedidoId'],
  );

  testWidgets('mostra os textos-chave do Figma', (t) async {
    await abrir(t);
    for (final s in [
      'Boa tarde, Joaquim',
      'Disponível para trabalhar',
      'Está a receber pedidos da sua zona.',
      '3',
      'Pedidos novos',
      '4,8',
      'Avaliação',
      '126',
      'Serviços',
      'Pedidos perto de si',
      'Ver todos',
      'Fuga de água na cozinha',
      'Talatona · 3,4 km · Hoje, 16:00',
      'NOVO',
      'Reparar muro do quintal',
      'Viana · 1,8 km · Amanhã, 9:00',
      'há 22 min',
    ]) {
      expect(find.text(s), findsOneWidget, reason: s);
    }
    expect(find.textContaining('Viana · até 10 km'), findsOneWidget);
    expect(find.text('Ver pedido'), findsNWidgets(2));
    expect(t.takeException(), isNull);
  });

  testWidgets('os pedidos não mostram morada nem contacto (RNF10)', (t) async {
    await abrir(t);
    expect(find.textContaining('+244'), findsNothing);
    expect(find.textContaining('Rua'), findsNothing);
    expect(find.textContaining('Maria'), findsNothing);
  });

  testWidgets('o interruptor de disponibilidade muda a mensagem', (t) async {
    await abrir(t);
    await t.tap(find.byType(Switch));
    await t.pumpAndSettle();
    expect(find.text('Não está a receber pedidos.'), findsOneWidget);
    expect(find.text('Está a receber pedidos da sua zona.'), findsNothing);
    await t.tap(find.byType(Switch));
    await t.pumpAndSettle();
    expect(find.text('Está a receber pedidos da sua zona.'), findsOneWidget);
  });

  testWidgets('"Ver pedido" abre o ecrã de enviar proposta', (t) async {
    await abrir(t);
    await t.tap(find.text('Ver pedido').first);
    await t.pumpAndSettle();
    expect(find.text('DESTINO /enviar-proposta/pp1'), findsOneWidget);
  });

  testWidgets('o segundo pedido leva ao seu id', (t) async {
    await abrir(t);
    await t.tap(find.text('Ver pedido').last);
    await t.pumpAndSettle();
    expect(find.text('DESTINO /enviar-proposta/pp2'), findsOneWidget);
  });

  testWidgets('"Ver todos" ainda não tem destino: mostra "Em breve"', (
    t,
  ) async {
    await abrir(t);
    await t.tap(find.text('Ver todos'));
    await t.pump();
    expect(find.text('Em breve'), findsOneWidget);
  });

  testWidgets('falha ao carregar mostra o estado de erro', (t) async {
    await abrir(t, repo: _SemRede());
    expect(find.text('Não foi possível carregar'), findsOneWidget);
    expect(find.text('Tentar outra vez'), findsOneWidget);
  });

  testWidgets('sem overflow com texto a 200 %', (t) async {
    await abrir(t, escala: 2);
    expect(t.takeException(), isNull);
  });

  testWidgets('v3.1: sino com novidades e tempo junto ao NOVO', (t) async {
    await abrir(t);
    expect(find.bySemanticsLabel(RegExp('Notificações')), findsOneWidget);
    expect(find.textContaining('há '), findsWidgets);
  });
}
