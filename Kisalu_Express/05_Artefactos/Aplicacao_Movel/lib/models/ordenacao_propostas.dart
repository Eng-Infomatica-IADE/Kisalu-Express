import 'proposta.dart';

/// Ordenação das propostas (ecrã 04, P11). Por omissão: [preco].
enum OrdenacaoPropostas {
  preco('Preço ↑'),
  avaliacao('Avaliação'),
  chegada('Chegada');

  const OrdenacaoPropostas(this.rotulo);

  final String rotulo;

  /// Chegada prometida mais cedo primeiro; em empate, a mais rápida na
  /// simulação de Monte Carlo (`p50_min`, mediana do tempo de chegada).
  static int _chegada(Proposta a, Proposta b) {
    final c = a.chegadaPrevista.compareTo(b.chegadaPrevista);
    final ea = a.estimativaChegada;
    final eb = b.estimativaChegada;
    if (c != 0 || ea == null || eb == null) return c;
    return ea.p50Min.compareTo(eb.p50Min);
  }

  /// Devolve uma cópia ordenada: preço crescente, melhor avaliação primeiro,
  /// chegada mais cedo primeiro. O desempate mantém a ordem original.
  List<Proposta> ordenar(List<Proposta> propostas) {
    final indexadas = propostas.indexed.toList();
    int cmp(Proposta a, Proposta b) => switch (this) {
      OrdenacaoPropostas.preco => a.valor.compareTo(b.valor),
      OrdenacaoPropostas.avaliacao => b.profissional.rating.compareTo(
        a.profissional.rating,
      ),
      OrdenacaoPropostas.chegada => _chegada(a, b),
    };
    indexadas.sort((a, b) {
      final c = cmp(a.$2, b.$2);
      return c != 0 ? c : a.$1.compareTo(b.$1);
    });
    return [for (final (_, p) in indexadas) p];
  }
}
