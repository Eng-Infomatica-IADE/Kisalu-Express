import 'package:flutter/material.dart';

import '../../../core/theme/k_colors.dart';
import '../../../core/theme/k_tokens.dart';
import '../../../core/theme/k_typography.dart';
import '../../../core/utils/k_format.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/conversa.dart';

/// Linha da lista de conversas (ecrã 18): avatar, nome, última mensagem,
/// hora e, se houver, o número de mensagens por ler.
class ConversaLinha extends StatelessWidget {
  const ConversaLinha({
    super.key,
    required this.conversa,
    required this.agora,
    required this.onTap,
  });

  final Conversa conversa;
  final DateTime agora;
  final VoidCallback onTap;

  static const _badge = K.s24 - 2;

  @override
  Widget build(BuildContext context) {
    final ultima = conversa.ultima;
    final naoLida = conversa.naoLidas > 0;
    final nome = conversa.interlocutor.nome;
    final quando = ultima == null
        ? ''
        : KFormat.quandoConversa(ultima.enviadaEm, agora);
    final texto = ultima?.texto ?? '';
    final rotulo =
        '$nome, $texto, $quando'
        '${naoLida ? ', ${conversa.naoLidas} por ler' : ''}';
    return Semantics(
      button: true,
      label: rotulo,
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: K.s12 + K.s4 / 2,
            vertical: K.s12,
          ),
          child: Row(
            children: [
              KAvatar(nome: nome, tamanho: K.avatarCartao),
              const SizedBox(width: K.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nome, style: KTypography.nomeLista),
                    Text(
                      texto,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: naoLida ? KColors.ebano : KColors.neutro500,
                        fontWeight: naoLida ? FontWeight.w500 : null,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: K.s8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    quando,
                    style: KTypography.corpo13.copyWith(
                      color: KColors.neutro500,
                    ),
                  ),
                  if (naoLida) ...[
                    const SizedBox(height: K.s4),
                    Container(
                      constraints: const BoxConstraints(
                        minWidth: _badge,
                        minHeight: _badge,
                      ),
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: KColors.laranja,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${conversa.naoLidas}',
                        style: KTypography.corpo13.copyWith(
                          color: KColors.branco,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
