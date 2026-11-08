import 'package:flutter/material.dart';

import '../theme/k_colors.dart';
import '../theme/k_icons.dart';
import '../theme/k_tokens.dart';

enum KAlertaTipo { erro, aviso, sucesso }

/// Alerta em linha (Style Guide, p. 14): fundo semântico, ícone, **título a
/// negrito** e texto que diz o que aconteceu e o que vem a seguir (RNF07).
/// Anunciado pelo leitor de ecrã quando aparece.
class KInlineAlert extends StatelessWidget {
  const KInlineAlert({
    super.key,
    required this.tipo,
    required this.titulo,
    required this.mensagem,
    this.icone,
  });

  final KAlertaTipo tipo;

  /// Ex.: "Sem ligação."
  final String titulo;

  /// Ex.: "O seu pedido ficou guardado como rascunho…"
  final String mensagem;

  /// Por omissão: aviso (erro e aviso) ou concluído (sucesso).
  final IconData? icone;

  static const _alturaLinha = 18.0 / 14;

  @override
  Widget build(BuildContext context) {
    final (fundo, corTexto, corIcone, iconePadrao) = switch (tipo) {
      KAlertaTipo.erro => (
        KColors.erroFundo,
        KColors.erroPremido,
        KColors.erro,
        KIcons.aviso,
      ),
      KAlertaTipo.aviso => (
        KColors.avisoFundo,
        KColors.avisoTexto,
        KColors.avisoTexto,
        KIcons.aviso,
      ),
      KAlertaTipo.sucesso => (
        KColors.sucessoFundo,
        KColors.sucesso,
        KColors.sucesso,
        KIcons.concluido,
      ),
    };
    final estilo = Theme.of(context).textTheme.bodyMedium!
        .copyWith(color: corTexto, height: _alturaLinha);
    final estiloTitulo = estilo.copyWith(fontWeight: FontWeight.w700);

    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          K.s12 + K.s4 / 2,
          K.s12,
          K.s12 + K.s4 / 2,
          K.s12,
        ),
        decoration: BoxDecoration(
          color: fundo,
          borderRadius: BorderRadius.circular(K.raioBotao),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icone ?? iconePadrao, size: K.icone20, color: corIcone),
            const SizedBox(width: K.s8 + K.s4 / 2),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: titulo, style: estiloTitulo),
                    TextSpan(text: ' $mensagem'),
                  ],
                ),
                style: estilo,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
