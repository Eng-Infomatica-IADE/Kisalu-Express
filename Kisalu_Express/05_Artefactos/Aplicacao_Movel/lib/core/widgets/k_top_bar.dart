import 'package:flutter/material.dart';

import '../theme/k_colors.dart';
import '../theme/k_tokens.dart';
import 'k_back_button.dart';
import 'k_icon_button.dart';

/// Barra de topo dos ecrãs internos: voltar + título + ação opcional à
/// direita (ex. "⋯" com Editar / Cancelar pedido, corrige P12).
/// Dentro dos fluxos o título substitui o logótipo (Style Guide, p. 4).
///
/// Coloca-se no topo do `body` (dentro de `SafeArea`), não em
/// `Scaffold.appBar`: assim cresce com o texto do sistema a 200 % em vez de
/// cortar o título.
class KTopBar extends StatelessWidget {
  const KTopBar({
    super.key,
    required this.titulo,
    this.mostrarVoltar = true,
    this.onVoltar,
    this.acao,
    this.escuro = false,
    this.tituloCentrado = false,
  });

  final String titulo;
  final bool mostrarVoltar;

  /// Por omissão o [KBackButton] volta atrás (ou ao Início).
  final VoidCallback? onVoltar;

  /// Normalmente um [KIconButton] (ex. ícone `KIcons.mais`).
  final Widget? acao;

  /// Sobre fundo Ébano (ecrã 16): título e voltar em versão clara.
  final bool escuro;

  /// Título ao centro (mapa, ecrã 22), em vez de junto ao voltar.
  final bool tituloCentrado;

  static const _folga = (K.alvoMinimo - K.botaoIcone) / 2;

  @override
  Widget build(BuildContext context) {
    final margem = K.margemPara(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: K.appBar),
      child: Padding(
        // O alvo de 48 dp tem 2 dp de folga à volta do quadrado de 44 dp;
        // descontamos para o quadrado ficar alinhado à margem.
        padding: EdgeInsets.symmetric(horizontal: margem - _folga),
        child: Row(
          children: [
            if (mostrarVoltar) ...[
              KBackButton(onPressed: onVoltar, escuro: escuro),
              const SizedBox(width: K.s12 - _folga),
            ] else
              const SizedBox(width: _folga),
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  titulo,
                  textAlign: tituloCentrado ? TextAlign.center : null,
                  style: Theme.of(context).textTheme.titleLarge!
                      .copyWith(color: escuro ? KColors.branco : null),
                ),
              ),
            ),
            if (acao != null) ...[const SizedBox(width: K.s8), acao!],
          ],
        ),
      ),
    );
  }
}
