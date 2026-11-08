import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/k_colors.dart';
import '../../../core/theme/k_tokens.dart';
import '../../../core/utils/k_format.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/repositories/kisalu_repository.dart';
import '../../../models/pedido.dart';
import '../../../models/proposta.dart';
import '../controllers/confirmar_proposta_controller.dart';

/// Abre a folha 08. Devolve o pedido já em curso se a pessoa confirmou, ou
/// null se voltou às propostas.
Future<Pedido?> mostrarConfirmarProposta(
  BuildContext context, {
  required String pedidoId,
  required Proposta proposta,
}) => mostrarKFolha<Pedido>(
  context,
  builder: (_) => ChangeNotifierProvider(
    create: (c) => ConfirmarPropostaController(
      c.read<KisaluRepository>(),
      pedidoId,
      proposta,
    ),
    child: const ConfirmarPropostaSheet(),
  ),
);

/// Conteúdo da folha 08 "Confirmar a proposta?" (RNF08, RNF10).
class ConfirmarPropostaSheet extends StatelessWidget {
  const ConfirmarPropostaSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ConfirmarPropostaController>();
    final text = Theme.of(context).textTheme;
    final pro = c.proposta.profissional;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          header: true,
          child: Text('Confirmar a proposta?', style: text.titleLarge),
        ),
        const SizedBox(height: K.s8),
        Text(
          'O ${pro.primeiroNome} só recebe a sua morada e o seu contacto '
          'depois de confirmar.',
          style: text.bodyMedium!.copyWith(color: KColors.neutro700),
        ),
        const SizedBox(height: K.s4),
        KLinhaChaveValor(rotulo: 'Profissional', valor: '${pro.nome} ✓'),
        KLinhaChaveValor.preco(
          rotulo: 'Valor fechado',
          valor: c.proposta.valor,
        ),
        const SizedBox(height: K.s4),
        KIncluiBox(
          maior: true,
          texto: KFormat.inclui(
            c.proposta.inclui,
            materialDetalhe: c.proposta.materialDetalhe,
          ),
          aviso: c.proposta.materialIncluido ? null : 'Material não incluído.',
        ),
        const SizedBox(height: K.s4),
        KLinhaChaveValor(
          rotulo: 'Chegada prevista',
          valor: KFormat.dataHora(
            c.proposta.chegadaPrevista,
            c.agora,
            relogio: false,
          ),
        ),
        if (c.erro != null) ...[
          const SizedBox(height: K.s12),
          KInlineAlert(
            tipo: KAlertaTipo.erro,
            titulo: 'Não foi possível confirmar.',
            mensagem: c.erro!,
          ),
        ],
        const SizedBox(height: K.s4),
        KPrimaryButton(
          rotulo: 'Confirmar proposta',
          aCarregar: c.aConfirmar,
          onPressed: () async {
            final navigator = Navigator.of(context);
            final pedido = await c.confirmar();
            if (pedido != null) navigator.pop(pedido);
          },
        ),
        const SizedBox(height: K.s8),
        Center(
          child: KTextLink(
            rotulo: 'Voltar às propostas',
            onPressed: c.aConfirmar ? null : () => Navigator.of(context).pop(),
          ),
        ),
      ],
    );
  }
}
