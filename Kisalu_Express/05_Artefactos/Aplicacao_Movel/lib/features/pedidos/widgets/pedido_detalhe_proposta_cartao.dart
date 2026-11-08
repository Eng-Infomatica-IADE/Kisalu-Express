import 'package:flutter/material.dart';

import '../../../core/theme/k_colors.dart';
import '../../../core/theme/k_icons.dart';
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
          if (proposta.estimativaChegada case final e?) ...[
            const SizedBox(height: K.s4),
            _LinhaChegaATempo(percentagem: e.percentagemCumprir),
          ],
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

/// "Chega a tempo em ~85% dos casos" (simulação de Monte Carlo). Cor + ícone
/// + texto: verde a partir de 80 %, aviso abaixo disso.
class _LinhaChegaATempo extends StatelessWidget {
  const _LinhaChegaATempo({required this.percentagem});

  final int percentagem;

  static const limiarBom = 80;

  @override
  Widget build(BuildContext context) {
    final bom = percentagem >= limiarBom;
    final cor = bom ? KColors.sucesso : KColors.avisoTexto;
    return Row(
      children: [
        Icon(bom ? KIcons.relogio : KIcons.aviso, size: K.icone16, color: cor),
        const SizedBox(width: K.s4),
        Expanded(
          child: Text(
            'Chega a tempo em ~$percentagem% dos casos',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(color: cor),
          ),
        ),
      ],
    );
  }
}
