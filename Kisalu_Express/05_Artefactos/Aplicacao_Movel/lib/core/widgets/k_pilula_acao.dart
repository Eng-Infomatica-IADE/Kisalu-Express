import 'package:flutter/material.dart';

import '../theme/k_colors.dart';
import '../theme/k_tokens.dart';
import '../theme/k_typography.dart';

/// Pílula `tomClaro` com texto Brasa a negrito: "Ver" (02, 22) e "Ver
/// pedido" (14). Sem [onPressed] é só indicação visual dentro de um cartão
/// tocável (o leitor de ecrã ignora-a); com [onPressed] é um botão com alvo
/// de 48 dp.
class KPilulaAcao extends StatelessWidget {
  const KPilulaAcao({
    super.key,
    required this.rotulo,
    this.onPressed,
    this.rotuloSemantico,
    this.larga = false,
  });

  final String rotulo;
  final VoidCallback? onPressed;

  /// Nome lido pelo leitor de ecrã, mais descritivo que [rotulo]
  /// ("Ver o perfil de Joaquim Manuel").
  final String? rotuloSemantico;

  /// Mais padding lateral ("Ver pedido", 14).
  final bool larga;

  @override
  Widget build(BuildContext context) {
    final pilula = Container(
      padding: EdgeInsets.symmetric(
        horizontal: larga ? K.s12 + K.s4 - 1 : K.s12,
        vertical: larga ? K.s8 : K.s4 + K.s4 / 2,
      ),
      decoration: BoxDecoration(
        color: KColors.tomClaro,
        borderRadius: BorderRadius.circular(K.raioPilula),
      ),
      child: Text(
        rotulo,
        style:
            (larga
                    ? Theme.of(context).textTheme.bodyMedium!
                    : KTypography.corpo13)
                .copyWith(color: KColors.brasa, fontWeight: FontWeight.w700),
      ),
    );

    if (onPressed == null) return ExcludeSemantics(child: pilula);

    return Semantics(
      button: true,
      label: rotuloSemantico ?? rotulo,
      onTap: onPressed,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: K.alvoMinimo,
            minWidth: K.alvoMinimo,
          ),
          child: Center(widthFactor: 1, child: pilula),
        ),
      ),
    );
  }
}
