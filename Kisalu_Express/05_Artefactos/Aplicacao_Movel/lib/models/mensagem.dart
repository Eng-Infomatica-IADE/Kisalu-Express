import 'json_leitura.dart';

/// Mensagem de uma conversa (ecrã 19).
class Mensagem {
  const Mensagem({
    required this.id,
    required this.texto,
    required this.minha,
    required this.enviadaEm,
    this.lida = false,
  });

  /// MensagemJSON.
  factory Mensagem.fromJson(Map<String, dynamic> j) => Mensagem(
    id: JsonLeitura.id(j['id']),
    texto: JsonLeitura.texto(j['texto']),
    minha: JsonLeitura.booleano(j['minha']),
    enviadaEm: JsonLeitura.data(j['enviada_em']),
    lida: JsonLeitura.booleano(j['lida']),
  );

  final String id;
  final String texto;

  /// true → enviada por quem usa a app.
  final bool minha;
  final DateTime enviadaEm;

  /// Só nas minhas: a outra pessoa já a leu ("14:51 · Lida").
  final bool lida;
}
