import 'package:flutter/material.dart';

import '../../../core/theme/k_icons.dart';
import '../../../core/theme/k_tokens.dart';
import '../../../core/theme/k_typography.dart';
import '../../../core/utils/k_format.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/pedido.dart';

/// Proposta já aceite no detalhe 04 (QA, F4): selo "ACEITE", valor fechado,
/// chegada prevista e as ações que fazem sentido depois de aceitar. Sem
/// botão de aceitar.
class PedidoDetalheAceiteCartao extends StatelessWidget {
  const PedidoDetalheAceiteCartao({
    super.key,
    required this.pedido,
    required this.agora,
    required this.onConversa,
    this.onVerQr,
    this.onDesfazer,
  });

  final Pedido pedido;
  final DateTime agora;
  final VoidCallback onConversa;

  /// null quando o serviço já foi confirmado.
  final VoidCallback? onVerQr;

  /// null quando já passou a janela de 5 minutos.
  final VoidCallback? onDesfazer;

  @override
  Widget build(BuildContext context) {
    final proposta = pedido.propostaAceite;
    final pro = proposta?.profissional ?? pedido.profissional;
    final nome = proposta?.nomeVisivel ?? pro?.nome ?? 'Profissional';
    final valor = pedido.valor ?? proposta?.valor;
    return KCard(
      destacado: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(alignment: Alignment.centerLeft, child: KStatusBadge.aceite()),
          const SizedBox(height: K.s12),
          Row(
            children: [
              KAvatar(nome: pro?.nome ?? nome),
              const SizedBox(width: K.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nome, style: KTypography.nomeLista),
                    if (proposta != null)
                      KRatingInline(
                        valor: proposta.profissional.rating,
                        sufixo: KFormat.chegadaEm(
                          proposta.chegadaPrevista,
                          agora,
                        ),
                      ),
                  ],
                ),
              ),
              if (valor != null) ...[
                const SizedBox(width: K.s8),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: KPriceText(valor),
                  ),
                ),
              ],
            ],
          ),
          if (proposta != null) ...[
            const SizedBox(height: K.s8),
            KIncluiBox(
              texto: KFormat.inclui(proposta.inclui),
              aviso: proposta.materialIncluido
                  ? null
                  : 'Material não incluído.',
            ),
          ],
          const SizedBox(height: K.s12),
          if (onVerQr != null) ...[
            KPrimaryButton(
              rotulo: 'Ver código QR',
              icone: KIcons.codigoQr,
              onPressed: onVerQr,
            ),
            const SizedBox(height: K.s8),
          ],
          KSecondaryButton(
            rotulo: 'Conversa',
            icone: KIcons.conversa,
            onPressed: onConversa,
          ),
          if (onDesfazer != null)
            Center(
              child: KTextLink(
                rotulo: 'Desfazer aceitação (até 5 min)',
                onPressed: onDesfazer,
              ),
            ),
        ],
      ),
    );
  }
}
