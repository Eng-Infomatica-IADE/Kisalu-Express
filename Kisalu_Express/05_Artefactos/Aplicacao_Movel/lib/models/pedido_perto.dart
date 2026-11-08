import 'json_leitura.dart';

/// Pedido de um cliente visto pelo profissional (ecrãs 14 e 15). Só tem a
/// zona e a distância: nunca a morada nem o contacto do cliente (RNF10).
class PedidoPerto {
  const PedidoPerto({
    required this.id,
    required this.titulo,
    required this.categoriaId,
    required this.zona,
    required this.distanciaKm,
    this.quando,
    required this.publicadoEm,
    this.descricao = '',
    this.novo = false,
  });

  /// PedidoPertoJSON, ou o PedidoJSON de `GET /pedidos/:id` visto pelo
  /// profissional (sem `publicado_em`: usa-se `criado_em`).
  factory PedidoPerto.fromJson(Map<String, dynamic> j) => PedidoPerto(
    id: JsonLeitura.id(j['id']),
    titulo: JsonLeitura.texto(j['titulo']),
    categoriaId: JsonLeitura.texto(j['categoria_chave']),
    descricao: JsonLeitura.texto(j['descricao']),
    zona: JsonLeitura.texto(j['zona']),
    distanciaKm: JsonLeitura.decimal(j['distancia_km']),
    quando: JsonLeitura.dataOuNull(j['data_pretendida']),
    publicadoEm: JsonLeitura.data(j['publicado_em'] ?? j['criado_em']),
    novo: JsonLeitura.booleano(j['novo']),
  );

  final String id;
  final String titulo;

  /// Uma das chaves de `CategoriaId`.
  final String categoriaId;
  final String descricao;

  /// "Talatona"
  final String zona;
  final double distanciaKm;

  /// Quando o cliente precisa do serviço; null = o mais cedo possível.
  final DateTime? quando;

  /// Quando foi publicado ("há 22 min").
  final DateTime publicadoEm;

  /// Ainda não visto: mostra a etiqueta NOVO.
  final bool novo;
}
