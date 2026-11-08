import 'json_leitura.dart';

/// Serviço confirmado pelo profissional com o código do cliente (ecrã 17).
class ServicoConfirmado {
  const ServicoConfirmado({
    required this.pedidoId,
    required this.servico,
    required this.cliente,
    required this.valor,
    required this.data,
  });

  /// Lido do ComprovativoJSON (confirmar e `GET /pedidos/:id/comprovativo`).
  factory ServicoConfirmado.fromJson(Map<String, dynamic> j) =>
      ServicoConfirmado(
        pedidoId: JsonLeitura.id(j['pedido_id']),
        servico: JsonLeitura.texto(j['titulo']),
        cliente: JsonLeitura.texto(j['cliente_curto']),
        valor: JsonLeitura.inteiro(j['valor_kz']),
        data: JsonLeitura.data(j['confirmado_em']),
      );

  final String pedidoId;
  final String servico;

  /// Nome curto: "Maria K."
  final String cliente;

  /// Valor combinado, em Kz inteiros.
  final int valor;
  final DateTime data;
}
