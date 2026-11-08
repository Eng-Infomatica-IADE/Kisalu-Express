import 'json_leitura.dart';

/// Dados do passo 1 do registo do profissional (ecrã 12).
class RegistoProfissional {
  const RegistoProfissional({
    required this.nomeCompleto,
    required this.categoriaIds,
    required this.anosExperiencia,
    required this.zona,
    required this.raioKm,
  });

  /// Derivado de EuJSON (`GET /eu`). null quando não há nada para
  /// pré-preencher.
  static RegistoProfissional? doUtilizadorJson(Map<String, dynamic> eu) {
    final nome = JsonLeitura.textoOuNull(eu['nome']);
    final p = JsonLeitura.mapaOuNull(eu['profissional']);
    if (p == null && nome == null) return null;
    return RegistoProfissional(
      nomeCompleto: nome ?? '',
      categoriaIds: JsonLeitura.textos(p?['categorias']),
      anosExperiencia: JsonLeitura.inteiro(p?['anos_experiencia']),
      zona: JsonLeitura.texto(p?['zona']),
      raioKm: JsonLeitura.inteiroOuNull(p?['raio_atuacao_km']) ?? 10,
    );
  }

  final String nomeCompleto;

  /// Chaves de `CategoriaId`.
  final List<String> categoriaIds;
  final int anosExperiencia;

  /// "Viana, Luanda"
  final String zona;
  final int raioKm;

  /// Corpo de `PUT /profissionais/eu`.
  Map<String, dynamic> toJson() => {
    'nome_completo': nomeCompleto,
    'categorias': categoriaIds,
    'anos_experiencia': anosExperiencia,
    'zona': zona,
    'raio_atuacao_km': raioKm,
  };
}
