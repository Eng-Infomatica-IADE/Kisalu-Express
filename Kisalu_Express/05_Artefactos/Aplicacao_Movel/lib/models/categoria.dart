import 'json_leitura.dart';

/// Chaves das categorias (Style Guide, cap. 05 — 13 serviços).
/// O ícone de cada uma resolve-se na camada de UI: `KIcons.categoria(id)`.
abstract final class CategoriaId {
  static const eletricista = 'eletricista';
  static const canalizador = 'canalizador';
  static const mecanico = 'mecanico';
  static const pedreiro = 'pedreiro';
  static const arCond = 'ar_cond';
  static const cabeleireira = 'cabeleireira';
  static const pintor = 'pintor';
  static const limpeza = 'limpeza';
  static const carpinteiro = 'carpinteiro';
  static const informatica = 'informatica';
  static const jardinagem = 'jardinagem';
  static const serralharia = 'serralharia';
  static const transporte = 'transporte';
}

/// Categoria de serviço. Sem tipos de Flutter: só dados.
class Categoria {
  const Categoria({
    required this.id,
    required this.nome,
    required this.plural,
    this.emDestaque = false,
  });

  /// `{chave, nome, plural, em_destaque}`: o id da app é a `chave`.
  factory Categoria.fromJson(Map<String, dynamic> j) => Categoria(
    id: JsonLeitura.texto(j['chave']),
    nome: JsonLeitura.texto(j['nome']),
    plural: JsonLeitura.texto(j['plural']),
    emDestaque: JsonLeitura.booleano(j['em_destaque']),
  );

  /// Uma das chaves de [CategoriaId].
  final String id;

  /// Rótulo curto: "Canalizador", "Ar condicionado".
  final String nome;

  /// Quem presta o serviço, em minúsculas e no plural: "canalizadores".
  final String plural;

  /// Aparece na grelha 4 × 2 do Início (as restantes só em "Ver todos").
  final bool emDestaque;
}
