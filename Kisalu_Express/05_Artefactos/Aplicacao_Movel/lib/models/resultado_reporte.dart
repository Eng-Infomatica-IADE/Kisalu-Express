import 'json_leitura.dart';

/// Resposta a "Reportar problema" (RF11): a mensagem da equipa e, para o
/// cliente, o contacto do profissional.
class ResultadoReporte {
  const ResultadoReporte({
    required this.mensagem,
    this.contactoNome,
    this.contactoTelemovel,
  });

  /// `{id, estado, mensagem, contacto_profissional?: {nome, telemovel}}`.
  factory ResultadoReporte.fromJson(Map<String, dynamic> j) {
    final contacto = JsonLeitura.mapaOuNull(j['contacto_profissional']);
    final mensagem = JsonLeitura.texto(j['mensagem']);
    return ResultadoReporte(
      mensagem: mensagem.isEmpty ? mensagemPredefinida : mensagem,
      contactoNome: JsonLeitura.textoOuNull(contacto?['nome']),
      contactoTelemovel: JsonLeitura.textoOuNull(contacto?['telemovel']),
    );
  }

  static const mensagemPredefinida =
      'Recebemos o seu problema. Respondemos em até 48 horas.';

  final String mensagem;
  final String? contactoNome;
  final String? contactoTelemovel;

  bool get temContacto => contactoNome != null || contactoTelemovel != null;
}
