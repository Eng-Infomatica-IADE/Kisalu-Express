import 'package:flutter/material.dart';

import '../../models/profissional.dart';
import '../theme/k_colors.dart';
import '../theme/k_icons.dart';
import '../theme/k_tokens.dart';
import '../theme/k_typography.dart';
import '../utils/k_format.dart';
import 'k_avatar.dart';
import 'k_card.dart';
import 'k_pilula_acao.dart';
import 'k_rating_inline.dart';

/// Cartão de profissional (ecrãs 02 e 22). O cartão inteiro leva ao perfil
/// (único destino); o "Ver" é só a indicação visual. No mapa (22, v3.1) a
/// pílula diz "Ver perfil" e o selo aparece também em texto
/// ([seloEmTexto]), para não depender só da cor.
class KCartaoProfissional extends StatelessWidget {
  const KCartaoProfissional({
    super.key,
    required this.profissional,
    required this.onAbrir,
    this.rotuloAcao = 'Ver',
    this.seloEmTexto = false,
  });

  final Profissional profissional;
  final VoidCallback onAbrir;
  final String rotuloAcao;
  final bool seloEmTexto;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = profissional;
    final grande = MediaQuery.textScalerOf(context).scale(1) > 1.5;
    final dados = <Widget>[
      KAvatar(nome: p.nome, tamanho: K.avatarCartao),
      const SizedBox(width: K.s12),
      Expanded(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: p.nome),
                  if (p.verificado) ...[
                    const TextSpan(text: ' '),
                    const WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Icon(
                        KIcons.verificado,
                        size: K.icone16,
                        color: KColors.sucesso,
                        semanticLabel: 'Verificado',
                      ),
                    ),
                  ],
                ],
              ),
              style: text.titleMedium,
            ),
            Text(
              '${p.categoria} · ${KFormat.km(p.distanciaKm)}',
              style: KTypography.corpo13.copyWith(color: KColors.neutro500),
            ),
            if (seloEmTexto && p.verificado)
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  KRatingInline(
                    valor: p.rating,
                    numAvaliacoes: p.numAvaliacoes,
                  ),
                  Text(
                    ' · Verificado',
                    style: KTypography.corpo13.copyWith(
                      color: KColors.sucesso,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              )
            else
              KRatingInline(valor: p.rating, numAvaliacoes: p.numAvaliacoes),
          ],
        ),
      ),
    ];
    return KCard(
      onTap: onAbrir,
      rotuloSemantico: 'Ver perfil de ${p.nome}',
      // Com letra muito grande a pílula passa para baixo, para o nome e a
      // categoria não ficarem espremidos.
      child: grande
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: dados),
                const SizedBox(height: K.s8),
                KPilulaAcao(rotulo: rotuloAcao),
              ],
            )
          : Row(
              children: [
                ...dados,
                const SizedBox(width: K.s8),
                KPilulaAcao(rotulo: rotuloAcao),
              ],
            ),
    );
  }
}
