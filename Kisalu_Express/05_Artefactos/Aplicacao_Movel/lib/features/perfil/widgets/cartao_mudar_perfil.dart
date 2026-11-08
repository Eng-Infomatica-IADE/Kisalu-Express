import 'package:flutter/material.dart';

import '../../../core/theme/k_colors.dart';
import '../../../core/theme/k_icons.dart';
import '../../../core/theme/k_tokens.dart';
import '../../../core/theme/k_typography.dart';

/// Cartão Ébano que alterna entre cliente e profissional (ecrã 20): a
/// pergunta numa linha e a ação noutra ("Também presta serviços?" /
/// "Mudar para profissional"), sem a frase se partir a meio.
class CartaoMudarPerfil extends StatelessWidget {
  const CartaoMudarPerfil({
    super.key,
    required this.pergunta,
    required this.acao,
    required this.onTap,
    this.aCarregar = false,
  });

  final String pergunta;
  final String acao;
  final VoidCallback? onTap;
  final bool aCarregar;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$pergunta $acao',
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: KColors.ebano,
        borderRadius: BorderRadius.circular(K.raioBotao),
        child: InkWell(
          onTap: aCarregar ? null : onTap,
          borderRadius: BorderRadius.circular(K.raioBotao),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: K.alvoMinimo),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: K.s16,
                vertical: K.s12,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pergunta,
                          style: KTypography.corpo15.copyWith(
                            color: KColors.branco,
                            height: 20 / 15,
                          ),
                        ),
                        Text(
                          acao,
                          style: KTypography.corpo15.copyWith(
                            color: KColors.branco,
                            fontWeight: FontWeight.w700,
                            height: 20 / 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: K.s8),
                  const Icon(
                    KIcons.avancar,
                    size: K.icone20,
                    color: KColors.branco,
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
