/// Estados do pedido (RF08). Termos fixos — não usar sinónimos (P18).
enum EstadoPedido {
  novo('Novo'),
  emCurso('Em curso'),
  concluido('Concluído'),
  cancelado('Cancelado');

  const EstadoPedido(this.rotulo);

  /// Estado do servidor → estado da app (CONTRATO-API.md, 0).
  static EstadoPedido doServidor(Object? estado) => switch (estado) {
    'aceite' || 'a_caminho' || 'em_curso' => emCurso,
    'concluido' => concluido,
    'cancelado' => cancelado,
    _ => novo,
  };

  /// Texto mostrado na interface. Em badges usa-se em MAIÚSCULAS.
  final String rotulo;
}

/// Etapa de um serviço aceite (RF08), como a API a guarda. A app mostra-as
/// todas como [EstadoPedido.emCurso]; o detalhe do trabalho (profissional)
/// precisa de as distinguir para os botões "Estou a caminho" e "Comecei o
/// trabalho".
enum EtapaServico {
  aceite('aceite', 'Proposta aceite'),
  aCaminho('a_caminho', 'A caminho'),
  emCurso('em_curso', 'Trabalho começado');

  const EtapaServico(this.chave, this.rotulo);

  /// Valor da API (`PATCH /pedidos/:id/estado`).
  final String chave;
  final String rotulo;

  /// null quando o pedido não está numa etapa ativa.
  static EtapaServico? doServidor(Object? estado) =>
      values.where((e) => e.chave == estado).firstOrNull;
}
