import 'package:flutter/material.dart';

import '../../../core/theme/k_colors.dart';
import '../../../core/theme/k_tokens.dart';
import '../../../core/theme/k_typography.dart';
import '../../../core/widgets/widgets.dart';

/// Número grande laranja com legenda por baixo (ecrã 14: "3 · Pedidos novos").
class EstatisticaCartao extends StatelessWidget {
  const EstatisticaCartao({
    super.key,
    required this.valor,
    required this.legenda,
  });

  final String valor;
  final String legenda;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '$legenda: $valor',
      excludeSemantics: true,
      child: KCard(
        padding: const EdgeInsets.symmetric(horizontal: K.s8, vertical: K.s12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              valor,
              style: KTypography.preco(size: K.icone20)
                  .copyWith(color: KColors.laranja),
            ),
            Text(
              legenda,
              textAlign: TextAlign.center,
              style: KTypography.corpo13.copyWith(color: KColors.neutro700),
            ),
          ],
        ),
      ),
    );
  }
}
