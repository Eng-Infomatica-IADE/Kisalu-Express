import 'estado_pedido.dart';
import 'json_leitura.dart';
import 'profissional.dart';
import 'proposta.dart';

/// Pedido de serviço publicado pelo cliente (RF03).
///
/// Não guarda a morada exata nem o ponto de referência: só seguem depois de
/// aceitar (RNF10). O código de confirmação também não vive aqui (ver
/// `CodigoConfirmacao`): existe só em memória no ecrã 05.
class Pedido {
  const Pedido({
    required this.id,
    required this.titulo,
    required this.categoriaId,
    required this.estado,
    required this.data,
    this.tituloResumo,
    this.descricao = '',
    this.zona = '',
    this.quando,
    this.profissional,
    this.valor,
    this.propostas = const [],
    this.propostaAceitaId,
    this.numFotos = 0,
    this.cliente,
    this.etapa,
    this.avaliado = false,
    this.podeReclamar = false,
    this.morada,
    this.pontoReferencia,
    this.clienteNome,
    this.clienteTelemovel,
    this.conversaId,
    this.aceiteEm,
  });

  /// PedidoJSON. Na lista, `propostas` vem vazio.
  ///
  /// O detalhe (`GET /pedidos/:id`) junta `contacto_cliente`, `morada`,
  /// `cliente` e `conversa_id`; a morada exata e o telemóvel só chegam a
  /// quem tem a proposta aceite (RNF10). Aceita também os campos soltos
  /// (`ponto_referencia`, `cliente_telemovel`).
  factory Pedido.fromJson(Map<String, dynamic> j) {
    final profissional = JsonLeitura.mapaOuNull(j['profissional']);
    final morada = JsonLeitura.mapaOuNull(j['morada']);
    final cliente = JsonLeitura.mapaOuNull(j['cliente']);
    final garantia = JsonLeitura.mapaOuNull(j['garantia']);
    final acordo = JsonLeitura.mapaOuNull(j['acordo']);
    // Só para o profissional da proposta aceite (RNF10).
    final contacto = JsonLeitura.mapaOuNull(j['contacto_cliente']);
    final estado = EstadoPedido.doServidor(j['estado']);
    String? textoCheio(Object? v) {
      final t = JsonLeitura.textoOuNull(v)?.trim();
      return t == null || t.isEmpty ? null : t;
    }

    return Pedido(
      id: JsonLeitura.id(j['id']),
      titulo: JsonLeitura.texto(j['titulo']),
      categoriaId: JsonLeitura.texto(j['categoria_chave']),
      estado: estado,
      data: JsonLeitura.data(j['criado_em']),
      descricao: JsonLeitura.texto(j['descricao']),
      zona: JsonLeitura.texto(j['zona']),
      quando: JsonLeitura.dataOuNull(j['data_pretendida']),
      profissional: profissional == null
          ? null
          : Profissional.fromJson(profissional),
      valor: JsonLeitura.inteiroOuNull(j['valor_acordado']),
      propostas: JsonLeitura.lista(j['propostas'], Proposta.fromJson),
      propostaAceitaId: JsonLeitura.idOuNull(j['proposta_aceite_id']),
      numFotos: JsonLeitura.inteiro(j['num_fotos']),
      cliente: JsonLeitura.textoOuNull(j['cliente_curto']),
      etapa: EtapaServico.doServidor(j['estado']),
      avaliado: JsonLeitura.booleano(j['avaliado']),
      // Sem o campo, vale a garantia de 7 dias do detalhe (RF11).
      podeReclamar: j.containsKey('pode_reclamar')
          ? JsonLeitura.booleano(j['pode_reclamar'])
          : estado == EstadoPedido.concluido &&
                JsonLeitura.booleano(garantia?['ativa']),
      morada: textoCheio(
        contacto?['morada'] ?? morada?['endereco'] ?? j['endereco'],
      ),
      pontoReferencia: textoCheio(
        contacto?['ponto_referencia'] ??
            morada?['ponto_referencia'] ??
            j['ponto_referencia'],
      ),
      clienteNome: textoCheio(
        contacto?['nome'] ?? cliente?['nome'] ?? j['cliente_nome'],
      ),
      clienteTelemovel: textoCheio(
        contacto?['telemovel'] ??
            cliente?['telemovel'] ??
            j['cliente_telemovel'],
      ),
      conversaId: JsonLeitura.idOuNull(j['conversa_id']),
      aceiteEm: JsonLeitura.dataOuNull(acordo?['aceite_em'] ?? j['aceite_em']),
    );
  }

