import 'package:flutter/material.dart';

import '../theme/k_colors.dart';
import '../theme/k_icons.dart';
import '../theme/k_tokens.dart';
import '../utils/k_format.dart';

/// Cinco estrelas: de leitura (avaliações no 03, pequenas) ou de escolha
/// (06: 48 × 48 dp com 8 dp de intervalo, corrige P16). Preenchidas `ouro`,
/// as restantes `areia300`. A semântica é "4 de 5 estrelas" e, quando
/// interativa, aceita aumentar/diminuir.
class KEstrelas extends StatelessWidget {
  const KEstrelas({super.key, required this.valor, this.onAlterar})
    : assert(valor >= 0 && valor <= total);

  /// 0 a 5.
  final int valor;

  /// Se null, só leitura. Recebe a nova nota (1 a 5).
  final ValueChanged<int>? onAlterar;

  static const total = 5;

  bool get _interativa => onAlterar != null;

  @override
  Widget build(BuildContext context) {
    final tamanho = _interativa ? K.alvoMinimo : K.icone16;
    final intervalo = _interativa ? K.s8 : K.s4;
    return Semantics(
      container: true,
      label: _interativa ? 'Avaliação' : null,
      value: KFormat.estrelas(valor),
      increasedValue: valor < total ? KFormat.estrelas(valor + 1) : null,
      decreasedValue: valor > 1 ? KFormat.estrelas(valor - 1) : null,
      onIncrease: _interativa && valor < total
          ? () => onAlterar!(valor + 1)
          : null,
      onDecrease: _interativa && valor > 1 ? () => onAlterar!(valor - 1) : null,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 1; i <= total; i++) ...[
            if (i > 1) SizedBox(width: intervalo),
            _Estrela(
              cheia: i <= valor,
              tamanho: tamanho,
              onTap: _interativa ? () => onAlterar!(i) : null,
            ),
          ],
        ],
      ),
    );
  }
}

class _Estrela extends StatelessWidget {
  const _Estrela({required this.cheia, required this.tamanho, this.onTap});

  final bool cheia;
  final double tamanho;
  final VoidCallback? onTap;

  /// O glifo tem folga interna; compensa-se para a estrela encher o alvo.
  static const _escala = 1.08;

  @override
  Widget build(BuildContext context) {
    final icone = SizedBox.square(
      dimension: tamanho,
      child: Transform.scale(
        scale: _escala,
        child: FittedBox(
          child: Icon(
            KIcons.estrela,
            color: cheia ? KColors.ouro : KColors.areia300,
          ),
        ),
      ),
    );
    if (onTap == null) return icone;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: icone,
    );
  }
}
