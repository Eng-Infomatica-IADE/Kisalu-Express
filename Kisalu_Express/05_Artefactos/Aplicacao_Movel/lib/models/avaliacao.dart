import 'json_leitura.dart';

/// Etiquetas rápidas da avaliação (ecrã 06). Só estas são aceites.
enum EtiquetaAvaliacao {
  pontual('Pontual', 'pontual'),
  precoJusto('Preço justo', 'preco_justo'),
  simpatico('Simpático', 'simpatico'),
  trabalhoLimpo('Trabalho limpo', 'trabalho_limpo'),
  rapido('Rápido', 'rapido');

  const EtiquetaAvaliacao(this.rotulo, this.chave);

  final String rotulo;

  /// Chave usada pela API (`etiqueta.chave`).
  final String chave;

  /// null se a chave não for conhecida.
  static EtiquetaAvaliacao? daChave(Object? chave) =>
      values.where((e) => e.chave == chave).firstOrNull;
}

/// Escala de 1 a 5 estrelas (ecrã 06).
abstract final class EscalaAvaliacao {
  static const minimo = 1;
  static const maximo = 5;

  static const _rotulos = {
    1: 'Mau',
    2: 'Fraco',
    3: 'Razoável',
    4: 'Muito bom',
    5: 'Excelente',
  };

  /// 4 → "Muito bom"; fora da escala → "".
  static String rotulo(int estrelas) => _rotulos[estrelas] ?? '';
}

/// Avaliação publicada sobre um profissional (RF12), lida no ecrã 03.
class Avaliacao {
  const Avaliacao({
    required this.autor,
    required this.estrelas,
    required this.comentario,
    this.etiquetas = const [],
  });

  /// `{autor, estrelas, comentario, etiquetas:[chaves]}`; etiquetas
  /// desconhecidas são ignoradas.
  factory Avaliacao.fromJson(Map<String, dynamic> j) => Avaliacao(
    autor: JsonLeitura.texto(j['autor']),
    estrelas: JsonLeitura.inteiro(j['estrelas']),
    comentario: JsonLeitura.texto(j['comentario']),
    etiquetas: [
      for (final c in JsonLeitura.textos(j['etiquetas']))
        ?EtiquetaAvaliacao.daChave(c),
    ],
  );

  /// Nome abreviado: "Maria S."
  final String autor;
  final int estrelas; // 1–5
  final String comentario;
  final List<EtiquetaAvaliacao> etiquetas;
}

/// Avaliação a enviar pelo cliente (ecrã 06). O servidor revalida tudo.
class NovaAvaliacao {
  const NovaAvaliacao({
    required this.estrelas,
    this.etiquetas = const [],
    this.comentario = '',
  });

  final int estrelas;
  final List<EtiquetaAvaliacao> etiquetas;
  final String comentario;

  Map<String, dynamic> toJson() => {
    'estrelas': estrelas,
    'etiquetas': [for (final e in etiquetas) e.chave],
    'comentario': comentario,
  };
}
