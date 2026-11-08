import 'package:flutter/material.dart';

import '../../../core/theme/k_colors.dart';
import '../../../core/theme/k_icons.dart';
import '../../../core/theme/k_tokens.dart';
import '../../../core/utils/k_format.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/comprovativo.dart';

/// Folha "Serviço confirmado" do ecrã 07 (comprovativo, RF17, P15).
class HistoricoComprovativoFolha extends StatelessWidget {
  const HistoricoComprovativoFolha({
    super.key,
    required this.comprovativo,
    required this.onPartilhar,
    this.onReportar,
  });

  final Comprovativo comprovativo;
  final VoidCallback onPartilhar;

  /// null quando já passou a garantia de 7 dias (sem `pode_reclamar`).
  final VoidCallback? onReportar;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final c = comprovativo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const ExcludeSemantics(
              child: Icon(
                KIcons.concluido,
                size: K.icone24,
                color: KColors.sucesso,
              ),
            ),
            const SizedBox(width: K.s8),
            Expanded(
              child: Semantics(
                header: true,
                child: Text('Serviço confirmado', style: text.titleLarge),
              ),
            ),
          ],
        ),
        const SizedBox(height: K.s8),
        KLinhaChaveValor.preco(
          rotulo: 'Valor',
          valor: c.valor,
          tamanho: KPriceText.destaque,
        ),
        KLinhaChaveValor(rotulo: 'Profissional', valor: c.profissional.nome),
        KLinhaChaveValor(rotulo: 'Serviço', valor: c.servico),
        KLinhaChaveValor(rotulo: 'Data', valor: KFormat.dataNumerica(c.data)),
        KLinhaChaveValor(rotulo: 'Pagamento', valor: c.pagamento.rotulo),
        KLinhaChaveValor(rotulo: 'Código', valor: c.referencia),
        const SizedBox(height: K.s16),
        KPrimaryButton(rotulo: 'Partilhar', onPressed: onPartilhar),
        if (onReportar != null) ...[
          const SizedBox(height: K.s4),
          Center(
            child: KTextLink(
              rotulo: 'Reportar problema',
              destrutivo: true,
              onPressed: onReportar,
            ),
          ),
        ],
      ],
    );
  }
}
