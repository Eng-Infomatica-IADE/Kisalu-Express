import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/k_colors.dart';
import '../../../core/theme/k_icons.dart';
import '../../../core/theme/k_tokens.dart';
import '../../../core/utils/k_format.dart';
import '../../../core/validators/k_validators.dart';
import '../../../core/widgets/widgets.dart';
import '../controllers/novo_pedido_controller.dart';

/// Passo 4 · quando precisa do serviço.
class NovoPedidoPassoData extends StatelessWidget {
  const NovoPedidoPassoData({super.key});

  Future<void> _escolher(BuildContext context, NovoPedidoController c) async {
    final agora = c.agora;
    final hoje = DateTime(agora.year, agora.month, agora.day);
    final dia = await showDatePicker(
      context: context,
      initialDate: c.quando ?? hoje,
      firstDate: hoje,
      lastDate: hoje.add(const Duration(days: KValidators.maxDiasDataPedido)),
    );
    if (dia == null || !context.mounted) return;
    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(c.quando ?? agora),
    );
    if (hora == null) return;
    c.escolherData(
      DateTime(dia.year, dia.month, dia.day, hora.hour, hora.minute),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<NovoPedidoController>();
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Quando precisa?', style: text.titleLarge),
        const SizedBox(height: K.s8),
        Align(
          alignment: Alignment.centerLeft,
          child: KChip(
            rotulo: 'O mais cedo possível',
            variante: KChipVariante.etiqueta,
            selecionado: c.maisCedo,
            onSelecionar: (_) => c.escolherMaisCedo(),
          ),
        ),
        const SizedBox(height: K.s8),
        KSecondaryButton(
          rotulo: 'Escolher data e hora',
          icone: KIcons.calendario,
          onPressed: () => _escolher(context, c),
        ),
        if (c.quando != null) ...[
          const SizedBox(height: K.s16),
          KLinhaIcone(
            icone: KIcons.calendario,
            texto: KFormat.dataHora(c.quando!, c.agora),
          ),
        ],
        if (c.erroData != null) ...[
          const SizedBox(height: K.s12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(KIcons.aviso, size: K.icone20, color: KColors.erro),
              const SizedBox(width: K.s8),
              Expanded(
                child: Text(
                  c.erroData!,
                  style: text.bodyMedium!.copyWith(color: KColors.erro),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
