import 'package:flutter/material.dart';

import '../theme/k_colors.dart';
import '../theme/k_tokens.dart';

/// Progresso de um fluxo em passos (ecrã 10): barras de 4 dp, concluídas a
/// laranja e por fazer a areia, com legenda opcional "Passo 3 de 4 · …".
class KStepProgress extends StatelessWidget {
  const KStepProgress({
    super.key,
    required this.total,
    required this.atual,
    this.legenda,
  });

  final int total;

  /// 1..total — barras até [atual] (inclusive) ficam laranja.
  final int atual;

  /// Ex.: "Rever o pedido" → "Passo 3 de 4 · Rever o pedido".
  final String? legenda;

  @override
  Widget build(BuildContext context) {
    final texto =
        'Passo $atual de $total${legenda == null ? '' : ' · $legenda'}';
    return Semantics(
      label: texto,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              for (var i = 1; i <= total; i++) ...[
                if (i > 1) const SizedBox(width: K.s4 + K.s4 / 2),
                Expanded(
                  child: Container(
                    height: K.s4 + 1,
                    decoration: BoxDecoration(
                      color: i <= atual ? KColors.laranja : KColors.areia200,
                      borderRadius: BorderRadius.circular(K.s4 / 2),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: K.s12 + K.s4 / 2),
          Text(
            texto,
            style: Theme.of(context).textTheme.bodySmall!
                .copyWith(color: KColors.neutro500),
          ),
        ],
      ),
    );
  }
}
