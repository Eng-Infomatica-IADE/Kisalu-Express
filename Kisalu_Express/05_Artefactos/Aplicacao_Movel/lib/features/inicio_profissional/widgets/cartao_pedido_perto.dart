import 'package:flutter/material.dart';

import '../../../core/theme/k_colors.dart';
import '../../../core/theme/k_icons.dart';
import '../../../core/theme/k_tokens.dart';
import '../../../core/theme/k_typography.dart';
import '../../../core/utils/k_format.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/estado_pedido.dart';
import '../../../models/pedido_perto.dart';

/// Pedido de um cliente perto do profissional (ecrã 14): só mostra a zona e
/// a distância, nunca a morada nem o contacto (RNF10). "Ver pedido" leva ao
/// ecrã 15.
class CartaoPedidoPerto extends StatelessWidget {
  const CartaoPedidoPerto({
    super.key,
    required this.pedido,
    required this.agora,
    required this.onVer,
  });

  final PedidoPerto pedido;
  final DateTime agora;
  final VoidCallback onVer;

  @override
  Widget build(BuildContext context) {
    final detalhe =
        '${pedido.zona} · ${KFormat.km(pedido.distanciaKm)} · '
        '${KFormat.quandoLista(pedido.quando, agora)}';
    return KCard(
      padding: const EdgeInsets.fromLTRB(K.s16, K.s16, K.s16, K.s8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: K.iconeQuadrado,
                height: K.iconeQuadrado,
                decoration: BoxDecoration(
                  color: KColors.tomClaro,
                  borderRadius: BorderRadius.circular(K.raioBotao),
                ),
                child: ExcludeSemantics(
                  child: Icon(
                    KIcons.categoria(pedido.categoriaId),
                    size: K.icone24,
                    color: KColors.brasa,
                  ),
                ),
              ),
              const SizedBox(width: K.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pedido.titulo, style: KTypography.nomeLista),
                    Text(
                      detalhe,
                      style: KTypography.corpo13.copyWith(
                        color: KColors.neutro500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: K.s4),
          Row(
            children: [
              Expanded(
                // O NOVO leva também o tempo, para se saber há quanto chegou.
                child: pedido.novo
                    ? Wrap(
                        spacing: K.s8,
                        runSpacing: K.s4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          KStatusBadge.estado(
                            EstadoPedido.novo,
                            compacta: true,
                          ),
                          Text(
                            KFormat.haTempo(pedido.publicadoEm, agora),
                            style: KTypography.corpo13.copyWith(
                              color: KColors.neutro500,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        KFormat.haTempo(pedido.publicadoEm, agora),
                        style: KTypography.corpo13.copyWith(
                          color: KColors.neutro500,
                        ),
                      ),
              ),
              KPilulaAcao(
                rotulo: 'Ver pedido',
                larga: true,
                rotuloSemantico: 'Ver pedido ${pedido.titulo}',
                onPressed: onVer,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
