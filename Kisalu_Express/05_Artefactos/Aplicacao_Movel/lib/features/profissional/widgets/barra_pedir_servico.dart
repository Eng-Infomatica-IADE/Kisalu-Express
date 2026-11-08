import 'package:flutter/material.dart';

import '../../../core/theme/k_colors.dart';
import '../../../core/theme/k_tokens.dart';
import '../../../core/widgets/widgets.dart';

/// Barra inferior fixa do ecrã 03: "mão de obra desde" + preço, e o botão
/// "Pedir serviço", que ocupa o resto da largura.
class BarraPedirServico extends StatelessWidget {
  const BarraPedirServico({
    super.key,
    required this.maoDeObraDesde,
    required this.onPedir,
  });

  final int maoDeObraDesde;
  final VoidCallback onPedir;

  /// Largura do botão em fração do ecrã, como no Figma.
  static const _fracaoBotao = .6;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: KColors.branco,
        boxShadow: [
          // Sombra para cima (a do cartão cai para baixo).
          BoxShadow(
            color: KColors.sombra,
            offset: Offset(0, -4),
            blurRadius: 14,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            K.margemPara(context),
            K.s16,
            K.margemPara(context),
            K.s24 + K.s4,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'mão de obra desde',
                      style: text.bodySmall!.copyWith(
                        color: KColors.neutro500,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    KPriceText(maoDeObraDesde, tamanho: KPriceText.barra),
                  ],
                ),
              ),
              const SizedBox(width: K.s4),
              SizedBox(
                width: MediaQuery.sizeOf(context).width * _fracaoBotao,
                child: KPrimaryButton(
                  rotulo: 'Pedir serviço',
                  onPressed: onPedir,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
