import 'package:flutter/material.dart';

import '../theme/k_colors.dart';
import '../theme/k_icons.dart';
import '../theme/k_tokens.dart';
import '../theme/k_typography.dart';

/// Mensagem de erro em linha, por baixo de um campo que não é um
/// `KTextField`: ícone de aviso + texto vermelho que ensina o que fazer
/// (código SMS, serviços escolhidos, valores da proposta). Anunciada pelo
/// leitor de ecrã quando aparece. Nunca só a cor: leva sempre ícone e texto.
class KMensagemErro extends StatelessWidget {
  const KMensagemErro(this.mensagem, {super.key});

  final String mensagem;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: ExcludeSemantics(
            child: Icon(KIcons.aviso, size: K.icone16, color: KColors.erro),
          ),
        ),
        const SizedBox(width: K.s4),
        Expanded(
          child: Semantics(
            liveRegion: true,
            child: Text(
              mensagem,
              style: KTypography.corpo13.copyWith(
                color: KColors.erro,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
