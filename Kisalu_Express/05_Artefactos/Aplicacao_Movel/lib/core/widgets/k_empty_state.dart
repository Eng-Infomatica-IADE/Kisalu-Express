import 'package:flutter/material.dart';

import '../theme/k_colors.dart';
import '../theme/k_tokens.dart';
import '../theme/k_typography.dart';
import 'k_secondary_button.dart';

/// Estado vazio (ecrã 09): círculo tom claro com ícone, título, texto e uma
/// ação secundária que diz para onde ir.
class KEmptyState extends StatelessWidget {
  const KEmptyState({
    super.key,
    required this.icone,
    required this.titulo,
    required this.mensagem,
    this.rotuloAcao,
    this.onAcao,
  });

  final IconData icone;
  final String titulo;
  final String mensagem;
  final String? rotuloAcao;
  final VoidCallback? onAcao;

  static const _alturaLinha = 20.0 / 15;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: K.estadoVazioCirculo,
          height: K.estadoVazioCirculo,
          decoration: const BoxDecoration(
            color: KColors.tomClaro,
            shape: BoxShape.circle,
          ),
          child: ExcludeSemantics(
            child: Icon(icone, size: K.icone40 + K.s16, color: KColors.laranja),
          ),
        ),
        const SizedBox(height: K.s12),
        Semantics(
          header: true,
          child: Text(
            titulo,
            textAlign: TextAlign.center,
            style: KTypography.titulo22,
          ),
        ),
        const SizedBox(height: K.s12),
        Text(
          mensagem,
          textAlign: TextAlign.center,
          style: KTypography.corpo15.copyWith(
            color: KColors.neutro700,
            height: _alturaLinha,
          ),
        ),
        if (rotuloAcao != null) ...[
          const SizedBox(height: K.s12),
          KSecondaryButton(
            rotulo: rotuloAcao!,
            onPressed: onAcao,
            larguraTotal: false,
          ),
        ],
      ],
    );
  }
}
