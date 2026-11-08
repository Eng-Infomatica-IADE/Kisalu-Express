import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kisalu_express/core/state/estado_ui.dart';
import 'package:kisalu_express/data/repositories/mock_kisalu_repository.dart';
import 'package:kisalu_express/features/pedidos/controllers/confirmar_proposta_controller.dart';
import 'package:kisalu_express/features/pedidos/controllers/pedido_detalhe_controller.dart';
import 'package:kisalu_express/models/estado_pedido.dart';
import 'package:kisalu_express/models/estimativa_chegada.dart';
import 'package:kisalu_express/models/ordenacao_propostas.dart';
import 'package:kisalu_express/models/proposta.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  test('carrega o pedido e ordena por preço por omissão', () async {
    final c = PedidoDetalheController(MockKisaluRepository(), 'ped1');
    expect(c.estado, isA<Carregar<dynamic>>());
    await c.carregar();
    expect(c.estado, isA<Sucesso<dynamic>>());
    expect(c.propostas.map((p) => p.id), ['pr1', 'pr2', 'pr3']);
    expect(c.podeAceitar, isTrue);
  });

  test('ordena por avaliação e por chegada', () async {
    final c = PedidoDetalheController(MockKisaluRepository(), 'ped1');
    await c.carregar();
    c.ordenar(OrdenacaoPropostas.chegada);
    expect(c.propostas.first.id, 'pr3');
    c.ordenar(OrdenacaoPropostas.avaliacao);
    expect(c.propostas.first.profissional.rating, greaterThanOrEqualTo(4.6));
  });

  test('pedido desconhecido dá erro "não encontrado"', () async {
    final c = PedidoDetalheController(MockKisaluRepository(), 'xyz');
    await c.carregar();
    expect((c.estado as Erro<dynamic>).naoEncontrado, isTrue);
  });

  test('aceitar e desfazer', () async {
    final repo = MockKisaluRepository();
    final c = PedidoDetalheController(repo, 'ped1');
    await c.carregar();
    final conf = ConfirmarPropostaController(repo, 'ped1', c.propostas.first);
    final aceite = await conf.confirmar();
    expect(aceite!.estado, EstadoPedido.emCurso);
    expect(aceite.valor, 12500);
    c.aoAceitar(aceite);
    expect(c.podeAceitar, isFalse);
    expect(await c.desfazerAceitacao(), isNull);
    expect(c.podeAceitar, isTrue);
  });

  test('confirmar uma proposta indisponível mostra a mensagem', () async {
    final repo = MockKisaluRepository();
    final c = PedidoDetalheController(repo, 'ped1');
    await c.carregar();
    final conf = ConfirmarPropostaController(repo, 'ped1', c.propostas.first);
    await conf.confirmar();
    expect(await conf.confirmar(), isNull);
    expect(
      conf.erro,
      'Esta proposta já não está disponível. Veja as outras propostas.',
    );
  });

  test('cancelar devolve null e depois erro do catálogo', () async {
    final c = PedidoDetalheController(MockKisaluRepository(), 'ped1');
    await c.carregar();
    expect(await c.cancelar(), isNull);
    expect(await c.cancelar(), 'Já não é possível cancelar este pedido.');
  });

  test('as propostas trazem a estimativa de chegada (Monte Carlo)', () async {
    final c = PedidoDetalheController(MockKisaluRepository(), 'ped1');
    await c.carregar();
    final pr3 = c.propostas.firstWhere((p) => p.id == 'pr3');
    expect(pr3.estimativaChegada!.simulacoes, 10000);
    expect(pr3.estimativaChegada!.percentagemCumprir, 60); // 0,576 → ~60 %
  });

  test('"Chegada" desempata pela mediana simulada (p50)', () async {
    final c = PedidoDetalheController(MockKisaluRepository(), 'ped1');
    await c.carregar();
    final base = c.propostas.first;
    Proposta com(String id, double p50) => Proposta(
      id: id,
      profissional: base.profissional,
      valor: base.valor,
      inclui: base.inclui,
      chegadaPrevista: base.chegadaPrevista,
      estimativaChegada: EstimativaChegada(
        simulacoes: 10000,
        mediaMin: p50,
        p50Min: p50,
        p90Min: p50 * 2,
        probCumprir: 0.9,
      ),
    );
    final ordenadas = OrdenacaoPropostas.chegada.ordenar([
      com('lenta', 30),
      com('rapida', 12),
    ]);
    expect(ordenadas.map((p) => p.id), ['rapida', 'lenta']);
  });
}
