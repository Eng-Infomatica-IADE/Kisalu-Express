import 'package:flutter/material.dart';

import '../theme/k_colors.dart';
import '../theme/k_tokens.dart';

/// Controlo segmentado para escolhas exclusivas ("Sou cliente" ·
/// "Sou profissional"). Fundo `areia100`; a opção ativa fica num cartão
/// branco a negrito. Cada opção tem alvo ≥ 48 dp.
class KSegmentedControl<T> extends StatelessWidget {
  const KSegmentedControl({
    super.key,
    required this.opcoes,
    required this.valor,
    required this.onMudar,
  });

  final List<(T, String)> opcoes;
  final T valor;
  final ValueChanged<T> onMudar;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(K.s4),
      decoration: BoxDecoration(
        color: KColors.areia100,
        borderRadius: BorderRadius.circular(K.raioBotao + K.s4 / 2),
      ),
      child: Row(
        children: [
          for (final (opcao, rotulo) in opcoes)
            Expanded(
              child: Semantics(
                button: true,
                selected: opcao == valor,
                inMutuallyExclusiveGroup: true,
                label: rotulo,
                onTap: () => onMudar(opcao),
                excludeSemantics: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  excludeFromSemantics: true,
                  onTap: () => onMudar(opcao),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    constraints: const BoxConstraints(
                      minHeight: K.alvoMinimo - K.s8,
                    ),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(
                      horizontal: K.s8,
                      vertical: K.s4,
                    ),
                    decoration: BoxDecoration(
                      color: opcao == valor ? KColors.branco : null,
                      borderRadius: BorderRadius.circular(K.raioMiniatura),
                      boxShadow: opcao == valor ? K.sombraCartao : null,
                    ),
                    child: Text(
                      rotulo,
                      textAlign: TextAlign.center,
                      style: text.bodyMedium!.copyWith(
                        color: opcao == valor
                            ? KColors.ebano
                            : KColors.neutro500,
                        fontWeight: opcao == valor
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
