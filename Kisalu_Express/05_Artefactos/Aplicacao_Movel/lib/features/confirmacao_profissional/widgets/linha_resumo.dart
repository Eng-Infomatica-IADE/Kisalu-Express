import 'package:flutter/material.dart';

import '../../../core/theme/k_colors.dart';
import '../../../core/theme/k_tokens.dart';
import '../../../core/theme/k_typography.dart';

/// Linha "Serviço … Fuga de água na cozinha" do resumo do ecrã 17: rótulo
/// cinzento à esquerda e valor a negrito à direita, mais compacta que a
/// `KLinhaChaveValor`. O valor usa o espaço que sobra e só quebra linha
/// quando não cabe.
class LinhaResumo extends StatelessWidget {
  const LinhaResumo({super.key, required this.rotulo, required this.valor});

  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: K.s4 - 1),
      // O rótulo ocupa o que precisa (até 35 % do ecrã) e o valor fica com o
      // resto, encostado à direita.
      child: Builder(
        builder: (context) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * .35,
              ),
              child: Text(
                rotulo,
                style: KTypography.corpo15.copyWith(color: KColors.neutro500),
              ),
            ),
            const SizedBox(width: K.s16),
            Expanded(
              child: Text(
                valor,
                textAlign: TextAlign.right,
                style: KTypography.corpo15.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
