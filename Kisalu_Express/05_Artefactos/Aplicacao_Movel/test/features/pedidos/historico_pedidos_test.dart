import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kisalu_express/core/state/estado_ui.dart';
import 'package:kisalu_express/core/theme/k_theme.dart';
import 'package:kisalu_express/data/repositories/kisalu_repository.dart';
import 'package:kisalu_express/data/repositories/mock_kisalu_repository.dart';
import 'package:kisalu_express/features/pedidos/controllers/historico_pedidos_controller.dart';
import 'package:kisalu_express/features/pedidos/views/historico_pedidos_view.dart';
import 'package:kisalu_express/models/filtro_pedidos.dart';
import 'package:kisalu_express/models/pedido.dart';
import 'package:kisalu_express/models/utilizador.dart';
import 'package:provider/provider.dart';

class _RepoComFalha extends MockKisaluRepository {
  @override
  Future<List<Pedido>> historico() async => throw const SemRedeException();
}

Widget _app(KisaluRepository repo, {double escala = 1}) {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => const HistoricoPedidosView()),
      GoRoute(
        path: '/pedidos/:id',
        builder: (_, s) => Text('detalhe ${s.pathParameters['id']}'),
      ),
      GoRoute(
        path: '/novo-pedido',
        builder: (_, s) => Text('novo ${s.uri.query}'),
      ),
      GoRoute(
        path: '/pedidos/:id/avaliar',
        builder: (_, s) => Text('avaliar ${s.pathParameters['id']}'),
      ),
      GoRoute(
        path: '/trabalhos/:id',
        builder: (_, s) => Text('trabalho ${s.pathParameters['id']}'),
      ),
    ],
  );
  return Provider<KisaluRepository>.value(
    value: repo,
    child: MaterialApp.router(
      theme: KTheme.light(),
      routerConfig: router,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(escala)),
        child: child!,
      ),
    ),
  );
}

