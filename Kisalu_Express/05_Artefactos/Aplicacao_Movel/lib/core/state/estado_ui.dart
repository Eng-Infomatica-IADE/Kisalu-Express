/// Estados de ecrã (Style Guide "desenhar os desvios", RNF07).
/// Como a classe é `sealed`, um `switch` sem um dos estados não compila.
sealed class EstadoUi<T> {
  const EstadoUi();
}

/// A carregar: esqueletos, sem bloquear o ecrã.
final class Carregar<T> extends EstadoUi<T> {
  const Carregar();
}

/// Há dados para mostrar.
final class Sucesso<T> extends EstadoUi<T> {
  const Sucesso(this.dados);

  final T dados;
}

/// Sem dados: `KEmptyState` com ação (ecrã 09).
final class Vazio<T> extends EstadoUi<T> {
  const Vazio();
}

/// Falha: `KInlineAlert` com mensagem em português e nova tentativa.
final class Erro<T> extends EstadoUi<T> {
  const Erro(this.mensagem, {this.semRede = false, this.naoEncontrado = false});

  final String mensagem;

  /// Falha de ligação (ecrã 10).
  final bool semRede;

  /// `:id` desconhecido ou sem acesso: a view mostra "não encontrado".
  final bool naoEncontrado;
}
