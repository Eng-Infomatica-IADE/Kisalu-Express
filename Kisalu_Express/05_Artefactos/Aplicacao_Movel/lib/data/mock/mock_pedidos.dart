import '../../models/categoria.dart';
import '../../models/comprovativo.dart';
import '../../models/estado_pedido.dart';
import '../../models/pedido.dart';
import '../../models/proposta.dart';
import 'mock_profissionais.dart';
import 'mock_sessao.dart';

/// Pedidos, propostas e comprovativos fictícios (ecrãs 04 a 08).
///
/// O pedido `ped1` aparece em dois estados porque a spec mostra os dois: no
/// histórico (07) "EM CURSO" e no detalhe (04) "NOVO · 3 PROPOSTAS". O mock
/// mantém os dois registos e `aceitarProposta` leva o detalhe a "em curso".
abstract final class MockPedidos {
  static final _agora = MockSessao.agora;

  static DateTime _hoje(int hora, [int minuto = 0]) =>
      DateTime(_agora.year, _agora.month, _agora.day, hora, minuto);

  static const _fuga = 'Fuga de água na cozinha';

  /// As 3 propostas do ecrã 04 (por preço crescente, como no Figma).
  static final propostasFuga = <Proposta>[
    Proposta(
      id: 'pr1',
      profissional: MockProfissionais.joaquim,
      valor: 12500,
      inclui: const [
        ComponenteProposta.maoDeObra,
        ComponenteProposta.material,
        ComponenteProposta.deslocacao,
      ],
      materialDetalhe: 'sifão e vedante',
      nomeNoCartao: 'Joaquim M.',
      chegadaPrevista: _hoje(15, 40),
    ),
    Proposta(
      id: 'pr2',
      profissional: MockProfissionais.rui,
      valor: 15000,
      inclui: const [
        ComponenteProposta.maoDeObra,
        ComponenteProposta.deslocacao,
      ],
      chegadaPrevista: _hoje(16),
    ),
    Proposta(
      id: 'pr3',
      profissional: MockProfissionais.paulo,
      valor: 18500,
      inclui: const [
        ComponenteProposta.maoDeObra,
        ComponenteProposta.material,
        ComponenteProposta.deslocacao,
      ],
      chegadaPrevista: _hoje(15, 25),
    ),
  ];

  /// Detalhe do ecrã 04: NOVO · 3 PROPOSTAS.
  static final ped1Novo = Pedido(
    id: 'ped1',
    titulo: _fuga,
    tituloResumo: 'Fuga de água',
    categoriaId: CategoriaId.canalizador,
    estado: EstadoPedido.novo,
    data: _agora,
    descricao:
        'Cano a pingar debaixo do lava-loiça. Precisa de reparação hoje.',
    zona: 'Talatona',
    pontoReferencia: 'perto da cantina do Sr. Zé',
    quando: _hoje(16),
    propostas: propostasFuga,
    numFotos: 1,
  );

  /// `ped1` em curso: histórico (07) e serviço dos ecrãs 05 e 06.
  static final ped1EmCurso = Pedido(
    id: 'ped1',
    titulo: _fuga,
    tituloResumo: 'Fuga de água',
    categoriaId: CategoriaId.canalizador,
    estado: EstadoPedido.emCurso,
    data: _agora,
    zona: 'Talatona',
    quando: _hoje(16),
    profissional: MockProfissionais.joaquim,
    valor: 12500,
    propostaAceitaId: 'pr1',
    numFotos: 1,
    etapa: EtapaServico.aCaminho,
    conversaId: 'c1',
    propostas: [propostasFuga.first],
  );

