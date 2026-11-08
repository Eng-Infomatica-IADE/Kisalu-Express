import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kisalu_express/core/state/estado_ui.dart';
import 'package:kisalu_express/core/state/reportar_problema_controller.dart';
import 'package:kisalu_express/core/theme/k_theme.dart';
import 'package:kisalu_express/data/repositories/kisalu_repository.dart';
import 'package:kisalu_express/data/repositories/mock_kisalu_repository.dart';
import 'package:kisalu_express/features/confirmacao_qr/controllers/confirmar_servico_controller.dart';
import 'package:kisalu_express/features/confirmacao_qr/views/confirmar_servico_view.dart';
import 'package:kisalu_express/models/estado_pedido.dart';
import 'package:kisalu_express/models/pedido.dart';
import 'package:kisalu_express/models/resultado_reporte.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

class _SemLigacao extends MockKisaluRepository {
  @override
  Future<ResultadoReporte> reportarProblema(
    String pedidoId,
    String descricao,
  ) async => throw const SemRedeException();
}

/// Como a API real: sem atalho de demonstração, e o profissional confirma
/// "noutro telemóvel" quando [confirmado] passa a true.
class _ComoApi extends MockKisaluRepository {
  bool confirmado = false;

  @override
  bool get modoDemonstracao => false;

  @override
  Future<Pedido?> pedido(String id) async {
    final emCurso = await servicoEmCurso();
    if (emCurso != null && emCurso.id == id) {
      return confirmado
          ? emCurso.copyWith(estado: EstadoPedido.concluido)
          : emCurso;
    }
    return super.pedido(id);
  }
}

