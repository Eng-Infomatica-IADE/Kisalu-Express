import 'package:flutter/material.dart';

import '../theme/k_colors.dart';
import '../theme/k_tokens.dart';

/// Bloco de esqueleto (estado "a carregar"): retângulo `areia200`, sem
/// animação (poupa bateria e não atrapalha quem reduz o movimento). Fica
/// fora da árvore semântica; o ecrã anuncia o carregamento.
class KSkeleton extends StatelessWidget {
  const KSkeleton({
    super.key,
    this.largura,
    this.altura = K.s16,
    this.raio = K.s8,
  });

  /// null → ocupa a largura disponível.
  final double? largura;
  final double altura;
  final double raio;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: largura,
      height: altura,
      decoration: BoxDecoration(
        color: KColors.areia200,
        borderRadius: BorderRadius.circular(raio),
      ),
    ),
  );
}

/// Lista de cartões-esqueleto: o carregamento por omissão de [KEstadoBuilder].
class KSkeletonLista extends StatelessWidget {
  const KSkeletonLista({
    super.key,
    this.itens = 3,
    this.alturaItem = KSkeletonLista.alturaPadrao,
  });

  final int itens;
  final double alturaItem;

  static const alturaPadrao = 88.0;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: 'A carregar',
      child: Column(
        children: [
          for (var i = 0; i < itens; i++) ...[
            if (i > 0) const SizedBox(height: K.s12),
            KSkeleton(altura: alturaItem, raio: K.raioCartao),
          ],
        ],
      ),
    );
  }
}
