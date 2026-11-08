import 'package:flutter/material.dart';

import '../../../core/theme/k_colors.dart';
import '../../../core/theme/k_tokens.dart';
import '../../../core/utils/k_format.dart';
import '../../../models/mensagem.dart';

/// Mensagem da conversa (ecrã 19): as minhas à direita em laranja, as do
/// outro à esquerda em branco, com a hora por baixo.
class BolhaMensagem extends StatelessWidget {
  const BolhaMensagem({super.key, required this.mensagem});

  final Mensagem mensagem;

  /// Fração máxima da largura ocupada por uma bolha.
  static const _fracaoMaxima = .72;

  @override
  Widget build(BuildContext context) {
    final minha = mensagem.minha;
    const raio = Radius.circular(K.raioCategoria);
    const ponta = Radius.circular(K.s4 + K.s4 / 2);
    final forma = BorderRadius.only(
      topLeft: raio,
      topRight: raio,
      bottomLeft: minha ? raio : ponta,
      bottomRight: minha ? ponta : raio,
    );
    final hora =
        KFormat.horaRelogio(mensagem.enviadaEm) +
        (minha && mensagem.lida ? ' · Lida' : '');
    return Semantics(
      label: '${minha ? 'Você' : 'Eles'}: ${mensagem.texto}, $hora',
      excludeSemantics: true,
      child: Align(
        alignment: minha ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * _fracaoMaxima,
          ),
          child: Column(
            crossAxisAlignment: minha
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: K.s12 + K.s4 / 2,
                  vertical: K.s8 + 2,
                ),
                decoration: BoxDecoration(
                  color: minha ? KColors.laranja : KColors.branco,
                  borderRadius: forma,
                  border: minha ? null : Border.all(color: KColors.areia200),
                ),
                child: Text(
                  mensagem.texto,
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    color: minha ? KColors.branco : KColors.ebano,
                    height: 21 / 16,
                  ),
                ),
              ),
              const SizedBox(height: K.s4),
              Text(
                hora,
                style: Theme.of(context).textTheme.bodySmall!
                    .copyWith(color: KColors.neutro500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