Widget _app(KisaluRepository repo, {double escala = 1, Duration? intervalo}) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) =>
            ConfirmarServicoView(intervaloVerificacao: intervalo),
      ),
      GoRoute(path: '/pedidos', builder: (_, _) => const Text('lista')),
      GoRoute(
        path: '/pedidos/:id/avaliar',
        builder: (_, _) => const Text('avaliar'),
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

  group('ConfirmarServicoController', () {
    test('com serviço em curso devolve Sucesso com o token opaco', () async {
      final c = ConfirmarServicoController(MockKisaluRepository());
      await c.carregar();
      final s = (c.estado as Sucesso<ServicoParaConfirmar>).dados;
      expect(s.profissional, 'Joaquim Manuel');
      expect(s.valor, 12500);
      expect(s.codigo.codigo, '482173');
      expect(s.codigo.token.contains(s.pedidoId), isFalse);
      expect(s.codigo.token.contains(s.codigo.codigo), isFalse);
    });

    test('sem serviço em curso devolve Vazio (ecrã 09)', () async {
      final c = ConfirmarServicoController(
        MockKisaluRepository(comServicoEmCurso: false),
      );
      await c.carregar();
      expect(c.estado, isA<Vazio<ServicoParaConfirmar>>());
    });

    test('forcarVazio devolve Vazio', () async {
      final c = ConfirmarServicoController(
        MockKisaluRepository(),
        forcarVazio: true,
      );
      await c.carregar();
      expect(c.estado, isA<Vazio<ServicoParaConfirmar>>());
    });

    test('com pedidoId mostra o QR desse pedido', () async {
      final repo = _ComoApi();
      final c = ConfirmarServicoController(repo, pedidoId: 'ped1');
      await c.carregar();
      expect(
        (c.estado as Sucesso<ServicoParaConfirmar>).dados.pedidoId,
        'ped1',
      );
      c.dispose();
    });

    test('pedido novo (sem aceitar) pelo pedidoId dá Vazio', () async {
      final c = ConfirmarServicoController(
        MockKisaluRepository(),
        pedidoId: 'ped1', // no detalhe do mock, ainda NOVO
      );
      await c.carregar();
      expect(c.estado, isA<Vazio<ServicoParaConfirmar>>());
      c.dispose();
    });

    test(
      'verificar: quando o profissional confirma, preenche concluidoId',
      () async {
        final repo = _ComoApi();
        final c = ConfirmarServicoController(
          repo,
          intervaloVerificacao: Duration.zero,
        );
        await c.carregar();
        await c.verificar();
        expect(c.concluidoId, isNull);
        repo.confirmado = true;
        await c.verificar();
        expect(c.concluidoId, 'ped1');
        expect(c.atalhoDemonstracao, isFalse);
        c.dispose();
      },
    );
  });

  group('ReportarProblemaController', () {
    test('valida e envia', () async {
      final repo = MockKisaluRepository();
      final c = ReportarProblemaController(repo, 'ped1');
      expect(await c.enviar(''), isNull);
      expect(c.erro, 'Conte-nos o que aconteceu.');
      expect(await c.enviar('curto'), isNull);
      expect(c.erro, 'Escreva um pouco mais para percebermos o problema.');
      final r = await c.enviar('A torneira continua a pingar.');
      expect(r, isNotNull);
      expect(r!.contactoNome, 'Joaquim Manuel');
      expect(repo.reportes.single.pedidoId, 'ped1');
    });

    test('falha de rede mostra a mensagem do catálogo', () async {
      final c = ReportarProblemaController(_SemLigacao(), 'ped1');
      expect(await c.enviar('A torneira continua a pingar.'), isNull);
      expect(c.erro, 'Sem ligação. Confirme a sua rede e tente outra vez.');
    });

    test('fora da garantia mostra o erro (422)', () async {
      final c = ReportarProblemaController(MockKisaluRepository(), 'ped3');
      expect(await c.enviar('O ar condicionado voltou a pingar.'), isNull);
      expect(c.erro, contains('7 dias'));
    });
  });

  group('ConfirmarServicoView', () {
    testWidgets('05: renderiza QR, código e passos', (tester) async {
      _ecra(tester);
      await tester.pumpWidget(_app(MockKisaluRepository()));
      await tester.pumpAndSettle();

      expect(find.text('Confirmar serviço'), findsOneWidget);
      expect(
        find.text(
          'Mostre o código só quando o trabalho estiver concluído e '
          'verificado.',
        ),
        findsOneWidget,
      );
      expect(find.byType(QrImageView), findsOneWidget);
      expect(find.text('Joaquim Manuel'), findsOneWidget);
      expect(find.text('Canalizador · 12.500 Kz'), findsOneWidget);
      expect(find.text('482 173'), findsOneWidget);
      expect(find.text('O trabalho tem um problema?'), findsOneWidget);
      expect(find.text('Como funciona?'), findsOneWidget);
      expect(find.text('O profissional lê o código'), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          'Código QR para confirmar o serviço de 12.500 Kz',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('05: "Como funciona?" e problema abrem folhas', (tester) async {
      _ecra(tester);
      final repo = MockKisaluRepository();
      await tester.pumpWidget(_app(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Como funciona?'));
      await tester.pumpAndSettle();
      expect(find.text('Confirma o valor combinado'), findsNWidgets(2));
      await tester.tapAt(const Offset(195, 20)); // barreira
      await tester.pumpAndSettle();

      await tester.tap(find.text('O trabalho tem um problema?'));
      await tester.pumpAndSettle();
      expect(
        find.text('Conte-nos o que aconteceu. Tem 7 dias.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Enviar'));
      await tester.pumpAndSettle();
      expect(find.text('Conte-nos o que aconteceu.'), findsOneWidget);

      await tester.enterText(
        find.byType(TextField),
        'A torneira continua a pingar.',
      );
      await tester.tap(find.text('Enviar'));
      await tester.pumpAndSettle();
      expect(repo.reportes, hasLength(1));
      expect(find.text('Problema enviado'), findsOneWidget);
      expect(find.text('Contacto do profissional'), findsOneWidget);
      expect(find.text('+244 923 111 222'), findsOneWidget);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.text('Problema enviado'), findsNothing);
    });

    testWidgets('05: tocar no QR abre a avaliação (demo)', (tester) async {
      _ecra(tester);
      await tester.pumpWidget(_app(MockKisaluRepository()));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(QrImageView));
      await tester.pumpAndSettle();
      expect(find.text('avaliar'), findsOneWidget);
    });

    testWidgets('05 com a API: o QR não é atalho e o ecrã avança sozinho', (
      tester,
    ) async {
      _ecra(tester);
      final repo = _ComoApi();
      await tester.pumpWidget(
        _app(repo, intervalo: const Duration(seconds: 5)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(QrImageView));
      await tester.pumpAndSettle();
      expect(find.text('avaliar'), findsNothing);

      repo.confirmado = true;
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();
      expect(find.text('avaliar'), findsOneWidget);
    });

    testWidgets('09: sem serviço mostra o estado vazio', (tester) async {
      _ecra(tester);
      await tester.pumpWidget(
        _app(MockKisaluRepository(comServicoEmCurso: false)),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Ainda não tem serviços para confirmar'),
        findsOneWidget,
      );
      expect(
        find.text(
          'Quando aceitar uma proposta, o código QR do serviço aparece aqui.',
        ),
        findsOneWidget,
      );
      expect(find.byType(QrImageView), findsNothing);
      await tester.tap(find.text('Ver os meus pedidos'));
      await tester.pumpAndSettle();
      expect(find.text('lista'), findsOneWidget);
    });

    testWidgets('sem overflow com texto a 200 %', (tester) async {
      _ecra(tester);
      await tester.pumpWidget(_app(MockKisaluRepository(), escala: 2));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
