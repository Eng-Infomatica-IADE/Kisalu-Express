import 'package:flutter/material.dart';

import '../../../core/theme/k_colors.dart';
import '../../../core/theme/k_tokens.dart';
import '../../../core/theme/k_typography.dart';

/// Cartão Ébano "Disponível para trabalhar" com interruptor (ecrã 14).
class CartaoDisponibilidade extends StatelessWidget {
  const CartaoDisponibilidade({
    super.key,
    required this.disponivel,
    required this.onMudar,
  });

  final bool disponivel;
  final ValueChanged<bool> onMudar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(K.s16, K.s8 + 2, K.s12, K.s8 + 2),
      decoration: BoxDecoration(
        color: KColors.ebano,
        borderRadius: BorderRadius.circular(K.raioCategoria),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Disponível para trabalhar',
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    color: KColors.branco,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  disponivel
                      ? 'Está a receber pedidos da sua zona.'
                      : 'Não está a receber pedidos.',
                  style: KTypography.corpo13.copyWith(
                    color: KColors.branco.withValues(alpha: .8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: K.s8),
          Semantics(
            label: 'Disponível para trabalhar',
            toggled: disponivel,
            child: SizedBox(
              width: K.alvoMinimo + K.s8,
              height: K.alvoMinimo,
              child: FittedBox(
                child: Switch(
                  value: disponivel,
                  onChanged: onMudar,
                  activeThumbColor: KColors.branco,
                  activeTrackColor: KColors.laranjaVivo,
                  inactiveThumbColor: KColors.branco,
                  inactiveTrackColor: KColors.neutro500,
                  trackOutlineColor: const WidgetStatePropertyAll(
                    Colors.transparent,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
