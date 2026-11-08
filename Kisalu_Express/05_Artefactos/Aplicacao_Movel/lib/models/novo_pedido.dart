import 'json_leitura.dart';
import 'pedido.dart';

/// Rascunho / pedido a publicar (fluxo "Novo pedido", ecrã 10). O servidor
/// revalida tudo (VALIDACOES.md).
class NovoPedido {
  const NovoPedido({
    required this.categoriaId,
    required this.titulo,
    required this.descricao,
    required this.zona,
    required this.pontoReferencia,
    this.quando,
    this.numFotos = 0,
    this.rascunhoId,
  });

  /// Rascunho guardado no aparelho ([paraArmazenar]); null se ilegível.
  static NovoPedido? doArmazenado(Map<String, dynamic> j) {
    final categoria = JsonLeitura.texto(j['categoria']);
    if (categoria.isEmpty) return null;
    return NovoPedido(
      categoriaId: categoria,
      titulo: JsonLeitura.texto(j['titulo']),
      descricao: JsonLeitura.texto(j['descricao']),
      zona: JsonLeitura.texto(j['zona']),
      pontoReferencia: JsonLeitura.texto(j['ponto_referencia']),
      quando: JsonLeitura.dataOuNull(j['quando']),
      numFotos: JsonLeitura.inteiro(j['num_fotos']),
    );
  }

  final String categoriaId;
  final String titulo;
  final String descricao;

  /// Zona aproximada: "Talatona".
  final String zona;

  /// "perto da cantina do Sr. Zé" — fica oculto até aceitar (RNF10).
  final String pontoReferencia;

  /// null = "o mais cedo possível".
  final DateTime? quando;
  final int numFotos;

  /// Rascunho já criado no servidor por "Pedir de novo": publicar muda-o e
  /// publica-o em vez de criar outro pedido.
  final String? rascunhoId;

  /// Rascunho local (RM07): só o que o formulário precisa para retomar.
  Map<String, dynamic> paraArmazenar() => {
    'categoria': categoriaId,
    'titulo': titulo,
    'descricao': descricao,
    'zona': zona,
    'ponto_referencia': pontoReferencia,
    'quando': quando?.toUtc().toIso8601String(),
    'num_fotos': numFotos,
  };

  /// Corpo de `PATCH /pedidos/:id`: o mesmo formato do `POST`, sem
  /// `publicar` (CONTRATO-API.md, secção 6). `quando: null` = o mais cedo
  /// possível.
  Map<String, dynamic> paraEditar() => {
    'categoria_chave': categoriaId,
    'titulo': titulo,
    'descricao': descricao,
    'zona': zona,
    'ponto_referencia': pontoReferencia,
    'quando': quando?.toUtc().toIso8601String(),
  };

  /// Corpo de `POST /pedidos` (publica logo).
  Map<String, dynamic> toJson() => {
    'categoria_chave': categoriaId,
    'titulo': titulo,
    'descricao': descricao,
    'zona': zona,
    'ponto_referencia': pontoReferencia,
    'quando': quando?.toUtc().toIso8601String(),
    'publicar': true,
  };
}

/// Resultado de publicar um pedido.
class PedidoPublicado {
  const PedidoPublicado({
    required this.pedido,
    required this.profissionaisAvisados,
    required this.categoriaPlural,
  });

  /// `{id, estado, pedido, profissionais_avisados, categoria_plural}`.
  factory PedidoPublicado.fromJson(Map<String, dynamic> j) {
    final plural = JsonLeitura.texto(j['categoria_plural']);
    return PedidoPublicado(
      pedido: Pedido.fromJson(JsonLeitura.mapa(j['pedido'])),
      profissionaisAvisados: JsonLeitura.inteiro(j['profissionais_avisados']),
      categoriaPlural: plural.isEmpty ? 'profissionais' : plural,
    );
  }

  final Pedido pedido;

  /// "Já avisámos 8 canalizadores perto de si."
  final int profissionaisAvisados;

  /// "canalizadores"
  final String categoriaPlural;
}
