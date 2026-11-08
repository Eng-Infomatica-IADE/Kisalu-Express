import 'json_leitura.dart';
import 'profissional.dart';

/// Como o cliente pagou o serviço.
enum MeioPagamento {
  dinheiro('Dinheiro', 'dinheiro'),
  multicaixaExpress('Multicaixa Express', 'multicaixa_express'),
  transferencia('Transferência', 'transferencia');

  const MeioPagamento(this.rotulo, this.chave);

  final String rotulo;

  /// Valor de `metodo_pagamento` na API.
  final String chave;

  /// Chave desconhecida ou em falta → [dinheiro].
  static MeioPagamento daChave(Object? chave) =>
      values.where((m) => m.chave == chave).firstOrNull ?? dinheiro;
}

/// Comprovativo de um serviço confirmado (ecrãs 06 e 07, RF17).
/// O valor vem sempre da proposta aceite, nunca do cliente (SEGURANCA.md).
class Comprovativo {
  const Comprovativo({
    required this.referencia,
    required this.pedidoId,
    required this.servico,
    required this.profissional,
    required this.valor,
    required this.data,
    required this.pagamento,
  });

  /// ComprovativoJSON (`GET /pedidos/:id/comprovativo`).
  factory Comprovativo.fromJson(Map<String, dynamic> j) => Comprovativo(
    referencia: JsonLeitura.texto(j['numero_comprovativo']),
    pedidoId: JsonLeitura.id(j['pedido_id']),
    servico: JsonLeitura.texto(j['titulo']),
    profissional: Profissional.fromJson(JsonLeitura.mapa(j['profissional'])),
    valor: JsonLeitura.inteiro(j['valor_kz']),
    data: JsonLeitura.data(j['confirmado_em']),
    pagamento: MeioPagamento.daChave(j['metodo_pagamento']),
  );

  /// "KX-482173"
  final String referencia;
  final String pedidoId;

  /// Título do pedido: "Fuga de água na cozinha".
  final String servico;
  final Profissional profissional;

  /// Kz, inteiro.
  final int valor;
  final DateTime data;
  final MeioPagamento pagamento;
}
