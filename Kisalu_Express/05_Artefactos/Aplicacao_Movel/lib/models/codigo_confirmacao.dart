import 'json_leitura.dart';

/// Conteúdo do ecrã 05, devolvido pelo servidor. Vive só em memória: nunca
/// vai para cache, `toJson`, logs nem área de transferência (SEGURANCA.md).
class CodigoConfirmacao {
  const CodigoConfirmacao({
    required this.pedidoId,
    required this.token,
    required this.codigo,
    required this.validoAte,
  });

  /// `GET /pedidos/:id/qr`.
  factory CodigoConfirmacao.fromJson(Map<String, dynamic> j) =>
      CodigoConfirmacao(
        pedidoId: JsonLeitura.id(j['pedido_id']),
        token: JsonLeitura.texto(j['token']),
        codigo: JsonLeitura.texto(j['codigo']),
        validoAte: JsonLeitura.data(j['valido_ate']),
      );

  final String pedidoId;

  /// Conteúdo do QR: texto opaco, sem significado para a app. Nunca abrir
  /// como URL nem derivar dele o id ou o código.
  final String token;

  /// Código alternativo de 6 dígitos ("482173"); mostrar com `KFormat.codigo`.
  final String codigo;
  final DateTime validoAte;
}
