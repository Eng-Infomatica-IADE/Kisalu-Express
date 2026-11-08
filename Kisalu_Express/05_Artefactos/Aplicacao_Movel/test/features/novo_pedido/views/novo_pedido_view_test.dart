import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kisalu_express/core/theme/k_icons.dart';
import 'package:kisalu_express/core/theme/k_theme.dart';
import 'package:kisalu_express/data/repositories/kisalu_repository.dart';
import 'package:kisalu_express/data/repositories/mock_kisalu_repository.dart';
import 'package:kisalu_express/features/novo_pedido/controllers/novo_pedido_controller.dart';
import 'package:kisalu_express/features/novo_pedido/views/novo_pedido_view.dart';
import 'package:provider/provider.dart';

Widget _app(
  KisaluRepository repo, {
  PassoNovoPedido? passo,
  double escala = 1,
}) {
  final router = GoRouter(
    initialLocation: '/inicio/novo',
    routes: [
      ShellRoute(
        builder: (_, _, child) => child,
        routes: [
          GoRoute(path: '/inicio', builder: (_, _) => const Text('Início')),
          GoRoute(
            path: '/inicio/novo',
            builder: (_, _) => NovoPedidoView(
              passoInicial: passo,
              pausaTentativa: Duration.zero,
            ),
          ),
          GoRoute(
            path: '/pedidos/:id',
            builder: (_, _) => const Text('Detalhe destino'),
          ),
        ],
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

void _tela(WidgetTester t) {
  t.view.physicalSize = const Size(390, 844);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('ecrã 10: rascunho, alerta e botão desativado', (t) async {
    _tela(t);
    await t.pumpWidget(_app(MockKisaluRepository()));
    await t.pumpAndSettle();
    expect(find.text('Novo pedido'), findsOneWidget);
    expect(find.text('Passo 3 de 4 · Rever o pedido'), findsOneWidget);
    expect(find.text('Fuga de água na cozinha'), findsOneWidget);
    expect(find.textContaining('Sem ligação.'), findsOneWidget);
    expect(find.text('Talatona · perto da cantina do Sr. Zé'), findsOneWidget);
    expect(find.text('Hoje, o mais cedo possível'), findsOneWidget);
    expect(find.text('1 foto anexada'), findsOneWidget);
    expect(find.text('A aguardar rede…'), findsOneWidget);
    expect(find.text('Tentar outra vez'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('"Tentar outra vez" sem rede mantém o estado', (t) async {
    _tela(t);
    await t.pumpWidget(_app(MockKisaluRepository()));
    await t.pumpAndSettle();
    await t.tap(find.text('Tentar outra vez'));
    await t.pumpAndSettle();
    expect(find.text('A aguardar rede…'), findsOneWidget);
  });

  testWidgets('com rede: publica, e navega para o pedido', (t) async {
    _tela(t);
    await t.pumpWidget(_app(MockKisaluRepository(semRede: false)));
    await t.pumpAndSettle();
    expect(find.textContaining('Sem ligação.'), findsNothing);
    expect(find.text('Tentar outra vez'), findsNothing);
    await t.tap(find.text('Publicar pedido'));
    await t.pumpAndSettle();
    expect(find.text('Detalhe destino'), findsOneWidget);
  });

  testWidgets('recupera a rede com "Tentar outra vez"', (t) async {
    _tela(t);
    final repo = MockKisaluRepository();
    await t.pumpWidget(_app(repo));
    await t.pumpAndSettle();
    repo.semRede = false;
    await t.tap(find.text('Tentar outra vez'));
    await t.pumpAndSettle();
    expect(find.text('Publicar pedido'), findsOneWidget);
    expect(find.textContaining('Sem ligação.'), findsNothing);
  });

  testWidgets('passo 1: erros ao continuar vazio', (t) async {
    _tela(t);
    await t.pumpWidget(
      _app(MockKisaluRepository(), passo: PassoNovoPedido.descricao),
    );
    await t.pumpAndSettle();
    expect(find.text('Passo 1 de 4 · O que precisa'), findsOneWidget);
    await t.tap(find.text('Continuar'));
    await t.pumpAndSettle();
    expect(find.text('Escolha o tipo de serviço.'), findsOneWidget);
    expect(
      find.text('Descreva o problema para receber propostas certas.'),
      findsOneWidget,
    );
  });

  testWidgets('passo 1 → 2 e voltar', (t) async {
    _tela(t);
    await t.pumpWidget(
      _app(MockKisaluRepository(), passo: PassoNovoPedido.descricao),
    );
    await t.pumpAndSettle();
    await t.tap(find.text('Canalizador'));
    await t.enterText(
      find.widgetWithText(TextField, 'Fuga de água na cozinha').first,
      'Fuga de água',
    );
    await t.enterText(
      find.widgetWithText(TextField, 'Cano a pingar debaixo do lava-loiça.'),
      'Cano a pingar debaixo do lava-loiça.',
    );
    await t.tap(find.text('Continuar'));
    await t.pumpAndSettle();
    expect(find.text('Passo 2 de 4 · Onde'), findsOneWidget);
    expect(
      find.text('Ajuda o profissional a encontrar a sua casa.'),
      findsOneWidget,
    );
    await t.tap(find.byIcon(KIcons.voltar));
    await t.pumpAndSettle();
    expect(find.text('Passo 1 de 4 · O que precisa'), findsOneWidget);
  });

  testWidgets('sem overflow com texto a 200 %', (t) async {
    _tela(t);
    await t.pumpWidget(_app(MockKisaluRepository(), escala: 2));
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
  });
}