void _ecra(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('HistoricoPedidosController', () {
    test('carrega, filtra e só mostra ações no primeiro concluído', () async {
      final c = HistoricoPedidosController(MockKisaluRepository());
      expect(c.estado, isA<Carregar<List<Pedido>>>());
      await c.carregar();
      expect(c.estado, isA<Sucesso<List<Pedido>>>());
      expect(c.filtrados.length, 5);
      final ped2 = c.filtrados.firstWhere((p) => p.id == 'ped2');
      final ped3 = c.filtrados.firstWhere((p) => p.id == 'ped3');
      expect(c.mostraAcoes(ped2), isTrue);
      expect(c.mostraAcoes(ped3), isFalse);
      c.escolherFiltro(FiltroPedidos.cancelados);
      expect(c.filtrados.map((p) => p.id), ['ped4']);
    });

    test('falha de rede dá Erro com semRede', () async {
      final c = HistoricoPedidosController(_RepoComFalha());
      await c.carregar();
      final e = c.estado as Erro<List<Pedido>>;
      expect(e.semRede, isTrue);
    });

    test('comprovativo inexistente devolve null', () async {
      final c = HistoricoPedidosController(MockKisaluRepository());
      expect(await c.comprovativo('ped4'), isNull);
      expect((await c.comprovativo('ped2'))?.referencia, 'KX-301854');
    });
  });

  group('HistoricoPedidosView', () {
    testWidgets('renderiza os pedidos do Figma', (tester) async {
      _ecra(tester);
      await tester.pumpWidget(_app(MockKisaluRepository()));
      await tester.pumpAndSettle();

      expect(find.text('Os seus pedidos'), findsOneWidget);
      expect(find.text('Fuga de água'), findsOneWidget);
      expect(find.text('Joaquim M. · Hoje'), findsOneWidget);
      expect(find.text('12.500 Kz'), findsOneWidget);
      expect(find.text('EM CURSO'), findsOneWidget);
      expect(find.text('Carlos D. · 24 set'), findsOneWidget);
      expect(find.text('CANCELADO'), findsOneWidget);
      expect(find.text('Pedir de novo'), findsOneWidget);
      expect(find.text('Ver comprovativo'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('filtro Cancelados e cartão em curso navega', (tester) async {
      _ecra(tester);
      await tester.pumpWidget(_app(MockKisaluRepository()));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Cancelados'));
      await tester.tap(find.text('Cancelados'));
      await tester.pumpAndSettle();
      expect(find.text('Pastilhas de travão'), findsOneWidget);
      expect(find.text('Fuga de água'), findsNothing);

      await tester.ensureVisible(find.text('Todos'));
      await tester.tap(find.text('Todos'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fuga de água'));
      await tester.pumpAndSettle();
      expect(find.text('detalhe ped1'), findsOneWidget);
    });

    testWidgets('Pedir de novo abre o novo pedido', (tester) async {
      _ecra(tester);
      await tester.pumpWidget(_app(MockKisaluRepository()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pedir de novo'));
      await tester.pumpAndSettle();
      expect(find.text('novo de=ped2'), findsOneWidget);
    });

    testWidgets('"Avaliar" só nos concluídos sem avaliação e some depois', (
      tester,
    ) async {
      _ecra(tester);
      final repo = MockKisaluRepository();
      await tester.pumpWidget(_app(repo));
      await tester.pumpAndSettle();
      // ped2 por avaliar; ped3 e ped5 já avaliados.
      expect(find.text('Avaliar'), findsOneWidget);
      await tester.tap(find.text('Avaliar'));
      await tester.pumpAndSettle();
      expect(find.text('avaliar ped2'), findsOneWidget);

      await repo.enviarAvaliacao(
        'ped2',
        (await repo.rascunhoAvaliacao('ped1'))!,
      );
      final c = HistoricoPedidosController(repo);
      await c.carregar();
      final ped2 = c.filtrados.firstWhere((p) => p.id == 'ped2');
      expect(c.podeAvaliar(ped2), isFalse);
      c.dispose();
    });

    testWidgets('profissional: tocar num trabalho abre o detalhe', (
      tester,
    ) async {
      _ecra(tester);
      final repo = MockKisaluRepository();
      await repo.mudarPerfil(PerfilUtilizador.profissional);
      await tester.pumpWidget(_app(repo));
      await tester.pumpAndSettle();
      expect(find.text('Avaliar'), findsNothing);
      await tester.tap(find.text('Fuga de água'));
      await tester.pumpAndSettle();
      expect(find.text('trabalho tp1'), findsOneWidget);
    });

    testWidgets('"Reportar problema" usa a folha e mostra o contacto', (
      tester,
    ) async {
      _ecra(tester);
      final repo = MockKisaluRepository();
      await tester.pumpWidget(_app(repo));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ver comprovativo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reportar problema'));
      await tester.pumpAndSettle();
      expect(find.text('O trabalho tem um problema?'), findsOneWidget);
      await tester.enterText(
        find.byType(TextField),
        'A tomada voltou a falhar ontem.',
      );
      await tester.tap(find.text('Enviar'));
      await tester.pumpAndSettle();
      expect(repo.reportes.single.pedidoId, 'ped2');
      expect(find.text('Contacto do profissional'), findsOneWidget);
    });

    testWidgets('Ver comprovativo abre a folha', (tester) async {
      _ecra(tester);
      await tester.pumpWidget(_app(MockKisaluRepository()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ver comprovativo'));
      await tester.pumpAndSettle();
      expect(find.text('Serviço confirmado'), findsOneWidget);
      expect(find.text('KX-301854'), findsOneWidget);
      expect(find.text('Partilhar'), findsOneWidget);
      expect(find.text('Reportar problema'), findsOneWidget);
    });

    testWidgets('estado de erro mostra Tentar outra vez', (tester) async {
      _ecra(tester);
      await tester.pumpWidget(_app(_RepoComFalha()));
      await tester.pumpAndSettle();
      expect(find.text('Tentar outra vez'), findsOneWidget);
    });

    testWidgets('sem overflow com texto a 200 %', (tester) async {
      _ecra(tester);
      await tester.pumpWidget(_app(MockKisaluRepository(), escala: 2));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
