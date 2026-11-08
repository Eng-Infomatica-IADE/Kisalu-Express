import 'avaliacao.dart';
import 'json_leitura.dart';

/// Trabalho feito com foto confirmada por QR (ecrã 03). A foto real virá do
/// backend; até lá só há a legenda.
class TrabalhoFeito {
  const TrabalhoFeito({required this.id, required this.legenda, this.fotoUrl});

  /// `{id, legenda, url}`.
  factory TrabalhoFeito.fromJson(Map<String, dynamic> j) => TrabalhoFeito(
    id: JsonLeitura.id(j['id']),
    legenda: JsonLeitura.texto(j['legenda']),
    fotoUrl: JsonLeitura.textoOuNull(j['url']),
  );

  final String id;
  final String legenda;
  final String? fotoUrl;
}

/// Profissional (biscateiro). Na interface diz-se sempre "profissional".
class Profissional {
  const Profissional({
    required this.id,
    required this.nome,
    required this.categoria,
    required this.zona,
    required this.distanciaKm,
    required this.rating,
    required this.numAvaliacoes,
    required this.servicosConfirmados,
    required this.anosExperiencia,
    required this.verificado,
    required this.maoDeObraDesde,
    this.especialidades = const [],
    this.trabalhosFeitos = const [],
    this.totalTrabalhosFeitos = 0,
    this.avaliacoes = const [],
  });

  /// ProfissionalResumo ou ProfissionalDetalhe. Campos em falta ou `null`
  /// ficam a 0 / vazio (o interlocutor cliente de uma conversa só traz
  /// `id` e `nome`).
  factory Profissional.fromJson(Map<String, dynamic> j) {
    final trabalhos = JsonLeitura.lista(
      j['trabalhos_feitos'],
      TrabalhoFeito.fromJson,
    );
    return Profissional(
      id: JsonLeitura.id(j['id']),
      nome: JsonLeitura.texto(j['nome']),
      categoria: JsonLeitura.texto(j['categoria']),
      zona: JsonLeitura.texto(j['zona']),
      distanciaKm: JsonLeitura.decimal(j['distancia_km']),
      rating: JsonLeitura.decimal(j['rating']),
      numAvaliacoes: JsonLeitura.inteiro(j['num_avaliacoes']),
      servicosConfirmados: JsonLeitura.inteiro(j['servicos_confirmados']),
      anosExperiencia: JsonLeitura.inteiro(j['anos_experiencia']),
      verificado: JsonLeitura.booleano(j['verificado']),
      maoDeObraDesde: JsonLeitura.inteiro(j['mao_de_obra_desde']),
      especialidades: JsonLeitura.textos(j['especialidades']),
      trabalhosFeitos: trabalhos,
      totalTrabalhosFeitos:
          JsonLeitura.inteiroOuNull(j['total_trabalhos_feitos']) ??
          trabalhos.length,
      avaliacoes: JsonLeitura.lista(j['avaliacoes'], Avaliacao.fromJson),
    );
  }

  final String id;
  final String nome;

  /// Nome da especialidade principal: "Canalizador".
  final String categoria;
  final String zona;
  final double distanciaKm;
  final double rating;
  final int numAvaliacoes;
  final int servicosConfirmados;
  final int anosExperiencia;
  final bool verificado;

  /// Valor em Kz, inteiro — mostrado como "mão de obra desde" (P08).
  final int maoDeObraDesde;
  final List<String> especialidades;

  /// Primeiros trabalhos feitos (miniaturas); o total pode ser maior.
  final List<TrabalhoFeito> trabalhosFeitos;
  final int totalTrabalhosFeitos;

  /// Avaliações recentes.
  final List<Avaliacao> avaliacoes;

  /// "Joaquim Manuel" → "Joaquim M."
  String get nomeCurto {
    final partes = nome.split(' ').where((p) => p.isNotEmpty).toList();
    return partes.length < 2 ? nome : '${partes.first} ${partes.last[0]}.';
  }

  /// "Joaquim Manuel" → "Joaquim"
  String get primeiroNome => nome.split(' ').first;
}
