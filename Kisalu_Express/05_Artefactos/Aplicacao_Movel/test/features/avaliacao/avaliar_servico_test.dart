import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kisalu_express/core/state/estado_ui.dart';
import 'package:kisalu_express/core/theme/k_theme.dart';
import 'package:kisalu_express/core/widgets/widgets.dart';
import 'package:kisalu_express/data/repositories/kisalu_repository.dart';
import 'package:kisalu_express/data/repositories/mock_kisalu_repository.dart';
import 'package:kisalu_express/features/avaliacao/controllers/avaliar_servico_controller.dart';
import 'package:kisalu_express/features/avaliacao/views/avaliar_servico_view.dart';
import 'package:kisalu_express/models/avaliacao.dart';
import 'package:kisalu_express/models/comprovativo.dart';
import 'package:provider/provider.dart';

Widget _app(KisaluRepository repo, {String id = 'ped1', double escala = 1}) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => AvaliarServicoView(pedidoId: id),
      ),
      GoRoute(
        path: '/pedidos',
        builder: (_, _) => const Scaffold(body: Text('lista')),
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

  group('AvaliarServicoController', () {
    test('carrega o rascunho do repositório', () async {
      final c = AvaliarServicoController(MockKisaluRepository(), 'ped1');
      await c.carregar();
      expect(c.estado, isA<Sucesso<Comprovativo>>());
      expect(c.estrelas, 4);
      expect(c.rotuloEstrelas, 'Muito bom');
      expect(c.etiquetas, contains(EtiquetaAvaliacao.pontual));
    });

    test('pedido sem comprovativo é "não encontrado"', () async {
      final c = AvaliarServicoController(MockKisaluRepository(), 'ped4');
      await c.carregar();
      final e = c.estado as Erro<Comprovativo>;
      expect(e.naoEncontrado, isTrue);
    });

    test('sem estrelas não envia', () async {
      final c = AvaliarServicoController(MockKisaluRepository(), 'ped2');
      await c.carregar();
      expect(c.estrelas, 0);
      expect(await c.enviar(), isFalse);
      expect(c.erroEstrelas, 'Escolha de 1 a 5 estrelas.');
    });

    test('comentário acima do limite não envia', () async {
      final c = AvaliarServicoController(MockKisaluRepository(), 'ped2');
      await c.carregar();
      c.definirEstrelas(5);
      c.alterarComentario('a' * 301);
      expect(await c.enviar(), isFalse);
      expect(c.erroComentario, isNotNull);
    });

    test('envia e a segunda vez falha com "já foi avaliado"', () async {
      final repo = MockKisaluRepository();
      final c = AvaliarServicoController(repo, 'ped2');
      await c.carregar();
      c.definirEstrelas(5);
      c.alternarEtiqueta(EtiquetaAvaliacao.rapido);
      expect(await c.enviar(), isTrue);
      expect(repo.avaliacoesEnviadas['ped2']!.estrelas, 5);
      expect(await c.enviar(), isFalse);
      expect(c.erroEnvio, 'Este serviço já foi avaliado.');
    });
  });

  group('AvaliarServicoView', () {
    testWidgets('renderiza o estado do Figma', (tester) async {
      final semantics = tester.ensureSemantics();
      _ecra(tester);
      await tester.pumpWidget(_app(MockKisaluRepository()));
      await tester.pumpAndSettle();

      expect(find.text('Avaliar serviço'), findsOneWidget);
      expect(find.text('Serviço confirmado'), findsOneWidget);
      expect(find.text('Fuga de água na cozinha · 12.500 Kz'), findsOneWidget);
      expect(
        find.text('Comprovativo guardado em Pedidos · Ver'),
        findsOneWidget,
      );
      expect(find.text('Como correu com o Joaquim?'), findsOneWidget);
      expect(find.text('Muito bom'), findsOneWidget);
      expect(find.text('O que correu bem?'), findsOneWidget);
      for (final e in EtiquetaAvaliacao.values) {
        expect(find.text(e.rotulo), findsOneWidget);
      }
      expect(
        find.text('Resolveu tudo em 40 minutos. Voltaria a chamar.'),
        findsOneWidget,
      );
      expect(find.text('Enviar avaliação'), findsOneWidget);
      expect(find.text('Avaliar mais tarde'), findsOneWidget);
      expect(
        tester.getSemantics(find.byType(KEstrelas)).value,
        '4 de 5 estrelas',
      );
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });

    testWidgets('estrelas, chips e envio', (tester) async {
      _ecra(tester);
      final repo = MockKisaluRepository();
      await tester.pumpWidget(_app(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.star_rounded).last);
      await tester.pumpAndSettle();
      expect(find.text('Excelente'), findsOneWidget);

      await tester.tap(find.text('Simpático'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Enviar avaliação'));
      await tester.tap(find.text('Enviar avaliação'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(repo.avaliacoesEnviadas['ped1']!.estrelas, 5);
      expect(
        repo.avaliacoesEnviadas['ped1']!.etiquetas,
        contains(EtiquetaAvaliacao.simpatico),
      );
      expect(find.text('lista'), findsOneWidget);
      expect(find.text('Avaliação enviada. Obrigado!'), findsOneWidget);
    });

    testWidgets('"Avaliar mais tarde" volta aos pedidos sem enviar', (
      tester,
    ) async {
      _ecra(tester);
      final repo = MockKisaluRepository();
      await tester.pumpWidget(_app(repo));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Avaliar mais tarde'));
      await tester.tap(find.text('Avaliar mais tarde'));
      await tester.pumpAndSettle();
      expect(find.text('lista'), findsOneWidget);
      expect(repo.avaliacoesEnviadas, isEmpty);
    });

    testWidgets('sem estrelas mostra o erro', (tester) async {
      _ecra(tester);
      await tester.pumpWidget(_app(MockKisaluRepository(), id: 'ped2'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Enviar avaliação'));
      await tester.tap(find.text('Enviar avaliação'));
      await tester.pumpAndSettle();
      expect(find.text('Escolha de 1 a 5 estrelas.'), findsOneWidget);
    });

    testWidgets('pedido desconhecido mostra "não encontrado"', (tester) async {
      _ecra(tester);
      await tester.pumpWidget(_app(MockKisaluRepository(), id: 'ped4'));
      await tester.pumpAndSettle();
      expect(find.text('Não encontrado'), findsOneWidget);
      expect(find.text('Ver os meus pedidos'), findsOneWidget);
    });

    testWidgets('sem overflow com texto a 200 %', (tester) async {
      _ecra(tester);
      await tester.pumpWidget(_app(MockKisaluRepository(), escala: 2));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
