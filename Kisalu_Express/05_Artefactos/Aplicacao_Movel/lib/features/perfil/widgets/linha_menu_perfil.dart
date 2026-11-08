import 'package:flutter/material.dart';

import '../../../core/theme/k_colors.dart';
import '../../../core/theme/k_icons.dart';
import '../../../core/theme/k_tokens.dart';
import '../../../core/theme/k_typography.dart';

/// Linha do menu do Perfil (ecrã 20): ícone em quadrado tom claro, título,
/// descrição opcional e seta. A linha inteira é o alvo de toque.
class LinhaMenuPerfil extends StatelessWidget {
  const LinhaMenuPerfil({
    super.key,
    required this.icone,
    required this.titulo,
    required this.onTap,
    this.descricao,
  });

  final IconData icone;
  final String titulo;
  final String? descricao;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: descricao == null ? titulo : '$titulo, $descricao',
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: K.alvoMinimo + K.s16),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: K.s12 + K.s4 / 2,
              vertical: K.s8,
            ),
            child: Row(
              children: [
                Container(
                  width: K.s32 + K.s8,
                  height: K.s32 + K.s8,
                  decoration: BoxDecoration(
                    color: KColors.tomClaro,
                    borderRadius: BorderRadius.circular(K.raioBotao),
                  ),
                  child: Icon(icone, size: K.icone20, color: KColors.brasa),
                ),
                const SizedBox(width: K.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: Theme.of(context).textTheme.bodyLarge!
                            .copyWith(fontWeight: FontWeight.w500),
                      ),
                      if (descricao != null)
                        Text(
                          descricao!,
                          style: KTypography.corpo13.copyWith(
                            color: KColors.neutro500,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: K.s8),
                const Icon(
                  KIcons.avancar,
                  size: K.icone20,
                  color: KColors.neutro700,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
