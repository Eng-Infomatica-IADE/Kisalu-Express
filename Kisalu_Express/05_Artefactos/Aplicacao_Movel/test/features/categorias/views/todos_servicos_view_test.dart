import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kisalu_express/data/repositories/kisalu_repository.dart';
import 'package:kisalu_express/data/repositories/mock_kisalu_repository.dart';
import 'package:kisalu_express/features/categorias/views/todos_servicos_view.dart';
import 'package:kisalu_express/models/categoria.dart';

import '../../../helpers/ecra_apoio.dart';

class _SemRede extends MockKisaluRepository {
  @override
  Future<List<Categoria>> categorias() => throw const SemRedeException();
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  const todas = [
    'Eletricista',
    'Canalizador',
    'Mecânico',
    'Pedreiro',
    'Ar condicionado',
    'Cabeleireira',
    'Pintor',
    'Limpeza',
    'Carpinteiro',
    'Jardinagem',
    'Informática',
    'Serralharia',
    'Transporte',
  ];

  Future<void> abrir(
    WidgetTester t, {
    double escala = 1,
    KisaluRepository? repo,
  }) => montarEcra(
    t,
    const TodosServicosView(),
    escala: escala,
    repo: repo,
    destinos: ['/novo-pedido'],
    comScaffold: false,
  );

  testWidgets('mostra o título, a pesquisa e as 13 categorias, por ordem', (
    t,
  ) async {
    await abrir(t);
    expect(find.text('Todos os serviços'), findsOneWidget);
    expect(find.text('Procurar um serviço'), findsOneWidget);
    for (final nome in todas) {
      // Na grelha cada palavra fica na sua linha.
      expect(
        find.text(nome.replaceAll(' ', '\n')),
        findsOneWidget,
        reason: nome,
      );
    }
    final fundo = t.getTopLeft(find.text('Transporte')).dy;
    expect(fundo, greaterThan(t.getTopLeft(find.text('Serralharia')).dy));
    expect(t.takeException(), isNull);
  });

  testWidgets('a grelha é um GridView.builder com 4 colunas', (t) async {
    await abrir(t);
    final grelha = t.widget<GridView>(find.byType(GridView));
    final delegate =
        grelha.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, 4);
    expect(grelha.childrenDelegate, isA<SliverChildBuilderDelegate>());
  });

  testWidgets('a pesquisa filtra ao escrever', (t) async {
    await abrir(t);
    await t.enterText(find.byType(TextField), 'mec');
    await t.pump();
    expect(find.text('Mecânico'), findsOneWidget);
    expect(find.text('Eletricista'), findsNothing);
    expect(find.text('Transporte'), findsNothing);
  });

  testWidgets('a pesquisa ignora acentos e maiúsculas', (t) async {
    await abrir(t);
    await t.enterText(find.byType(TextField), 'INFORMATICA');
    await t.pump();
    expect(find.text('Informática'), findsOneWidget);
    expect(find.text('Pintor'), findsNothing);
  });

  testWidgets('sem correspondência mostra "Sem resultados"', (t) async {
    await abrir(t);
    await t.enterText(find.byType(TextField), 'zzz');
    await t.pump();
    expect(find.text('Sem resultados'), findsOneWidget);
    expect(find.text('Eletricista'), findsNothing);
    await t.enterText(find.byType(TextField), '');
    await t.pump();
    expect(find.text('Eletricista'), findsOneWidget);
  });

  testWidgets('tocar numa categoria abre o novo pedido', (t) async {
    await abrir(t);
    await t.tap(find.text('Pintor'));
    await t.pumpAndSettle();
    expect(find.text('DESTINO /novo-pedido'), findsOneWidget);
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

  testWidgets('v3.1: "Descreva o que precisa" abre um novo pedido', (t) async {
    await abrir(t);
    await t.ensureVisible(find.text('Descreva o que precisa'));
    await t.pump();
    await t.tap(find.text('Descreva o que precisa'));
    await t.pumpAndSettle();
    expect(find.textContaining('DESTINO /novo-pedido'), findsOneWidget);
  });
}
