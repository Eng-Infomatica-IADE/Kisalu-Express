import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kisalu_express/core/state/estado_ui.dart';
import 'package:kisalu_express/core/widgets/widgets.dart';
import 'package:kisalu_express/data/repositories/kisalu_repository.dart';
import 'package:kisalu_express/data/repositories/mock_kisalu_repository.dart';
import 'package:kisalu_express/features/ajuda/controllers/ajuda_controller.dart';
import 'package:kisalu_express/features/ajuda/views/ajuda_view.dart';
import 'package:kisalu_express/features/confirmacao_profissional/views/ler_qr_view.dart';
import 'package:kisalu_express/features/conversas/views/conversa_view.dart';
import 'package:kisalu_express/features/notificacoes/controllers/notificacoes_controller.dart';
import 'package:kisalu_express/features/notificacoes/views/notificacoes_view.dart';
import 'package:kisalu_express/features/novo_pedido/views/novo_pedido_view.dart';
import 'package:kisalu_express/features/pedidos/widgets/historico_comprovativo_folha.dart';
import 'package:kisalu_express/models/conversa.dart';
import 'package:kisalu_express/models/notificacao.dart';
import 'package:kisalu_express/models/pergunta_ajuda.dart';
import 'package:kisalu_express/models/trabalho_por_confirmar.dart';
import 'package:kisalu_express/models/utilizador.dart';

import '../helpers/ecra_apoio.dart';
import '../helpers/montar_widget.dart';

/// Ecrãs e ações acrescentados depois do QA (Entrega 2b): notificações,
/// ajuda, vários trabalhos no 16, conversa sem valor, editar pedido e o
/// recarregar ao voltar a um separador.

class _SemNotificacoes extends MockKisaluRepository {
  @override
  Future<CaixaNotificacoes> notificacoes() async =>
      const CaixaNotificacoes(naoLidas: 0, lista: []);
}

class _AjudaSemRede extends MockKisaluRepository {
  @override
  Future<List<PerguntaAjuda>> perguntasAjuda() =>
      throw const SemRedeException();
}

class _DoisTrabalhos extends MockKisaluRepository {
  @override
  Future<List<TrabalhoPorConfirmar>> trabalhosPorConfirmar() async => const [
    TrabalhoPorConfirmar(
      pedidoId: 'tp1',
      servico: 'Fuga de água',
      cliente: 'Maria K.',
      valor: 12500,
    ),
    TrabalhoPorConfirmar(
      pedidoId: 'tp9',
      servico: 'Trocar torneira',
      cliente: 'Rui B.',
      valor: 7000,
    ),
  ];
}

class _ConversaSemValor extends MockKisaluRepository {
  @override
  Future<Conversa?> conversa(String id) async {
    final c = (await super.conversa(id))!;
    return Conversa(
      id: c.id,
      interlocutor: c.interlocutor,
      pedidoTitulo: c.pedidoTitulo,
      categoriaId: c.categoriaId,
      valor: null,
      mensagens: c.mensagens,
    );
  }
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('Notificações (F17)', () {
    test('carrega e marca como lidas', () async {
      final repo = MockKisaluRepository();
      expect(await repo.notificacoesPorLer(), 2);
      final c = NotificacoesController(repo);
      await c.carregar();
      expect((c.estado as Sucesso<List<Notificacao>>).dados, hasLength(3));
      expect(await repo.notificacoesPorLer(), 0);
      c.dispose();
    });

    testWidgets('lista com "Nova" nas que estavam por ler', (t) async {
      await montarEcra(t, const NotificacoesView(), comScaffold: false);
      expect(find.text('Notificações'), findsOneWidget);
      expect(find.text('O profissional está a caminho'), findsOneWidget);
      expect(find.text('NOVA'), findsNWidgets(2));
      expect(find.text('Hoje'), findsNWidgets(2));
    });

    testWidgets('sem notificações mostra o estado vazio', (t) async {
      await montarEcra(
        t,
        const NotificacoesView(),
        repo: _SemNotificacoes(),
        comScaffold: false,
      );
      expect(find.text('Sem notificações'), findsOneWidget);
    });
  });

