import 'package:flutter/material.dart';

import '../theme/k_colors.dart';
import '../theme/k_tokens.dart';
import '../theme/k_typography.dart';
import 'k_price_text.dart';

/// Linha "rótulo à esquerda, valor à direita": folha de confirmação (08) e
/// comprovativo (07). O valor quebra linha em vez de cortar (texto a 200 %).
class KLinhaChaveValor extends StatelessWidget {
  const KLinhaChaveValor({
    super.key,
    required this.rotulo,
    required String this.valor,
  }) : preco = null,
       tamanhoPreco = KPriceText.destaque;

  /// Valor em Kz, em destaque (Sora 800): "Valor fechado — 12.500 Kz".
  const KLinhaChaveValor.preco({
    super.key,
    required this.rotulo,
    required int valor,
    double tamanho = KPriceText.destaque,
  }) : valor = null,
       preco = valor,
       tamanhoPreco = tamanho;

  final String rotulo;
  final String? valor;
  final int? preco;
  final double tamanhoPreco;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: K.s4 + K.s4 / 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              rotulo,
              style: text.bodyMedium!.copyWith(color: KColors.neutro700),
            ),
          ),
          const SizedBox(width: K.s16),
          Flexible(
            child: preco != null
                ? KPriceText(preco!, tamanho: tamanhoPreco)
                : Text(
                    valor!,
                    textAlign: TextAlign.right,
                    style: KTypography.corpo15.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
