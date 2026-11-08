import 'json_leitura.dart';

/// Pergunta frequente da Ajuda (RF16).
class PerguntaAjuda {
  const PerguntaAjuda({
    required this.id,
    required this.pergunta,
    required this.resposta,
    this.tema = '',
  });

  /// `GET /ajuda/perguntas` → `[{id, tema, pergunta, resposta}]`.
  factory PerguntaAjuda.fromJson(Map<String, dynamic> j) => PerguntaAjuda(
    id: JsonLeitura.id(j['id']),
    tema: JsonLeitura.texto(j['tema']),
    pergunta: JsonLeitura.texto(j['pergunta']),
    resposta: JsonLeitura.texto(j['resposta']),
  );

  final String id;
  final String tema;
  final String pergunta;
  final String resposta;
}
