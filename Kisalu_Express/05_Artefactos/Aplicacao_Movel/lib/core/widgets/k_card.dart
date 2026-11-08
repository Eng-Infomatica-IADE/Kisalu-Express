import 'package:flutter/material.dart';

import '../theme/k_colors.dart';
import '../theme/k_tokens.dart';

/// Cartão base: branco, raio 20, padding 16, contorno `areia100` e sombra de
/// nível 1, como no Figma v2. Só é tocável inteiro se tiver um único destino
/// ([onTap]); com duas ações, cada botão é um alvo separado.
///
/// [destacado]: borda laranja 2 dp, sem sombra (proposta selecionada, 04).
class KCard extends StatelessWidget {
  const KCard({
    super.key,
    required this.child,
    this.onTap,
    this.destacado = false,
    this.padding = const EdgeInsets.all(K.s16),
    this.rotuloSemantico,
    this.plano = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool destacado;
  final EdgeInsetsGeometry padding;

  /// Sem contorno nem sombra (cartão de rever o pedido, ecrã 10).
  final bool plano;

  /// Nome lido pelo leitor de ecrã quando o cartão inteiro é um botão.
  final String? rotuloSemantico;

  @override
  Widget build(BuildContext context) {
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(K.raioCartao),
      side: destacado
          ? const BorderSide(color: KColors.laranja, width: 2)
          : plano
          ? BorderSide.none
          : const BorderSide(color: KColors.areia100),
    );
    final conteudo = Padding(padding: padding, child: child);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(K.raioCartao),
        boxShadow: destacado || plano ? null : K.sombraCartao,
      ),
      child: Material(
        color: KColors.branco,
        shape: forma,
        clipBehavior: Clip.antiAlias,
        child: onTap == null
            ? conteudo
            : Semantics(
                button: true,
                label: rotuloSemantico,
                child: InkWell(
                  onTap: onTap,
                  highlightColor: KColors.areia50,
                  splashColor: KColors.tomClaro,
                  child: conteudo,
                ),
              ),
      ),
    );
  }
}
