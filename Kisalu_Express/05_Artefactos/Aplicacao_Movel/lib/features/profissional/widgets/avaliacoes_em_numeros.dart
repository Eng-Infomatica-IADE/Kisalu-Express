import 'package:flutter/material.dart';

import '../../../core/theme/k_colors.dart';
import '../../../core/theme/k_icons.dart';
import '../../../core/theme/k_tokens.dart';
import '../../../core/theme/k_typography.dart';
import '../../../core/utils/k_format.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/estatisticas_avaliacoes.dart';

/// Ecrã 03 · "Avaliações em números": média ± desvio padrão, intervalo de
/// confiança a 95 % e distribuição 1–5 estrelas (Matemática Discreta; ver
/// kisalu-api/docs/MATEMATICA.md).
class AvaliacoesEmNumeros extends StatelessWidget {
  const AvaliacoesEmNumeros({super.key, required this.estatisticas});

  final EstatisticasAvaliacoes estatisticas;

  @override
  Widget build(BuildContext context) {
    final e = estatisticas;
    final text = Theme.of(context).textTheme;
    final media = KFormat.decimal(e.media ?? 0);
    final dp = e.desvioPadrao;
    final ic = e.ic95;
    final legenda = text.bodySmall!.copyWith(color: KColors.neutro500);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const KSecaoTitulo(titulo: 'Avaliações em números'),
        const SizedBox(height: K.s12),
        KCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                label: dp == null
                    ? 'Média de $media estrelas'
                    : 'Média de $media estrelas, desvio padrão '
                          '${KFormat.decimal(dp)}',
                excludeSemantics: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dp == null ? media : '$media ± ${KFormat.decimal(dp)}',
                      style: KTypography.titulo22,
                    ),
                    Text('média ± desvio padrão', style: legenda),
                  ],
                ),
              ),
              if (ic != null) ...[
                const SizedBox(height: K.s8),
                Text(
                  'Entre ${KFormat.decimal(ic.inferior)} e '
                  '${KFormat.decimal(ic.superior)} com 95% de confiança',
                  style: text.bodyMedium,
                ),
              ],
              const SizedBox(height: K.s16),
              for (var estrelas = 5; estrelas >= 1; estrelas--) ...[
                _BarraDistribuicao(
                  estrelas: estrelas,
                  contagem: e.distribuicao[estrelas] ?? 0,
                  maximo: e.maiorContagem,
                ),
                if (estrelas > 1) const SizedBox(height: K.s8),
              ],
              const SizedBox(height: K.s12),
              Text(
                'n = ${e.n} ${e.n == 1 ? 'avaliação' : 'avaliações'}',
                style: legenda,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Uma linha da distribuição: "5 ★ ▬▬▬▬▬ 108". O leitor de ecrã ouve
/// "5 estrelas: 108 avaliações".
class _BarraDistribuicao extends StatelessWidget {
  const _BarraDistribuicao({
    required this.estrelas,
    required this.contagem,
    required this.maximo,
  });

  final int estrelas;
  final int contagem;
  final int maximo;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final fracao = maximo == 0 ? 0.0 : contagem / maximo;
    return Semantics(
      label:
          '$estrelas ${estrelas == 1 ? 'estrela' : 'estrelas'}: '
          '$contagem ${contagem == 1 ? 'avaliação' : 'avaliações'}',
      excludeSemantics: true,
      child: Row(
        children: [
          Text('$estrelas', style: text.bodyMedium),
          const SizedBox(width: K.s4),
          const Icon(KIcons.estrela, size: K.icone16, color: KColors.ouro),
          const SizedBox(width: K.s8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(K.raioPilula),
              child: Stack(
                children: [
                  Container(height: K.s8, color: KColors.areia100),
                  FractionallySizedBox(
                    widthFactor: fracao,
                    child: Container(height: K.s8, color: KColors.ouro),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: K.s8),
          Text(
            '$contagem',
            style: text.bodyMedium!.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
