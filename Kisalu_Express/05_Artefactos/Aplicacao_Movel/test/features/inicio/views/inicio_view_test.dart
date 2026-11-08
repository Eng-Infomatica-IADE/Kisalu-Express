import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kisalu_express/data/repositories/kisalu_repository.dart';
import 'package:kisalu_express/data/repositories/mock_kisalu_repository.dart';
import 'package:kisalu_express/features/inicio/views/inicio_view.dart';
import 'package:kisalu_express/models/categoria.dart';

import '../../../helpers/ecra_apoio.dart';

class _SemRede extends MockKisaluRepository {
  @override
  Future<List<Categoria>> categorias() => throw const SemRedeException();
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> abrir(
    WidgetTester t, {
    double escala = 1,
    KisaluRepository? repo,
  }) => montarEcra(
    t,
    const InicioView(),
    escala: escala,
    repo: repo,
    destinos: [
      '/novo-pedido',
      '/profissional/:id',
      '/categorias',
      '/mapa',
      '/notificacoes',
    ],
  );

  testWidgets('mostra os textos-chave do Figma', (t) async {
    await abrir(t);
    for (final s in [
      'Boa tarde, Maria',
      'Que serviço precisa hoje?',
      'CONFIRMAÇÃO POR QR',
      'Pague só quando o trabalho estiver feito.',
      'Serviços',
      'Ver todos',
      'Eletricista',
      'Canalizador',
      'Mecânico',
      'Pedreiro',
      'Ar\ncondicionado',
      'Cabeleireira',
      'Pintor',
      'Limpeza',
      'Perto de si',
      'Mapa',
    ]) {
      expect(find.text(s), findsOneWidget, reason: s);
    }
    expect(find.textContaining('Talatona, Luanda'), findsOneWidget);
    expect(find.bySemanticsLabel('Notificações, há novidades'), findsOneWidget);
    expect(find.textContaining('Joaquim Manuel'), findsOneWidget);
    expect(find.textContaining('Canalizador · 1,2 km'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('o ✕ esconde o banner', (t) async {
    await abrir(t);
    await t.tap(find.byTooltip('Fechar aviso'));
    await t.pumpAndSettle();
    expect(find.text('CONFIRMAÇÃO POR QR'), findsNothing);
  });

  testWidgets('categoria abre o novo pedido', (t) async {
    await abrir(t);
    await t.tap(find.text('Mecânico'));
    await t.pumpAndSettle();
    expect(find.text('DESTINO /novo-pedido'), findsOneWidget);
  });

  testWidgets('pesquisa abre o novo pedido', (t) async {
    await abrir(t);
    await t.tap(find.byType(TextField));
    await t.pumpAndSettle();
    expect(find.text('DESTINO /novo-pedido'), findsOneWidget);
  });

  testWidgets('cartão do profissional abre o perfil', (t) async {
    await abrir(t);
    await t.tap(find.text('Ver').first);
    await t.pumpAndSettle();
    expect(find.text('DESTINO /profissional/p1'), findsOneWidget);
  });

  testWidgets('"Ver todos" abre Todos os serviços (ecrã 21)', (t) async {
    await abrir(t);
    await t.tap(find.text('Ver todos'));
    await t.pumpAndSettle();
    expect(find.text('DESTINO /categorias'), findsOneWidget);
  });

  testWidgets('o chip "Mapa" abre o mapa (ecrã 22)', (t) async {
    await abrir(t);
    await t.ensureVisible(find.text('Mapa'));
    await t.tap(find.text('Mapa'));
    await t.pumpAndSettle();
    expect(find.text('DESTINO /mapa'), findsOneWidget);
  });

  testWidgets('o sino abre as notificações; o ponto segue as não lidas', (
    t,
  ) async {
    final repo = MockKisaluRepository();
    await abrir(t, repo: repo);
    await t.tap(find.bySemanticsLabel('Notificações, há novidades'));
    await t.pumpAndSettle();
    expect(find.text('DESTINO /notificacoes'), findsOneWidget);

    await repo.marcarNotificacoesLidas();
    await abrir(t, repo: repo);
    expect(find.bySemanticsLabel('Notificações, há novidades'), findsNothing);
    expect(find.bySemanticsLabel('Notificações'), findsOneWidget);
  });

  testWidgets('puxar para baixo volta a ler', (t) async {
    await abrir(t);
    await t.fling(find.text('Boa tarde, Maria'), const Offset(0, 400), 1000);
    await t.pumpAndSettle();
    expect(find.text('Boa tarde, Maria'), findsOneWidget);
  });

  testWidgets('estado de erro com nova tentativa', (t) async {
    await abrir(t, repo: _SemRede());
    expect(find.text('Não foi possível carregar'), findsOneWidget);
    expect(
      find.text('Sem ligação. Confirme a sua rede e tente outra vez.'),
      findsOneWidget,
    );
    expect(find.text('Tentar outra vez'), findsOneWidget);
  });

  testWidgets('sem overflow com texto a 200 %', (t) async {
    await abrir(t, escala: 2);
    expect(t.takeException(), isNull);
  });
}
