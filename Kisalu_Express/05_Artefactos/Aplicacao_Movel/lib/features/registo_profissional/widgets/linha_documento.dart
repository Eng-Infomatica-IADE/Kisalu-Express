import 'package:flutter/material.dart';

import '../../../core/theme/k_colors.dart';
import '../../../core/theme/k_tokens.dart';
import '../../../core/theme/k_typography.dart';
import '../../../core/widgets/widgets.dart';

/// Linha de um documento do selo Verificado: ícone, título, descrição e
/// estado ENVIADO / FALTA (ecrã 13). Com [onTap] a linha inteira é um botão
/// (adicionar o que falta ou alterar). [acao] acrescenta à descrição uma
/// palavra a laranja ("Alterar"); com [descricaoAcao] a descrição inteira
/// fica a laranja, porque é ela própria a instrução.
class LinhaDocumento extends StatelessWidget {
  const LinhaDocumento({
    super.key,
    required this.icone,
    required this.titulo,
    required this.descricao,
    required this.enviado,
    this.onTap,
    this.acao,
    this.descricaoAcao = false,
  });

  final IconData icone;
  final String titulo;
  final String descricao;
  final bool enviado;
  final VoidCallback? onTap;
  final String? acao;
  final bool descricaoAcao;

  @override
  Widget build(BuildContext context) {
    final linha = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: K.alvoMinimo),
      child: Row(
        children: [
          Container(
            width: K.s32 + K.s8,
            height: K.s32 + K.s8,
            decoration: BoxDecoration(
              color: KColors.tomClaro,
              borderRadius: BorderRadius.circular(K.raioBotao),
            ),
            child: ExcludeSemantics(
              child: Icon(icone, size: K.icone20, color: KColors.brasa),
            ),
          ),
          const SizedBox(width: K.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: Theme.of(context).textTheme.bodyLarge!
                      .copyWith(fontWeight: FontWeight.w500, height: 20 / 16),
                ),
                Text.rich(
                  TextSpan(
                    text: descricao,
                    style: KTypography.corpo13.copyWith(
                      color: descricaoAcao
                          ? KColors.laranja
                          : KColors.neutro500,
                      fontWeight: descricaoAcao ? FontWeight.w700 : null,
                    ),
                    children: [
                      if (acao != null) ...[
                        const TextSpan(text: ' · '),
                        TextSpan(
                          text: acao,
                          style: const TextStyle(
                            color: KColors.laranja,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: K.s8),
          KStatusBadge.envio(enviado: enviado, compacta: true),
        ],
      ),
    );
    final estado = enviado ? 'enviado' : 'falta';
    return Semantics(
      button: onTap != null,
      label: '$titulo, $descricao, $estado${acao == null ? '' : ', $acao'}',
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(K.raioBotao),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: K.s4),
          child: linha,
        ),
      ),
    );
  }
}
