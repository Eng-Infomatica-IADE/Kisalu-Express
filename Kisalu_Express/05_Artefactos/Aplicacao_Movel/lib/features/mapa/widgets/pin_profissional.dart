import 'package:flutter/material.dart';

import '../../../core/theme/k_colors.dart';
import '../../../core/theme/k_tokens.dart';
import '../../../core/widgets/widgets.dart';

/// Pin de um profissional no mapa (ecrã 22): o logótipo Kisalu, laranja se
/// estiver selecionado e cinzento se não. O alvo de toque é de 48 dp e a
/// ponta do pin fica no centro da base.
class PinProfissional extends StatelessWidget {
  const PinProfissional({
    super.key,
    required this.nome,
    required this.selecionado,
    required this.onTap,
  });

  final String nome;
  final bool selecionado;
  final VoidCallback onTap;

  // Largura do pin; a altura segue a proporção do logótipo.
  static const _larguraSelecionado = K.icone32 - 2;
  static const _larguraNormal = K.icone24 - 1;

  @override
  Widget build(BuildContext context) {
    final largura = selecionado ? _larguraSelecionado : _larguraNormal;
    final altura = largura * K.markAltura / K.markLargura;
    return Semantics(
      button: true,
      selected: selecionado,
      label: 'Ver $nome no mapa',
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: K.alvoMinimo,
          height: K.alvoMinimo + K.s4,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: KisaluMark(
              largura: largura,
              altura: altura,
              cor: selecionado ? KColors.laranja : KColors.neutro500,
              corLetra: KColors.branco,
              rotulo: nome,
            ),
          ),
        ),
      ),
    );
  }
}
