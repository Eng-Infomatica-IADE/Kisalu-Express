import 'package:flutter/material.dart';

import '../theme/k_colors.dart';
import '../theme/k_tokens.dart';
import '../theme/k_typography.dart';

/// Ícone laranja + texto numa linha: "Talatona", "Hoje, 16:00" (04) e as
/// três linhas do cartão de rever o pedido (10). Quebra linha, nunca corta.
class KLinhaIcone extends StatelessWidget {
  const KLinhaIcone({
    super.key,
    required this.icone,
    required this.texto,
    this.corIcone = KColors.laranja,
    this.maior = false,
  });

  final IconData icone;
  final String texto;
  final Color corIcone;

  /// Texto Corpo S Ébano (cartão de rever, ecrã 10).
  final bool maior;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(
          child: Icon(icone, size: K.icone16, color: corIcone),
        ),
        SizedBox(width: maior ? K.s4 / 2 : K.s4 + K.s4 / 2),
        Flexible(
          child: Text(
            texto,
            style: maior
                ? Theme.of(context).textTheme.bodyMedium!
                      .copyWith(color: KColors.ebano)
                : KTypography.corpo13.copyWith(color: KColors.neutro700),
          ),
        ),
      ],
    );
  }
}