  /// Histórico do ecrã 07 (mais recentes primeiro).
  static final historico = <Pedido>[
    ped1EmCurso,
    Pedido(
      id: 'ped2',
      titulo: 'Tomada sem luz',
      categoriaId: CategoriaId.eletricista,
      estado: EstadoPedido.concluido,
      data: DateTime(2026, 9, 24, 10),
      profissional: MockProfissionais.carlos,
      valor: 6000,
      podeReclamar: true,
    ),
    Pedido(
      id: 'ped3',
      titulo: 'Limpeza de AC',
      categoriaId: CategoriaId.arCond,
      estado: EstadoPedido.concluido,
      data: DateTime(2026, 9, 12, 10),
      profissional: MockProfissionais.nuno,
      valor: 9500,
      avaliado: true,
    ),
    Pedido(
      id: 'ped4',
      titulo: 'Pastilhas de travão',
      categoriaId: CategoriaId.mecanico,
      estado: EstadoPedido.cancelado,
      data: DateTime(2026, 9, 3, 10),
      profissional: MockProfissionais.helder,
      valor: 15000,
    ),
    Pedido(
      id: 'ped5',
      titulo: 'Tranças',
      categoriaId: CategoriaId.cabeleireira,
      estado: EstadoPedido.concluido,
      data: DateTime(2026, 8, 28, 10),
      profissional: MockProfissionais.ana,
      valor: 20000,
      avaliado: true,
    ),
  ];

  /// Trabalhos do profissional (separador Pedidos em modo profissional).
  /// Dados inventados; o primeiro é o serviço que o ecrã 16 confirma.
  static final historicoProfissional = <Pedido>[
    Pedido(
      id: 'tp1',
      titulo: _fuga,
      tituloResumo: 'Fuga de água',
      categoriaId: CategoriaId.canalizador,
      estado: EstadoPedido.emCurso,
      data: _agora,
      zona: 'Talatona',
      valor: 12500,
      cliente: 'Maria K.',
      etapa: EtapaServico.aceite,
      morada: 'Rua 21, casa 14, Talatona',
      pontoReferencia: 'perto da cantina do Sr. Zé',
      clienteNome: 'Maria Kiala',
      clienteTelemovel: '+244923000000',
      conversaId: 'c1',
    ),
    Pedido(
      id: 'tp2',
      titulo: 'Desentupir pia',
      categoriaId: CategoriaId.canalizador,
      estado: EstadoPedido.concluido,
      data: DateTime(2026, 9, 24, 10),
      valor: 8500,
      cliente: 'Pedro K.',
    ),
    Pedido(
      id: 'tp3',
      titulo: 'Trocar esquentador',
      categoriaId: CategoriaId.canalizador,
      estado: EstadoPedido.concluido,
      data: DateTime(2026, 9, 12, 10),
      valor: 18000,
      cliente: 'Ana P.',
    ),
    Pedido(
      id: 'tp4',
      titulo: 'Torneira a pingar',
      categoriaId: CategoriaId.canalizador,
      estado: EstadoPedido.cancelado,
      data: DateTime(2026, 9, 3, 10),
      valor: 5000,
      cliente: 'Rui B.',
    ),
  ];

  /// Comprovativos por id de pedido (o cancelado não tem). O de `ped1` existe
  /// para o ecrã 06 poder abrir diretamente na galeria.
  static final comprovativos = <String, Comprovativo>{
    'ped1': Comprovativo(
      referencia: 'KX-482173',
      pedidoId: 'ped1',
      servico: _fuga,
      profissional: MockProfissionais.joaquim,
      valor: 12500,
      data: _agora,
      pagamento: MeioPagamento.dinheiro,
    ),
    'ped2': Comprovativo(
      referencia: 'KX-301854',
      pedidoId: 'ped2',
      servico: 'Tomada sem luz',
      profissional: MockProfissionais.carlos,
      valor: 6000,
      data: DateTime(2026, 9, 24, 10),
      pagamento: MeioPagamento.dinheiro,
    ),
    'ped3': Comprovativo(
      referencia: 'KX-297316',
      pedidoId: 'ped3',
      servico: 'Limpeza de AC',
      profissional: MockProfissionais.nuno,
      valor: 9500,
      data: DateTime(2026, 9, 12, 10),
      pagamento: MeioPagamento.dinheiro,
    ),
    'ped5': Comprovativo(
      referencia: 'KX-188240',
      pedidoId: 'ped5',
      servico: 'Tranças',
      profissional: MockProfissionais.ana,
      valor: 20000,
      data: DateTime(2026, 8, 28, 10),
      pagamento: MeioPagamento.dinheiro,
    ),
  };
}
