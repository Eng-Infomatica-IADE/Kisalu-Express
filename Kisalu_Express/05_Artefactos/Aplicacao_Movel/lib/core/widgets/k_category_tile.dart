import 'package:flutter/material.dart';

import '../theme/k_colors.dart';
import '../theme/k_tokens.dart';

/// Categoria de serviço (ecrã 02): quadrado tom claro de 64 dp com ícone
/// e rótulo por baixo — sempre ícone + rótulo (RNF04). Selecionada: fundo
/// laranja, ícone branco.
class KCategoryTile extends StatelessWidget {
  const KCategoryTile({
    super.key,
    required this.icone,
    required this.rotulo,
    required this.onTap,
    this.selecionada = false,
  });

  final IconData icone;
  final String rotulo;
  final VoidCallback? onTap;
  final bool selecionada;

  @override
  Widget build(BuildContext context) {
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(K.raioCategoria),
    );
    return Semantics(
      button: true,
      selected: selecionada,
      label: rotulo,
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Material(
              color: selecionada ? KColors.laranja : KColors.tomClaro,
              shape: forma,
              child: InkWell(
                onTap: onTap,
                customBorder: forma,
                splashColor: KColors.areia200,
                child: SizedBox.square(
                  dimension: K.categoriaTile,
                  child: Icon(
                    icone,
                    size: K.icone24 + K.s4 / 2,
                    color: selecionada ? KColors.branco : KColors.brasa,
                  ),
                ),
              ),
            ),
            const SizedBox(height: K.s4 + K.s4 / 2),
            // Cada palavra na sua linha e, se uma palavra não couber
            // ("condicionado"), a letra encolhe em vez de a partir a meio.
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                rotulo.replaceAll(' ', '\n'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall!
                    .copyWith(color: KColors.ebano),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
