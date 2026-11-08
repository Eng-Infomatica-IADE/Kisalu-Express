import 'package:flutter/material.dart';

import '../theme/k_tokens.dart';
import 'k_text_link.dart';

/// Título de secção (Título 2) com uma ligação opcional à direita
/// ("Serviços · Ver todos" no 02, "Trabalhos feitos · Ver todos (41)" no 03)
/// ou um widget livre em [acessorio] (chip "Mapa" no 02).
class KSecaoTitulo extends StatelessWidget {
  const KSecaoTitulo({
    super.key,
    required this.titulo,
    this.rotuloAcao,
    this.onAcao,
    this.acessorio,
  }) : assert(acessorio == null || rotuloAcao == null);

  final String titulo;
  final String? rotuloAcao;
  final VoidCallback? onAcao;
  final Widget? acessorio;

  @override
  Widget build(BuildContext context) {
    final direita =
        acessorio ??
        (rotuloAcao == null
            ? null
            : KTextLink(rotulo: rotuloAcao!, onPressed: onAcao, pequeno: true));
    // Direita flexível: a 200 % a ligação quebra linha em vez de transbordar.
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Semantics(
            header: true,
            child: Text(titulo, style: Theme.of(context).textTheme.titleSmall),
          ),
        ),
        if (direita != null) ...[
          const SizedBox(width: K.s8),
          Flexible(
            flex: 2,
            child: Align(alignment: Alignment.centerRight, child: direita),
          ),
        ],
      ],
    );
  }
}