  group('Ajuda (F18)', () {
    test('erro de rede dá Erro', () async {
      final c = AjudaController(_AjudaSemRede());
      await c.carregar();
      expect(c.estado, isA<Erro<List<PerguntaAjuda>>>());
      c.dispose();
    });

    testWidgets('perguntas expandem e mostram a resposta', (t) async {
      await montarEcra(t, const AjudaView(), comScaffold: false);
      expect(find.text('Perguntas frequentes'), findsOneWidget);
      expect(find.text('Como faço um pedido?'), findsOneWidget);
      expect(find.textContaining('preço fechado'), findsNothing);
      await t.tap(find.text('Como faço um pedido?'));
      await t.pumpAndSettle();
      expect(find.textContaining('preço fechado'), findsOneWidget);
    });

    testWidgets('sem overflow com texto a 200 %', (t) async {
      await montarEcra(t, const AjudaView(), escala: 2, comScaffold: false);
      expect(t.takeException(), isNull);
    });
  });

  testWidgets('16 com vários trabalhos lista-os (F6)', (t) async {
    final repo = _DoisTrabalhos();
    await repo.mudarPerfil(PerfilUtilizador.profissional);
    await montarEcra(t, const LerQrView(), repo: repo);
    expect(
      find.text(
        'Tem 2 trabalhos por confirmar. O código do cliente diz qual é.',
      ),
      findsOneWidget,
    );
    expect(find.text('Trocar torneira · Rui B. · 7.000 Kz'), findsOneWidget);
  });

  testWidgets('conversa sem valor não mostra "0 Kz" (F16)', (t) async {
    await montarEcra(
      t,
      const ConversaView(conversaId: 'c1'),
      repo: _ConversaSemValor(),
      comScaffold: false,
    );
    expect(find.text('Fuga de água na cozinha'), findsOneWidget);
    expect(find.textContaining('0 Kz'), findsNothing);
  });

  testWidgets('editar pedido: título e botão próprios (F8)', (t) async {
    await montarEcra(
      t,
      const NovoPedidoView(editarId: 'ped1'),
      repo: MockKisaluRepository(semRede: false),
      comScaffold: false,
    );
    expect(find.text('Editar pedido'), findsOneWidget);
    expect(find.text('Fuga de água na cozinha'), findsWidgets);
  });

  testWidgets('comprovativo fora da garantia não oferece reportar (F10)', (
    t,
  ) async {
    final repo = MockKisaluRepository();
    final comprovativo = (await repo.comprovativo('ped3'))!;
    await t.pumpWidget(
      montarWidget(
        HistoricoComprovativoFolha(
          comprovativo: comprovativo,
          onPartilhar: () {},
        ),
      ),
    );
    expect(find.text('Partilhar'), findsOneWidget);
    expect(find.text('Reportar problema'), findsNothing);
  });

  group('KAoVoltar (F2)', () {
    testWidgets('chama ao voltar a ficar visível, não ao abrir', (t) async {
      var chamadas = 0;
      final ativo = ValueNotifier(true);
      await t.pumpWidget(
        ValueListenableBuilder<bool>(
          valueListenable: ativo,
          builder: (_, v, _) => TickerMode(
            enabled: v,
            child: KAoVoltar(
              aoVoltar: () => chamadas++,
              child: const SizedBox(),
            ),
          ),
        ),
      );
      expect(chamadas, 0);
      ativo.value = false;
      await t.pump();
      await t.pump();
      expect(chamadas, 0);
      ativo.value = true;
      await t.pump();
      await t.pump();
      expect(chamadas, 1);
    });
  });

  test('só os dados fictícios estão em modo de demonstração', () {
    final KisaluRepository repo = MockKisaluRepository();
    expect(repo.modoDemonstracao, isTrue);
  });
}
