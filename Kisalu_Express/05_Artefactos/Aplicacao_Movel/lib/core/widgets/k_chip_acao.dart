import 'package:flutter/material.dart';

import '../theme/k_colors.dart';
import '../theme/k_tokens.dart';
import '../theme/k_typography.dart';

/// Chip de contorno com ícone e texto laranja a negrito: "Mapa" ao lado de
/// "Perto de si" (02) e "Lista" no mapa (22). Como no Figma, difere do
/// `KChip` (texto Ébano): é uma ação, não um filtro.
class KChipAcao extends StatelessWidget {
  const KChipAcao({
    super.key,
    required this.rotulo,
    required this.icone,
    required this.onTap,
  });

  final String rotulo;
  final IconData icone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: rotulo,
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: K.alvoMinimo),
          child: Center(
            widthFactor: 1,
            child: Container(
              constraints: const BoxConstraints(minHeight: K.chipAltura - K.s4),
              padding: const EdgeInsets.symmetric(
                horizontal: K.s12,
                vertical: K.s4 / 2,
              ),
              decoration: BoxDecoration(
                color: KColors.branco,
                border: Border.all(color: KColors.areia400),
                borderRadius: BorderRadius.circular(K.raioPilula),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icone, size: K.icone16, color: KColors.laranja),
                  const SizedBox(width: K.s4),
                  Flexible(
                    child: Text(
                      rotulo,
                      style: KTypography.corpo13.copyWith(
                        color: KColors.laranja,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
