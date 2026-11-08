import 'package:flutter/material.dart';

import '../../../core/theme/k_colors.dart';
import '../../../core/theme/k_tokens.dart';
import '../../../models/profissional.dart';

/// Três miniaturas com legenda (ecrã 03). Até haver fotos reais, cada uma é
/// um gradiente areia (placeholder).
class TrabalhosFeitos extends StatelessWidget {
  const TrabalhosFeitos({super.key, required this.trabalhos});

  final List<TrabalhoFeito> trabalhos;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < trabalhos.length; i++) ...[
            if (i > 0) const SizedBox(width: K.s8),
            Expanded(
              child: Container(
                constraints: const BoxConstraints(minHeight: K.miniaturaAltura),
                padding: const EdgeInsets.all(K.s8),
                alignment: Alignment.bottomLeft,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(K.raioMiniatura),
                  gradient: const LinearGradient(
                    colors: [KColors.areia300, KColors.areia100],
                  ),
                ),
                child: Text(
                  trabalhos[i].legenda,
                  style: text.bodySmall!.copyWith(
                    color: KColors.ebano,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
