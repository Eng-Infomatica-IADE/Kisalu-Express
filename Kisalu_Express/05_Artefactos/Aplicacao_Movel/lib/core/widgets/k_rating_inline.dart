import 'package:flutter/material.dart';

import '../theme/k_colors.dart';
import '../theme/k_icons.dart';
import '../theme/k_tokens.dart';
import '../utils/k_format.dart';

/// Avaliação de leitura em cartões: UMA estrela + número, "★ 4,8 (126)"
/// (Style Guide, p. 12 — cinco estrelas pequenas são difíceis de ler).
/// [sufixo] acrescenta contexto: "★ 4,8 · chega em 40 min".
class KRatingInline extends StatelessWidget {
  const KRatingInline({
    super.key,
    required this.valor,
    this.numAvaliacoes,
    this.sufixo,
  });

  final double valor;
  final int? numAvaliacoes;
  final String? sufixo;

  @override
  Widget build(BuildContext context) {
    final estilo = Theme.of(context).textTheme.bodySmall!
        .copyWith(fontWeight: FontWeight.w400);
    final nota = KFormat.decimal(valor);
    final rotulo = [
      'Avaliação $nota em 5',
      if (numAvaliacoes != null) '$numAvaliacoes avaliações',
      ?sufixo,
    ].join(', ');

    return Semantics(
      label: rotulo,
      excludeSemantics: true,
      child: Text.rich(
        TextSpan(
          children: [
            const WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Icon(KIcons.estrela, size: K.icone16, color: KColors.ouro),
            ),
            const TextSpan(text: ' '),
            TextSpan(
              text: nota,
              style: estilo.copyWith(
                color: sufixo == null ? KColors.ebano : KColors.neutro700,
                fontWeight: sufixo == null ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
            if (numAvaliacoes != null)
              TextSpan(
                text: ' ($numAvaliacoes)',
                style: estilo.copyWith(color: KColors.neutro500),
              ),
            if (sufixo != null)
              TextSpan(
                text: ' · $sufixo',
                style: estilo.copyWith(color: KColors.neutro700),
              ),
          ],
        ),
      ),
    );
  }
}