  final String id;
  final String titulo;

  /// Título curto usado nas listas ("Fuga de água"); se null usa [titulo].
  final String? tituloResumo;

  /// Uma das chaves de `CategoriaId`.
  final String categoriaId;
  final EstadoPedido estado;

  /// Quando o pedido foi feito (histórico: "Hoje", "24 set").
  final DateTime data;
  final String descricao;

  /// Zona aproximada: "Talatona".
  final String zona;

  /// Quando o cliente precisa do serviço; null = o mais cedo possível.
  final DateTime? quando;

  /// Profissional da proposta aceite.
  final Profissional? profissional;

  /// Valor fechado da proposta aceite, em Kz inteiros.
  final int? valor;
  final List<Proposta> propostas;
  final String? propostaAceitaId;
  final int numFotos;

  /// Nome curto do cliente ("Maria K."), só nos trabalhos do profissional.
  final String? cliente;

  /// Etapa do serviço aceite (aceite, a caminho, começado); null nos
  /// outros estados.
  final EtapaServico? etapa;

  /// O cliente já avaliou o serviço (RF12).
  final bool avaliado;

  /// Ainda se pode reportar um problema (garantia de 7 dias, RF11).
  final bool podeReclamar;

  /// Morada exata e ponto de referência: só para o profissional com a
  /// proposta aceite (e para o próprio cliente).
  final String? morada;
  final String? pontoReferencia;

  /// Nome completo e telemóvel do cliente (detalhe do trabalho, RF08).
  final String? clienteNome;
  final String? clienteTelemovel;

  /// Conversa do pedido com o profissional escolhido; null se não há.
  final String? conversaId;

  /// Quando a proposta foi aceite (a API deixa desfazer durante 5 min).
  final DateTime? aceiteEm;

  String get tituloNaLista => tituloResumo ?? titulo;

  /// Proposta aceite (está em [propostas] no detalhe); null se não há.
  Proposta? get propostaAceite => propostaAceitaId == null
      ? null
      : propostas.where((p) => p.id == propostaAceitaId).firstOrNull;

  Pedido copyWith({
    EstadoPedido? estado,
    Profissional? profissional,
    int? valor,
    String? propostaAceitaId,
    bool limparAceitacao = false,
    List<Proposta>? propostas,
    EtapaServico? etapa,
    bool? avaliado,
    DateTime? aceiteEm,
  }) => Pedido(
    id: id,
    titulo: titulo,
    tituloResumo: tituloResumo,
    categoriaId: categoriaId,
    estado: estado ?? this.estado,
    data: data,
    descricao: descricao,
    zona: zona,
    quando: quando,
    profissional: limparAceitacao ? null : (profissional ?? this.profissional),
    valor: limparAceitacao ? null : (valor ?? this.valor),
    propostas: propostas ?? this.propostas,
    propostaAceitaId: limparAceitacao
        ? null
        : (propostaAceitaId ?? this.propostaAceitaId),
    numFotos: numFotos,
    cliente: cliente,
    etapa: limparAceitacao ? null : (etapa ?? this.etapa),
    avaliado: avaliado ?? this.avaliado,
    podeReclamar: podeReclamar,
    morada: morada,
    pontoReferencia: pontoReferencia,
    clienteNome: clienteNome,
    clienteTelemovel: clienteTelemovel,
    conversaId: conversaId,
    aceiteEm: limparAceitacao ? null : (aceiteEm ?? this.aceiteEm),
  );
}
