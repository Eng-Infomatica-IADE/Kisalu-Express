import 'package:flutter/material.dart';

import '../../../core/theme/k_colors.dart';
import '../../../core/theme/k_icons.dart';
import '../../../core/theme/k_tokens.dart';
import '../../../core/widgets/widgets.dart';

/// Banner Ébano do Início: etiqueta amarela, mensagem e marca. O ✕ fecha-o
/// (P06). Corrige P03: explica o pagamento por QR.
class BannerQr extends StatelessWidget {
  const BannerQr({super.key, required this.onFechar});

  final VoidCallback onFechar;

  /// Largura do texto: quebra em duas linhas, como no Figma.
  static const _larguraTexto = 200.0;
  static const _padding = K.s16 + K.s4 / 2;
  static const _markLargura = K.s32 + K.s4;
  static const _markAltura = K.s32 + K.s16 + K.s4;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(_padding),
          decoration: BoxDecoration(
            color: KColors.ebano,
            borderRadius: BorderRadius.circular(K.raioCartao),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: K.s12,
                        vertical: K.s4 + 1,
                      ),
                      decoration: BoxDecoration(
                        color: KColors.ouro,
                        borderRadius: BorderRadius.circular(K.raioPilula),
                      ),
                      child: Text(
                        'CONFIRMAÇÃO POR QR',
                        style: text.labelSmall!.copyWith(color: KColors.ebano),
                      ),
                    ),
                    const SizedBox(height: K.s4 + K.s4 / 2),
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: _larguraTexto,
                      ),
                      child: Text(
                        'Pague só quando o trabalho estiver feito.',
                        style: text.titleMedium!.copyWith(
                          color: KColors.branco,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: K.s8),
              const KisaluMark(
                largura: _markLargura,
                altura: _markAltura,
                cor: KColors.laranjaVivo,
                corLetra: KColors.ebano,
              ),
            ],
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: Semantics(
            button: true,
            label: 'Fechar aviso',
            excludeSemantics: true,
            child: Tooltip(
              message: 'Fechar aviso',
              child: InkResponse(
                onTap: onFechar,
                radius: K.alvoMinimo / 2,
                child: const SizedBox.square(
                  dimension: K.alvoMinimo,
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(0, K.s12, K.s12, 0),
                      child: Icon(
                        KIcons.fechar,
                        size: K.icone16,
                        color: KColors.branco,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
