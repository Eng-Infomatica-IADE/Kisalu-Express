import 'package:flutter/material.dart';

import '../theme/k_colors.dart';
import '../theme/k_tokens.dart';
import '../theme/k_typography.dart';

/// Caixa `areia50` com "**Inclui:** mão de obra · material · deslocação"
/// (cartões de proposta no 04 e folha de confirmação no 08). Se o material
/// não está incluído, [aviso] aparece a vermelho: "Material não incluído.".
class KIncluiBox extends StatelessWidget {
  const KIncluiBox({
    super.key,
    required this.texto,
    this.aviso,
    this.maior = false,
  });

  /// "mão de obra · material · deslocação" (ver `KFormat.inclui`).
  final String texto;
  final String? aviso;

  /// Texto de 13 sp e raio 14 (folha 08).
  final bool maior;

  @override
  Widget build(BuildContext context) {
    final base = maior
        ? KTypography.corpo13
        : Theme.of(context).textTheme.bodySmall!
              .copyWith(fontWeight: FontWeight.w400);
    final estilo = base.copyWith(color: KColors.neutro700);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: K.s12, vertical: K.s8),
      decoration: BoxDecoration(
        color: KColors.areia50,
        borderRadius: BorderRadius.circular(maior ? K.raioBotao : K.raioInclui),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: 'Inclui:',
              style: estilo.copyWith(
                color: KColors.ebano,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(text: ' $texto'),
            if (aviso != null)
              TextSpan(
                text: ' $aviso',
                style: estilo.copyWith(
                  color: KColors.erro,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
        style: estilo,
      ),
    );
  }
}
