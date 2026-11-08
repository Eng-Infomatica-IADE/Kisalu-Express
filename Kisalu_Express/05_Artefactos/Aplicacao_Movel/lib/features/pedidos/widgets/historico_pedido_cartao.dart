import 'package:flutter/material.dart';

import '../../../core/theme/k_colors.dart';
import '../../../core/theme/k_icons.dart';
import '../../../core/theme/k_tokens.dart';
import '../../../core/theme/k_typography.dart';
import '../../../core/utils/k_format.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/pedido.dart';

/// Cartão de um pedido no histórico (ecrã 07). Só é tocável inteiro se tiver
/// um único destino ([onTap], pedidos em curso); com ações no rodapé, cada
/// uma é um alvo próprio e o cartão fica dentro de outro, como no Figma.
class HistoricoPedidoCartao extends StatelessWidget {
  const HistoricoPedidoCartao({
    super.key,
    required this.pedido,
    required this.agora,
    this.onTap,
    this.onPedirDeNovo,
    this.onVerComprovativo,
    this.onAvaliar,
  });

  final Pedido pedido;
  final DateTime agora;
  final VoidCallback? onTap;
  final VoidCallback? onPedirDeNovo;
  final VoidCallback? onVerComprovativo;

  /// Concluído e ainda não avaliado (RF12).
  final VoidCallback? onAvaliar;

  static const _fracaoDireita = .45; // da largura do ecrã
  static const _alturaRodape = K.s32;
  static const _padding = EdgeInsets.symmetric(
    horizontal: K.s12 + K.s4 / 2,
    vertical: K.s16 - 1,
  );

  bool get _temAcoes =>
      onPedirDeNovo != null || onVerComprovativo != null || onAvaliar != null;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final quando = KFormat.dataCurta(pedido.data, agora);
    // O cliente vê o profissional; o profissional vê o cliente.
    final outro = pedido.profissional?.nomeCurto ?? pedido.cliente;
    final subtitulo = outro == null ? quando : '$outro · $quando';

    final cartao = KCard(
      onTap: onTap,
      padding: _padding,
      rotuloSemantico: '${pedido.tituloNaLista}, $subtitulo',
      child: Row(
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
                Text(pedido.tituloNaLista, style: KTypography.nomeLista),
                Text(
                  subtitulo,
                  style: text.bodySmall!.copyWith(
                    color: KColors.neutro500,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: K.s8),
          // Com texto a 200 % o preço e o estado quebram linha em vez de
          // empurrar o título para fora do cartão.
          Builder(
            builder: (context) => ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * _fracaoDireita,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (pedido.valor != null)
                    KPriceText(pedido.valor!, tamanho: KPriceText.lista),
                  const SizedBox(height: K.s4),
                  KStatusBadge.estado(pedido.estado, compacta: true),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (!_temAcoes) return cartao;
    return KCard(
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: _alturaRodape),
            child: cartao,
          ),
          // O alvo de 48 dp entra na folga inferior do cartão de dentro.
          Positioned(
            left: K.s16,
            right: K.s16,
            bottom: 0,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (onPedirDeNovo != null)
                  KTextLink(
                    rotulo: 'Pedir de novo',
                    icone: KIcons.pedirDeNovo,
                    onPressed: onPedirDeNovo,
                  ),
                if (onAvaliar != null)
                  KTextLink(
                    rotulo: 'Avaliar',
                    icone: KIcons.avaliacoes,
                    onPressed: onAvaliar,
                  ),
                if (onVerComprovativo != null)
                  KTextLink(
                    rotulo: 'Ver comprovativo',
                    onPressed: onVerComprovativo,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
