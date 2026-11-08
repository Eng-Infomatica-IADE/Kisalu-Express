import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kisalu_express/core/theme/k_icons.dart';
import 'package:kisalu_express/core/theme/k_theme.dart';
import 'package:kisalu_express/data/repositories/kisalu_repository.dart';
import 'package:kisalu_express/data/repositories/mock_kisalu_repository.dart';
import 'package:kisalu_express/features/pedidos/views/pedido_detalhe_view.dart';
import 'package:provider/provider.dart';

Widget _app(KisaluRepository repo, {String id = 'ped1', double escala = 1}) {
  // ShellRoute: o Scaffold persiste, como o AppShell na app.
  final router = GoRouter(
    initialLocation: '/pedidos/$id',
    routes: [
      ShellRoute(
        builder: (_, _, child) => Scaffold(body: child),
        routes: [
          GoRoute(
            path: '/pedidos/:id',
            builder: (_, s) =>
                PedidoDetalheView(pedidoId: s.pathParameters['id']!),
          ),
          GoRoute(path: '/qr', builder: (_, _) => const Text('QR destino')),
          GoRoute(path: '/pedidos', builder: (_, _) => const Text('Histórico')),
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

void _tela(WidgetTester t, {double altura = 1600}) {
  t.view.physicalSize = Size(390, altura);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('renderiza o pedido e a primeira proposta', (t) async {
    _tela(t);
    await t.pumpWidget(_app(MockKisaluRepository()));
    await t.pumpAndSettle();
    expect(find.text('O meu pedido'), findsOneWidget);
    expect(find.text('Fuga de água na cozinha'), findsOneWidget);
    expect(find.text('NOVO'), findsOneWidget);
    expect(find.text('3 PROPOSTAS'), findsOneWidget);
    expect(find.text('Talatona'), findsOneWidget);
    expect(find.text('Hoje, 16:00'), findsOneWidget);
    expect(find.text('Propostas recebidas'), findsOneWidget);
    expect(find.text('Joaquim M.'), findsOneWidget);
    expect(find.text('12.500 Kz'), findsOneWidget);
    expect(find.text('Ver e aceitar'), findsWidgets);
    expect(t.takeException(), isNull);
  });

  testWidgets('ordenar por chegada muda a primeira proposta', (t) async {
    _tela(t);
    await t.pumpWidget(_app(MockKisaluRepository()));
    await t.pumpAndSettle();
    await t.tap(find.text('Chegada'));
    await t.pumpAndSettle();
    final y = t.getTopLeft(find.text('Paulo Neto')).dy;
    expect(y, lessThan(t.getTopLeft(find.text('Joaquim M.')).dy));
  });

  testWidgets('folha 08: confirma, mostra snack e vai para o QR', (t) async {
    _tela(t);
    await t.pumpWidget(_app(MockKisaluRepository()));
    await t.pumpAndSettle();
    await t.tap(find.text('Ver e aceitar').first);
    await t.pumpAndSettle();
    expect(find.text('Confirmar a proposta?'), findsOneWidget);
    expect(
      find.text(
        'O Joaquim só recebe a sua morada e o seu contacto depois de '
        'confirmar.',
      ),
      findsOneWidget,
    );
    expect(find.text('Joaquim Manuel ✓'), findsOneWidget);
    expect(find.text('Hoje, 15h40'), findsOneWidget);
    await t.tap(find.text('Confirmar proposta'));
    await t.pumpAndSettle();
    expect(find.text('QR destino'), findsOneWidget);
    expect(
      find.text(
        'Proposta aceite. O Joaquim já foi avisado. '
        'Pode desfazer nos próximos 5 minutos.',
      ),
      findsOneWidget,
    );
    expect(find.text('Desfazer'), findsOneWidget);
    // Não fica para sempre (não tapa a conversa): some ao fim de 10 s.
    await t.pump(const Duration(seconds: 11));
    await t.pumpAndSettle();
    expect(find.text('Desfazer'), findsNothing);
  });

  testWidgets('com proposta aceite mostra o acordo, sem aceitar nem editar', (
    t,
  ) async {
    _tela(t);
    final repo = MockKisaluRepository();
    await repo.aceitarProposta('ped1', 'pr1');
    await t.pumpWidget(_app(repo));
    await t.pumpAndSettle();
    expect(find.text('Proposta aceite'), findsOneWidget);
    expect(find.text('ACEITE'), findsOneWidget);
    expect(find.text('12.500 Kz'), findsOneWidget);
    expect(find.text('Ver e aceitar'), findsNothing);
    expect(find.text('Recusar'), findsNothing);
    expect(find.text('Conversa'), findsOneWidget);
    expect(find.text('Desfazer aceitação (até 5 min)'), findsOneWidget);

    await t.tap(find.byIcon(KIcons.mais));
    await t.pumpAndSettle();
    expect(find.text('Editar pedido'), findsNothing);
    expect(find.text('Cancelar pedido'), findsOneWidget);
    await t.tapAt(const Offset(10, 10));
    await t.pumpAndSettle();

    await t.tap(find.text('Ver código QR'));
    await t.pumpAndSettle();
    expect(find.text('QR destino'), findsOneWidget);
  });

  testWidgets('"Desfazer aceitação" no acordo volta às propostas', (t) async {
    _tela(t);
    final repo = MockKisaluRepository();
    await repo.aceitarProposta('ped1', 'pr1');
    await t.pumpWidget(_app(repo));
    await t.pumpAndSettle();
    await t.tap(find.text('Desfazer aceitação (até 5 min)'));
    await t.pumpAndSettle();
    expect(find.text('Propostas recebidas'), findsOneWidget);
    expect(find.text('Ver e aceitar'), findsNWidgets(3));
  });

  testWidgets('"Recusar" pede confirmação e tira a proposta', (t) async {
    _tela(t);
    final repo = MockKisaluRepository();
    await t.pumpWidget(_app(repo));
    await t.pumpAndSettle();
    expect(find.text('Recusar'), findsNWidgets(3));
    await t.tap(find.text('Recusar').first);
    await t.pumpAndSettle();
    expect(find.text('Recusar esta proposta?'), findsOneWidget);
    await t.tap(find.text('Manter'));
    await t.pumpAndSettle();
    expect(repo.recusadas, isEmpty);

    await t.tap(find.text('Recusar').first);
    await t.pumpAndSettle();
    await t.tap(find.text('Recusar').last);
    await t.pumpAndSettle();
    expect(repo.recusadas.single.propostaId, 'pr1');
    expect(find.text('Proposta recusada.'), findsOneWidget);
    expect(find.text('Ver e aceitar'), findsNWidgets(2));
  });

  testWidgets('"Voltar às propostas" fecha a folha', (t) async {
    _tela(t);
    await t.pumpWidget(_app(MockKisaluRepository()));
    await t.pumpAndSettle();
    await t.tap(find.text('Ver e aceitar').first);
    await t.pumpAndSettle();
    await t.tap(find.text('Voltar às propostas'));
    await t.pumpAndSettle();
    expect(find.text('Confirmar a proposta?'), findsNothing);
    expect(find.text('Propostas recebidas'), findsOneWidget);
  });

  testWidgets('menu ⋯ abre as opções e cancelar pede confirmação', (t) async {
    _tela(t);
    await t.pumpWidget(_app(MockKisaluRepository()));
    await t.pumpAndSettle();
    await t.tap(find.byIcon(KIcons.mais));
    await t.pumpAndSettle();
    expect(find.text('Editar pedido'), findsOneWidget);
    await t.tap(find.text('Cancelar pedido'));
    await t.pumpAndSettle();
    expect(find.text('Cancelar este pedido?'), findsOneWidget);
    expect(
      find.text('Os 3 profissionais que enviaram proposta vão ser avisados.'),
      findsOneWidget,
    );
  });

  testWidgets('pedido inexistente mostra "Não encontrado"', (t) async {
    _tela(t);
    await t.pumpWidget(_app(MockKisaluRepository(), id: 'xyz'));
    await t.pumpAndSettle();
    expect(find.text('Não encontrado'), findsOneWidget);
    expect(find.text('Ver os meus pedidos'), findsOneWidget);
  });

  testWidgets('sem overflow em 390x844 com texto a 200 %', (t) async {
    _tela(t, altura: 844);
    await t.pumpWidget(_app(MockKisaluRepository(), escala: 2));
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
    await t.drag(find.byType(ListView), const Offset(0, -700));
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
    await t.ensureVisible(find.text('Ver e aceitar').first);
    await t.pumpAndSettle();
    await t.tap(find.text('Ver e aceitar').first);
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
  });
}
