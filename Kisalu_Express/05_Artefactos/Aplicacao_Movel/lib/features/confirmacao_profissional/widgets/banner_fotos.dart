import 'package:flutter/material.dart';

import '../../../core/theme/k_colors.dart';
import '../../../core/theme/k_icons.dart';
import '../../../core/theme/k_tokens.dart';

/// "Mostre este trabalho no seu perfil" — caixa tom claro com câmara (ecrã
/// 17).
class BannerFotos extends StatelessWidget {
  const BannerFotos({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(K.s16),
      decoration: BoxDecoration(
        color: KColors.tomClaro,
        borderRadius: BorderRadius.circular(K.raioCartao - K.s4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const ExcludeSemantics(
                child: Icon(KIcons.foto, size: K.icone20, color: KColors.brasa),
              ),
              const SizedBox(width: K.s8),
              Expanded(
                child: Text(
                  'Mostre este trabalho no seu perfil',
                  style: text.titleMedium!.copyWith(
                    color: KColors.brasa,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: K.s4),
          Text(
            'Os clientes escolhem primeiro quem mostra fotos de trabalhos '
            'feitos.',
            style: text.bodyMedium!.copyWith(
              color: KColors.brasa,
              height: 18 / 14,
            ),
          ),
        ],
      ),
    );
  }
}
