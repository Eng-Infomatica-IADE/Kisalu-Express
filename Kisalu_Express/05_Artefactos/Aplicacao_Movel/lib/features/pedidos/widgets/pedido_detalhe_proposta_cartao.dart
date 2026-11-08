import 'package:flutter/material.dart';

import '../../../core/theme/k_tokens.dart';
import '../../../core/theme/k_typography.dart';
import '../../../core/utils/k_format.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/proposta.dart';

/// Cartão de proposta (04): todos iguais; o primeiro vem `destacado`.
class PedidoDetalhePropostaCartao extends StatelessWidget {
  const PedidoDetalhePropostaCartao({
    super.key,
    required this.proposta,
    required this.agora,
    required this.destacado,
    required this.onVerPerfil,
    required this.onAceitar,
    this.onRecusar,
  });

  final Proposta proposta;
  final DateTime agora;
  final bool destacado;
  final VoidCallback onVerPerfil;
  final VoidCallback? onAceitar;

  /// "Recusar" (RF05); null quando já não se pode responder.
  final VoidCallback? onRecusar;

  @override
  Widget build(BuildContext context) {
    final pro = proposta.profissional;
    return KCard(
      destacado: destacado,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                flex: 2,
                child: Semantics(
                  button: true,
                  label: 'Ver perfil de ${pro.nome}',
                  excludeSemantics: true,
                  onTap: onVerPerfil,
                  child: InkWell(
                    onTap: onVerPerfil,
                    borderRadius: BorderRadius.circular(K.raioMiniatura),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minHeight: K.alvoMinimo,
                      ),
                      child: Row(
                        children: [
                          KAvatar(nome: pro.nome),
                          const SizedBox(width: K.s12),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  proposta.nomeVisivel,
                                  style: KTypography.nomeLista,
                                ),
                                KRatingInline(
                                  valor: pro.rating,
                                  sufixo: KFormat.chegadaEm(
                                    proposta.chegadaPrevista,
                                    agora,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: K.s8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: KPriceText(proposta.valor),
                ),
              ),
            ],
          ),
          const SizedBox(height: K.s8),
          KIncluiBox(
            texto: KFormat.inclui(proposta.inclui),
            aviso: proposta.materialIncluido ? null : 'Material não incluído.',
          ),
          const SizedBox(height: K.s12),
          KPrimaryButton(rotulo: 'Ver e aceitar', onPressed: onAceitar),
          if (onRecusar != null) ...[
            const SizedBox(height: K.s8),
            KSecondaryButton(rotulo: 'Recusar', onPressed: onRecusar),
          ],
        ],
      ),
    );
  }
}
