import 'proposta.dart';

/// Ordenação das propostas (ecrã 04, P11). Por omissão: [preco].
enum OrdenacaoPropostas {
  preco('Preço ↑'),
  avaliacao('Avaliação'),
  chegada('Chegada');

  const OrdenacaoPropostas(this.rotulo);

  final String rotulo;

  /// Devolve uma cópia ordenada: preço crescente, melhor avaliação primeiro,
  /// chegada mais cedo primeiro. O desempate mantém a ordem original.
  List<Proposta> ordenar(List<Proposta> propostas) {
    final indexadas = propostas.indexed.toList();
    int cmp(Proposta a, Proposta b) => switch (this) {
      OrdenacaoPropostas.preco => a.valor.compareTo(b.valor),
      OrdenacaoPropostas.avaliacao => b.profissional.rating.compareTo(
        a.profissional.rating,
      ),
      OrdenacaoPropostas.chegada => a.chegadaPrevista.compareTo(
        b.chegadaPrevista,
      ),
    };
    indexadas.sort((a, b) {
      final c = cmp(a.$2, b.$2);
      return c != 0 ? c : a.$1.compareTo(b.$1);
    });
    return [for (final (_, p) in indexadas) p];
  }
}
