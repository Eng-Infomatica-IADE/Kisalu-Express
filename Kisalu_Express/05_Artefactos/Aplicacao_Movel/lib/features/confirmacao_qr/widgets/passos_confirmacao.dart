import 'package:flutter/material.dart';

import '../../../core/theme/k_colors.dart';
import '../../../core/theme/k_tokens.dart';

/// Os 3 passos da confirmação (cartão do ecrã 05 e folha "Como funciona?").
class PassosConfirmacao extends StatelessWidget {
  const PassosConfirmacao({super.key});

  static const passos = [
    'O profissional lê o código',
    'Confirma o valor combinado',
    'Avalie o serviço e a experiência',
  ];

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        for (var i = 0; i < passos.length; i++)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : K.s12),
            child: Row(
              children: [
                Container(
                  width: K.passoCirculo,
                  height: K.passoCirculo,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: KColors.tomClaro,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${i + 1}',
                    style: text.labelSmall!.copyWith(
                      color: KColors.brasa,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                const SizedBox(width: K.s12),
                Expanded(child: Text(passos[i], style: text.bodyMedium)),
              ],
            ),
          ),
      ],
    );
  }
}
