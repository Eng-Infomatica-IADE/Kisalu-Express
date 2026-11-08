import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/k_icons.dart';
import '../../../core/theme/k_tokens.dart';
import '../../../core/utils/k_format.dart';
import '../../../core/widgets/widgets.dart';
import '../controllers/novo_pedido_controller.dart';

/// Passo 3 · rever o pedido (ecrã 10). Com rede: sem alerta.
class NovoPedidoPassoRever extends StatelessWidget {
  const NovoPedidoPassoRever({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<NovoPedidoController>();
    final text = Theme.of(context).textTheme;
    final fotos = c.numFotos == 1
        ? '1 foto anexada'
        : '${c.numFotos} fotos anexadas';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(c.titulo, style: text.titleLarge),
        const SizedBox(height: K.s12 + K.s4 / 2),
        if (c.semRede) ...[
          const KInlineAlert(
            tipo: KAlertaTipo.erro,
            titulo: 'Sem ligação.',
            mensagem:
                'O seu pedido ficou guardado como rascunho e vamos tentar '
                'enviar outra vez automaticamente.',
          ),
          const SizedBox(height: K.s16),
        ],
        if (c.erroPublicacao != null) ...[
          KInlineAlert(
            tipo: KAlertaTipo.erro,
            titulo: 'Não foi possível publicar.',
            mensagem: c.erroPublicacao!,
          ),
          const SizedBox(height: K.s16),
        ],
        KCard(
          plano: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              KLinhaIcone(
                icone: KIcons.localizacao,
                maior: true,
                texto: '${c.zona} · ${c.pontoReferencia}',
              ),
              const SizedBox(height: K.s8),
              KLinhaIcone(
                icone: KIcons.calendario,
                maior: true,
                texto: KFormat.quandoPedido(c.quando, c.agora),
              ),
              if (c.numFotos > 0) ...[
                const SizedBox(height: K.s8),
                KLinhaIcone(icone: KIcons.foto, maior: true, texto: fotos),
              ],
            ],
          ),
        ),
        if (c.dataEditavel)
          Align(
            alignment: Alignment.centerLeft,
            child: KTextLink(
              rotulo: 'Alterar a data',
              onPressed: c.alterarData,
            ),
          ),
      ],
    );
  }
}
