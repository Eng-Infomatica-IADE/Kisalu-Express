import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kisalu_express/core/router/app_router.dart';
import 'package:kisalu_express/core/router/app_routes.dart';
import 'package:kisalu_express/core/theme/k_theme.dart';
import 'package:kisalu_express/core/widgets/widgets.dart';
import 'package:kisalu_express/data/repositories/kisalu_repository.dart';
import 'package:kisalu_express/data/repositories/mock_kisalu_repository.dart';
import 'package:kisalu_express/models/utilizador.dart';
import 'package:provider/provider.dart';

/// Garante que todas as rotas das telas do Figma abrem no ecrã certo: cada
/// uma é identificada por um texto-chave (ver docs/design/SCREENS.md).
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  final rotas = <String, String>{
    AppRoutes.login: 'Entrar ou criar conta',
    AppRoutes.inicio: 'Perto de si',
    AppRoutes.profissional('p1'): 'Especialidades',
    AppRoutes.pedido('ped1'): 'O meu pedido',
    AppRoutes.qr: 'Se a leitura falhar, diga este código:',
    AppRoutes.avaliar('ped1'): 'Avaliar serviço',
    AppRoutes.pedidos: 'Os seus pedidos',
    '${AppRoutes.qr}?vazio=1': 'Ainda não tem serviços para confirmar',
    AppRoutes.novoPedido: 'Passo 3 de 4 · Rever o pedido',
    AppRoutes.novoPedidoInicio: 'Passo 1 de 4 · O que precisa',
    // Ecrãs 11 a 22 (Figma v3).
    AppRoutes.codigoSms: 'Introduza o código',
    AppRoutes.registoProfissional: 'Que serviços presta?',
    AppRoutes.verificarIdentidade: 'Documento de identidade',
    AppRoutes.enviarProposta('pp1'): 'O que inclui o preço?',
    AppRoutes.servicoConfirmado('tp1'): 'Trabalho concluído',
    AppRoutes.conversas: 'Chego às 15h40, como combinado.',
    AppRoutes.conversa('c1'): 'Escreva uma mensagem',
    AppRoutes.perfil: 'Maria Kiala',
    AppRoutes.categorias: 'Procurar um serviço',
    AppRoutes.mapa: 'Lista',
  };

  Future<void> abrir(WidgetTester tester, String rota) async {
    await tester.pumpWidget(
      Provider<KisaluRepository>.value(
        value: MockKisaluRepository(),
        child: MaterialApp.router(
          theme: KTheme.light(),
          routerConfig: createRouter(initialLocation: rota),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final MapEntry(key: rota, value: esperado) in rotas.entries) {
    testWidgets('rota $rota abre', (tester) async {
      await abrir(tester, rota);
      expect(find.text(esperado), findsOneWidget);
    });
  }

  testWidgets('rota desconhecida mostra o erro simples, sem detalhes', (
    tester,
  ) async {
    await abrir(tester, '/nao-existe');
    expect(find.text('Não encontrámos esta página'), findsOneWidget);
    expect(find.text('Ir para o início'), findsOneWidget);
    expect(find.textContaining('/nao-existe'), findsNothing);
  });

  testWidgets(':id com formato inválido mostra "não encontrado"', (
    tester,
  ) async {
    await abrir(tester, '/profissional/id%20invalido');
    expect(find.text('Não encontrámos esta página'), findsOneWidget);
    await abrir(tester, '/pedidos/a%24b/avaliar');
    expect(find.text('Não encontrámos esta página'), findsOneWidget);
  });

  testWidgets(':id válido mas desconhecido abre a view (que trata o caso)', (
    tester,
  ) async {
    await abrir(tester, AppRoutes.pedido('zzz'));
    expect(find.text('O meu pedido'), findsOneWidget);
    expect(find.text('Não encontrado'), findsOneWidget);
  });

  test('AppRoutes valida e codifica ids', () {
    expect(AppRoutes.idValido('ped1'), isTrue);
    expect(AppRoutes.idValido('p_1-A'), isTrue);
    expect(AppRoutes.idValido(null), isFalse);
    expect(AppRoutes.idValido(''), isFalse);
    expect(AppRoutes.idValido('a/b'), isFalse);
    expect(AppRoutes.idValido('x' * 65), isFalse);
    expect(AppRoutes.pedido('a b'), '/pedidos/a%20b');
  });

  testWidgets('?novo só aceita o valor 1: o resto abre o ecrã 10', (
    tester,
  ) async {
    for (final valor in ['0', '2', 'x', '1%20', '']) {
      await abrir(tester, '${AppRoutes.novoPedido}?novo=$valor');
      expect(find.text('Passo 3 de 4 · Rever o pedido'), findsOneWidget);
    }
  });

  test('a app arranca no Login', () {
    final router = createRouter();
    addTearDown(router.dispose);
    expect(router.routeInformationProvider.value.uri.path, AppRoutes.login);
  });

  testWidgets('/dev existe em debug', (tester) async {
    await abrir(tester, AppRoutes.dev);
    expect(find.text('Kisalu · ecrãs (dev)'), findsOneWidget);
  });

  testWidgets('QR na barra fica ativo com serviço em curso', (tester) async {
    await abrir(tester, AppRoutes.inicio);
    expect(
      find.bySemanticsLabel('QR, confirmar o serviço em curso'),
      findsOneWidget,
    );
  });

  testWidgets('a barra volta a ler o serviço após aceitar e desfazer', (
    tester,
  ) async {
    final repo = MockKisaluRepository(comServicoEmCurso: false);
    await tester.pumpWidget(
      Provider<KisaluRepository>.value(
        value: repo,
        child: MaterialApp.router(
          theme: KTheme.light(),
          routerConfig: createRouter(initialLocation: AppRoutes.inicio),
        ),
      ),
    );
    await tester.pumpAndSettle();
    const semServico = 'QR, sem serviços para confirmar';
    const comServico = 'QR, confirmar o serviço em curso';
    expect(find.bySemanticsLabel(semServico), findsOneWidget);

    await repo.aceitarProposta('ped1', 'pr1');
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel(comServico), findsOneWidget);

    await repo.desfazerAceitacao('ped1');
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel(semServico), findsOneWidget);
  });

  testWidgets('QR na barra fica desativado no ecrã 09', (tester) async {
    await abrir(tester, '${AppRoutes.qr}?vazio=1');
    expect(
      find.bySemanticsLabel('QR, sem serviços para confirmar'),
      findsOneWidget,
    );
  });

  group('rotas novas (11 a 22)', () {
    testWidgets(':pedidoId e :id com formato inválido não rebentam', (
      tester,
    ) async {
      for (final rota in [
        '/enviar-proposta/a%24b',
        '/servico-confirmado/id%20invalido',
        '/conversas/a%2Fb',
      ]) {
        await abrir(tester, rota);
        expect(
          find.text('Não encontrámos esta página'),
          findsOneWidget,
          reason: rota,
        );
      }
    });

    testWidgets(':id válido mas desconhecido abre a view, que trata o caso', (
      tester,
    ) async {
      await abrir(tester, AppRoutes.enviarProposta('zzz'));
      expect(find.text('Enviar proposta'), findsOneWidget);
      expect(find.text('Não encontrado'), findsOneWidget);
      await abrir(tester, AppRoutes.servicoConfirmado('zzz'));
      expect(find.text('Não encontrado'), findsOneWidget);
      await abrir(tester, AppRoutes.conversa('zzz'));
      expect(find.text('Não encontrado'), findsOneWidget);
    });

    testWidgets('abrem sem a barra inferior (navigator raiz)', (tester) async {
      for (final rota in [
        AppRoutes.codigoSms,
        AppRoutes.registoProfissional,
        AppRoutes.verificarIdentidade,
        AppRoutes.enviarProposta('pp1'),
        AppRoutes.servicoConfirmado('tp1'),
        AppRoutes.conversa('c1'),
        AppRoutes.categorias,
        AppRoutes.mapa,
      ]) {
        await abrir(tester, rota);
        expect(find.byType(KBottomNavBar), findsNothing, reason: rota);
      }
    });

    testWidgets('as abas Conversas e Perfil têm a barra inferior', (
      tester,
    ) async {
      for (final rota in [AppRoutes.conversas, AppRoutes.perfil]) {
        await abrir(tester, rota);
        expect(find.byType(KBottomNavBar), findsOneWidget, reason: rota);
      }
    });

    test('AppRoutes constrói e codifica os novos caminhos', () {
      expect(AppRoutes.enviarProposta('pp 1'), '/enviar-proposta/pp%201');
      expect(AppRoutes.servicoConfirmado('tp1'), '/servico-confirmado/tp1');
      expect(AppRoutes.conversa('c1'), '/conversas/c1');
      expect(AppRoutes.codigoSms, '/codigo-sms');
      expect(AppRoutes.registoProfissional, '/registo-profissional');
      expect(AppRoutes.verificarIdentidade, '/verificar-identidade');
      expect(AppRoutes.categorias, '/categorias');
      expect(AppRoutes.mapa, '/mapa');
    });

    testWidgets('"Ver todos" no Início abre o ecrã 21', (tester) async {
      await abrir(tester, AppRoutes.inicio);
      await tester.tap(find.text('Ver todos'));
      await tester.pumpAndSettle();
      expect(find.text('Todos os serviços'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Voltar'));
      await tester.pumpAndSettle();
      expect(find.text('Perto de si'), findsOneWidget);
    });

    testWidgets('o chip "Mapa" no Início abre o ecrã 22 e "Lista" volta', (
      tester,
    ) async {
      await abrir(tester, AppRoutes.inicio);
      await tester.ensureVisible(find.text('Mapa'));
      await tester.tap(find.text('Mapa'));
      await tester.pumpAndSettle();
      expect(find.text('Lista'), findsOneWidget);
      await tester.tap(find.text('Lista'));
      await tester.pumpAndSettle();
      expect(find.text('Mapa'), findsOneWidget);
    });

    testWidgets('o chip "Mapa" leva ao perfil do profissional via "Ver"', (
      tester,
    ) async {
      await abrir(tester, AppRoutes.mapa);
      await tester.tap(find.text('Ver perfil'));
      await tester.pumpAndSettle();
      expect(find.text('Especialidades'), findsOneWidget);
    });

    testWidgets('uma conversa abre-se a partir da lista e volta a ela', (
      tester,
    ) async {
      await abrir(tester, AppRoutes.conversas);
      await tester.tap(find.text('Joaquim Manuel'));
      await tester.pumpAndSettle();
      expect(find.text('Escreva uma mensagem'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Voltar'));
      await tester.pumpAndSettle();
      expect(find.text('Chego às 15h40, como combinado.'), findsOneWidget);
    });
  });

  group('modo profissional na casca', () {
    Future<MockKisaluRepository> abrirComoProfissional(
      WidgetTester tester,
      String rota,
    ) async {
      final repo = MockKisaluRepository();
      await repo.mudarPerfil(PerfilUtilizador.profissional);
      await tester.pumpWidget(
        Provider<KisaluRepository>.value(
          value: repo,
          child: MaterialApp.router(
            theme: KTheme.light(),
            routerConfig: createRouter(initialLocation: rota),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return repo;
    }

    testWidgets('o separador Início mostra o ecrã 14', (tester) async {
      await abrirComoProfissional(tester, AppRoutes.inicio);
      expect(find.text('Boa tarde, Joaquim'), findsOneWidget);
      expect(find.text('Disponível para trabalhar'), findsOneWidget);
      expect(find.text('Boa tarde, Maria'), findsNothing);
    });

    testWidgets('o separador QR mostra o ecrã 16 e fica sempre ativo', (
      tester,
    ) async {
      await abrirComoProfissional(tester, AppRoutes.qr);
      expect(find.text('Código de confirmação'), findsOneWidget);
      expect(
        find.bySemanticsLabel('QR, confirmar o serviço em curso'),
        findsOneWidget,
      );
    });

    testWidgets('o QR do profissional está ativo mesmo sem serviço em curso', (
      tester,
    ) async {
      final repo = MockKisaluRepository(comServicoEmCurso: false);
      await repo.mudarPerfil(PerfilUtilizador.profissional);
      await tester.pumpWidget(
        Provider<KisaluRepository>.value(
          value: repo,
          child: MaterialApp.router(
            theme: KTheme.light(),
            routerConfig: createRouter(initialLocation: AppRoutes.inicio),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.bySemanticsLabel('QR, confirmar o serviço em curso'),
        findsOneWidget,
      );
    });

    testWidgets('o separador Pedidos mostra os trabalhos do profissional', (
      tester,
    ) async {
      await abrirComoProfissional(tester, AppRoutes.pedidos);
      expect(find.text('Os seus pedidos'), findsOneWidget);
      expect(find.textContaining('Maria K.'), findsOneWidget);
      expect(find.text('Tomada sem luz'), findsNothing);
      expect(find.text('Desentupir pia'), findsOneWidget);
    });

    testWidgets('mudar de perfil no ecrã 20 troca o Início sem reiniciar', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final repo = MockKisaluRepository();
      await tester.pumpWidget(
        Provider<KisaluRepository>.value(
          value: repo,
          child: MaterialApp.router(
            theme: KTheme.light(),
            routerConfig: createRouter(initialLocation: AppRoutes.perfil),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mudar para profissional'));
      await tester.pumpAndSettle();
      expect(find.text('Boa tarde, Joaquim'), findsOneWidget);
      // e de volta a cliente
      await tester.tap(find.text('Perfil'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mudar para cliente'));
      await tester.pumpAndSettle();
      expect(find.text('Boa tarde, Maria'), findsOneWidget);
    });
  });
}
