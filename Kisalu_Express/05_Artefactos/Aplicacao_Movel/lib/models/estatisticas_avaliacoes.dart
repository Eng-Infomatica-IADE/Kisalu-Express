import 'json_leitura.dart';

/// Intervalo de confiança a 95 % da média das estrelas.
class IntervaloConfianca {
  const IntervaloConfianca({
    required this.inferior,
    required this.superior,
    required this.metodo,
  });

  factory IntervaloConfianca.fromJson(Map<String, dynamic> j) =>
      IntervaloConfianca(
        inferior: JsonLeitura.decimal(j['inferior']),
        superior: JsonLeitura.decimal(j['superior']),
        metodo: JsonLeitura.texto(j['metodo']),
      );

  final double inferior;
  final double superior;

  /// 't' (t de Student, n < 30) ou 'z' (normal, n ≥ 30).
  final String metodo;
}

/// Estatística das avaliações de um profissional (ecrã 03, "Avaliações em
/// números"). `GET /profissionais/:id/estatisticas`; fórmulas em
/// kisalu-api/docs/MATEMATICA.md.
class EstatisticasAvaliacoes {
  const EstatisticasAvaliacoes({
    required this.n,
    required this.media,
    required this.mediana,
    required this.moda,
    required this.desvioPadrao,
    required this.variancia,
    required this.ic95,
    required this.distribuicao,
    required this.mediaBayesiana,
  });

  factory EstatisticasAvaliacoes.fromJson(Map<String, dynamic> j) {
    final d = JsonLeitura.mapa(j['distribuicao']);
    final ic = JsonLeitura.mapaOuNull(j['ic95']);
    double? dec(Object? v) => v is num ? v.toDouble() : null;
    return EstatisticasAvaliacoes(
      n: JsonLeitura.inteiro(j['n']),
      media: dec(j['media']),
      mediana: dec(j['mediana']),
      moda: JsonLeitura.inteiroOuNull(j['moda']),
      desvioPadrao: dec(j['desvio_padrao']),
      variancia: dec(j['variancia']),
      ic95: ic == null ? null : IntervaloConfianca.fromJson(ic),
      distribuicao: {
        for (var e = 1; e <= 5; e++) e: JsonLeitura.inteiro(d['$e']),
      },
      mediaBayesiana: dec(j['media_bayesiana']),
    );
  }

  /// Número de avaliações.
  final int n;

  /// null quando ainda não há avaliações.
  final double? media;
  final double? mediana;
  final int? moda;

  /// Amostrais (n − 1); null com menos de 2 avaliações.
  final double? desvioPadrao;
  final double? variancia;
  final IntervaloConfianca? ic95;

  /// Estrelas (1 a 5) → número de avaliações.
  final Map<int, int> distribuicao;

  /// Média ajustada à média da categoria (justa com poucas avaliações).
  final double? mediaBayesiana;

  /// Maior contagem da distribuição (escala das barras).
  int get maiorContagem => distribuicao.values.fold(0, (a, b) => b > a ? b : a);
}
