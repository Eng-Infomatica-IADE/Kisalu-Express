import 'json_leitura.dart';

/// Aviso da app (RF08, RM06): proposta nova, profissional a caminho…
class Notificacao {
  const Notificacao({
    required this.id,
    required this.titulo,
    required this.corpo,
    required this.criadaEm,
    this.lida = false,
    this.pedidoId,
  });

  /// `{id, tipo, titulo, corpo, pedido_id, acao, lida, criado_em}`.
  factory Notificacao.fromJson(Map<String, dynamic> j) => Notificacao(
    id: JsonLeitura.id(j['id']),
    titulo: JsonLeitura.texto(j['titulo']),
    corpo: JsonLeitura.texto(j['corpo']),
    criadaEm: JsonLeitura.data(j['criado_em']),
    lida: JsonLeitura.booleano(j['lida']),
    pedidoId: JsonLeitura.idOuNull(j['pedido_id']),
  );

  final String id;
  final String titulo;
  final String corpo;
  final DateTime criadaEm;
  final bool lida;
  final String? pedidoId;

  Notificacao lidaAgora() => Notificacao(
    id: id,
    titulo: titulo,
    corpo: corpo,
    criadaEm: criadaEm,
    lida: true,
    pedidoId: pedidoId,
  );
}

/// Lista de notificações com o total por ler (ponto vermelho do sino).
class CaixaNotificacoes {
  const CaixaNotificacoes({required this.naoLidas, required this.lista});

  /// `GET /notificacoes` → `{nao_lidas, notificacoes}`.
  factory CaixaNotificacoes.fromJson(Map<String, dynamic> j) =>
      CaixaNotificacoes(
        naoLidas: JsonLeitura.inteiro(j['nao_lidas']),
        lista: JsonLeitura.lista(j['notificacoes'], Notificacao.fromJson),
      );

  final int naoLidas;

  /// Mais recentes primeiro.
  final List<Notificacao> lista;
}
