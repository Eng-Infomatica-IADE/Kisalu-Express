import 'json_leitura.dart';

/// Estimativa da chegada por simulação de Monte Carlo (ecrã 04): 10 000
/// viagens simuladas com a distância e os minutos prometidos na proposta.
/// Vem em `estimativa_chegada` da PropostaJSON (só para o cliente).
class EstimativaChegada {
  const EstimativaChegada({
    required this.simulacoes,
    required this.mediaMin,
    required this.p50Min,
    required this.p90Min,
    required this.probCumprir,
  });

  factory EstimativaChegada.fromJson(Map<String, dynamic> j) =>
      EstimativaChegada(
        simulacoes: JsonLeitura.inteiro(j['simulacoes']),
        mediaMin: JsonLeitura.decimal(j['media_min']),
        p50Min: JsonLeitura.decimal(j['p50_min']),
        p90Min: JsonLeitura.decimal(j['p90_min']),
        probCumprir: JsonLeitura.decimal(j['prob_cumprir']),
      );

  final int simulacoes;
  final double mediaMin;

  /// Metade das simulações chega até este tempo (mediana).
  final double p50Min;

  /// 9 em cada 10 simulações chegam até este tempo.
  final double p90Min;

  /// Fração (0 a 1) das simulações dentro dos minutos prometidos.
  final double probCumprir;

  /// Percentagem arredondada a 5 % (não sugere precisão que não existe).
  int get percentagemCumprir => ((probCumprir * 100) / 5).round() * 5;
}
