import 'package:flutter/material.dart';

import '../../../core/theme/k_colors.dart';
import '../../../core/theme/k_icons.dart';
import '../../../core/theme/k_tokens.dart';
import '../../../core/utils/k_format.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/estado_pedido.dart';
import '../../../models/pedido.dart';
import 'pedido_detalhe_mapa.dart';

/// Cartão do pedido (04): badges, título, descrição, zona, quando e mapa.
class PedidoDetalheCartao extends StatelessWidget {
  const PedidoDetalheCartao({
    super.key,
    required this.pedido,
    required this.agora,
  });

  final Pedido pedido;
  final DateTime agora;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final comPropostas =
        pedido.estado == EstadoPedido.novo && pedido.propostas.isNotEmpty;
    return KCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: K.s8,
            runSpacing: K.s8,
            children: [
              KStatusBadge.estado(pedido.estado),
              if (comPropostas) KStatusBadge.propostas(pedido.propostas.length),
            ],
          ),
          const SizedBox(height: K.s8 + K.s4 / 2),
          Text(pedido.titulo, style: text.titleLarge),
          if (pedido.descricao.isNotEmpty) ...[
            const SizedBox(height: K.s8 + 1),
            Text(
              pedido.descricao,
              style: text.bodyMedium!.copyWith(color: KColors.neutro700),
            ),
          ],
          const SizedBox(height: K.s8 + K.s4 / 2),
          Wrap(
            spacing: K.s16,
            runSpacing: K.s8,
            children: [
              if (pedido.zona.isNotEmpty)
                KLinhaIcone(icone: KIcons.localizacao, texto: pedido.zona),
              KLinhaIcone(
                icone: KIcons.calendario,
                texto: KFormat.quandoPedido(pedido.quando, agora),
              ),
            ],
          ),
          const SizedBox(height: K.s8 + 1),
          const PedidoDetalheMapa(),
        ],
      ),
    );
  }
}
