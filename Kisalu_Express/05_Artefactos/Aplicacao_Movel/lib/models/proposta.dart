import 'estimativa_chegada.dart';
import 'json_leitura.dart';
import 'profissional.dart';

/// O que o valor da proposta inclui (RF15).
enum ComponenteProposta {
  maoDeObra('mão de obra'),
  material('material'),
  deslocacao('deslocação');

  const ComponenteProposta(this.rotulo);

  final String rotulo;
}

/// Proposta com preço fechado em Kz e o que inclui (RF04).
class Proposta {
  const Proposta({
    required this.id,
    required this.profissional,
    required this.valor,
    required this.inclui,
    required this.chegadaPrevista,
    this.materialDetalhe,
    this.nomeNoCartao,
    this.estimativaChegada,
  });

  /// PropostaJSON. O "inclui" sai das componentes com valor acima de zero.
  factory Proposta.fromJson(Map<String, dynamic> j) {
    final componentes = JsonLeitura.mapa(j['componentes']);
    bool tem(String c) => JsonLeitura.inteiro(componentes[c]) > 0;
    return Proposta(
      id: JsonLeitura.id(j['proposta_id'] ?? j['id']),
      profissional: Profissional.fromJson(JsonLeitura.mapa(j['profissional'])),
      valor: JsonLeitura.inteiro(j['valor_total']),
      inclui: [
        if (tem('mao_de_obra')) ComponenteProposta.maoDeObra,
        if (tem('material')) ComponenteProposta.material,
        if (tem('deslocacao')) ComponenteProposta.deslocacao,
      ],
      chegadaPrevista: JsonLeitura.data(j['chegada_prevista']),
      materialDetalhe: JsonLeitura.textoOuNull(j['material_detalhe']),
      estimativaChegada: switch (JsonLeitura.mapaOuNull(
        j['estimativa_chegada'],
      )) {
        final m? => EstimativaChegada.fromJson(m),
        null => null,
      },
    );
  }

  final String id;
  final Profissional profissional;

  /// Kz, inteiro, sem cêntimos.
  final int valor;
  final List<ComponenteProposta> inclui;

  /// Detalhe do material, quando incluído: "sifão e vedante".
  final String? materialDetalhe;

  /// Nome a mostrar no cartão (04), como cada proposta o apresenta; sem
  /// valor, o nome completo do profissional.
  final String? nomeNoCartao;

  /// Momento previsto de chegada. A UI calcula "chega em 40 min" com o
  /// relógio do repositório (`KFormat.chegadaEm`).
  final DateTime chegadaPrevista;

  /// Monte Carlo da chegada (só para o cliente); null sem distância ou
  /// quando a proposta chega "na hora pedida".
  final EstimativaChegada? estimativaChegada;

  String get nomeVisivel => nomeNoCartao ?? profissional.nome;

  bool get materialIncluido => inclui.contains(ComponenteProposta.material);
}
