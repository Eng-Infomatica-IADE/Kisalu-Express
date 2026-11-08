/// Quando o profissional pode chegar (ecrã 15).
enum ChegadaProposta {
  quarentaMinutos(Duration(minutes: 40)),
  umaHora(Duration(hours: 1)),
  duasHoras(Duration(hours: 2)),

  /// À hora que o cliente pediu.
  horaPedida(null);

  const ChegadaProposta(this.duracao);

  /// null → na hora pedida pelo cliente.
  final Duration? duracao;
}

/// Proposta com preço fechado, composta por três componentes em Kz
/// inteiros (RF04, RF15). O valor fechado calcula-se, nunca se escreve.
class NovaProposta {
  const NovaProposta({
    required this.pedidoId,
    required this.maoDeObra,
    required this.material,
    required this.deslocacao,
    required this.chegada,
  });

  final String pedidoId;
  final int maoDeObra;
  final int material;
  final int deslocacao;
  final ChegadaProposta chegada;

  int get valorFechado => maoDeObra + material + deslocacao;

  /// Corpo de `POST /pedidos/:id/propostas`.
  Map<String, dynamic> toJson() => {
    'valor_mao_obra': maoDeObra,
    'valor_material': material,
    'valor_deslocacao': deslocacao,
    if (chegada.duracao case final d?)
      'tempo_chegada_min': d.inMinutes
    else
      'na_hora_pedida': true,
  };
}
