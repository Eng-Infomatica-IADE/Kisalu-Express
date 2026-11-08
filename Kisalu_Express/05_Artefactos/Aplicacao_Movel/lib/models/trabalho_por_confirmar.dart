import 'json_leitura.dart';

/// Trabalho em curso que o profissional vai confirmar com o código do
/// cliente (ecrã 16): mostra-se antes de confirmar, para se saber o quê.
class TrabalhoPorConfirmar {
  const TrabalhoPorConfirmar({
    required this.pedidoId,
    required this.servico,
    required this.cliente,
    required this.valor,
  });

  /// `GET /pedidos/por-confirmar` → `{pedido_id, servico, cliente, valor}`.
  factory TrabalhoPorConfirmar.fromJson(Map<String, dynamic> j) =>
      TrabalhoPorConfirmar(
        pedidoId: JsonLeitura.id(j['pedido_id']),
        servico: JsonLeitura.texto(j['servico']),
        cliente: JsonLeitura.texto(j['cliente']),
        valor: JsonLeitura.inteiro(j['valor']),
      );

  final String pedidoId;
  final String servico;

  /// Nome curto: "Maria K."
  final String cliente;

  /// Valor combinado, em Kz inteiros.
  final int valor;
}
