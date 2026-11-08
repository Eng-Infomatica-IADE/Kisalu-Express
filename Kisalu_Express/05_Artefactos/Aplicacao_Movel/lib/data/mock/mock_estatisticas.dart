/// Estatística das avaliações (ecrã 03) com os mesmos valores que a API
/// devolve para os dados de exemplo (`GET /profissionais/:id/estatisticas`).
/// Fica em JSON para passar pelo mesmo `fromJson` que a versão REST.
abstract final class MockEstatisticas {
  static Map<String, dynamic> _e(
    int n,
    double media,
    double dp,
    double variancia,
    double inferior,
    double superior,
    String metodo,
    List<int> d,
    double bayes,
  ) => {
    'n': n,
    'media': media,
    'mediana': 5,
    'moda': 5,
    'desvio_padrao': dp,
    'variancia': variancia,
    'ic95': {'inferior': inferior, 'superior': superior, 'metodo': metodo},
    'distribuicao': {for (var i = 0; i < 5; i++) '${i + 1}': d[i]},
    'media_bayesiana': bayes,
  };

  /// Por id do profissional no mock (p1 = Joaquim, … p7 = Hélder).
  static final porProfissional = <String, Map<String, dynamic>>{
    'p1': _e(126, 4.79, 0.6, 0.357, 4.69, 4.9, 'z', [1, 1, 3, 13, 108], 4.79),
    'p2': _e(88, 4.9, 0.34, 0.116, 4.83, 4.97, 'z', [0, 0, 1, 7, 80], 4.9),
    'p3': _e(54, 4.57, 0.81, 0.664, 4.36, 4.79, 'z', [1, 1, 2, 12, 38], 4.61),
    'p4': _e(97, 4.89, 0.38, 0.143, 4.81, 4.96, 'z', [0, 0, 2, 7, 88], 4.88),
    'p5': _e(73, 4.7, 0.62, 0.38, 4.56, 4.84, 'z', [0, 1, 3, 13, 56], 4.7),
    'p6': _e(39, 4.54, 0.76, 0.571, 4.3, 4.78, 'z', [0, 1, 3, 9, 26], 4.54),
    'p7': _e(28, 4.39, 0.83, 0.692, 4.07, 4.72, 't', [0, 1, 3, 8, 16], 4.39),
  };
}
