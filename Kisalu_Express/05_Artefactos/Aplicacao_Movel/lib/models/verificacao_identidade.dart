import 'json_leitura.dart';

/// Estado dos documentos do selo Verificado (ecrã 13).
class VerificacaoIdentidade {
  const VerificacaoIdentidade({
    required this.documentoEnviado,
    required this.rostoEnviado,
  });

  /// `GET /profissionais/eu/verificacao`.
  factory VerificacaoIdentidade.fromJson(Map<String, dynamic> j) =>
      VerificacaoIdentidade(
        documentoEnviado: JsonLeitura.booleano(j['documento_enviado']),
        rostoEnviado: JsonLeitura.booleano(j['rosto_enviado']),
      );

  final bool documentoEnviado;
  final bool rostoEnviado;

  bool get completa => documentoEnviado && rostoEnviado;

  VerificacaoIdentidade copyWith({
    bool? documentoEnviado,
    bool? rostoEnviado,
  }) => VerificacaoIdentidade(
    documentoEnviado: documentoEnviado ?? this.documentoEnviado,
    rostoEnviado: rostoEnviado ?? this.rostoEnviado,
  );
}
