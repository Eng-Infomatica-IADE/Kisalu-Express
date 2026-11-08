import 'package:flutter/material.dart';

import '../../../core/theme/k_colors.dart';
import '../../../core/theme/k_tokens.dart';
import '../../../core/theme/k_typography.dart';
import '../../../core/widgets/widgets.dart';

/// Cabeçalho laranja do ecrã 01: círculos decorativos, marca, nome e
/// slogan. [alturaMinima] é ≈ 37,5 % do ecrã; cresce se o texto crescer.
class CabecalhoLogin extends StatelessWidget {
  const CabecalhoLogin({super.key, required this.alturaMinima});

  final double alturaMinima;

  // Círculos decorativos (cortados nas bordas), em dp, medidos no Figma.
  static const _grande = 420.0;
  static const _grandeTopo = -120.0;
  static const _grandeDireita = -180.0;
  static const _pequeno = 260.0;
  static const _pequenoTopo = 250.0;
  static const _pequenoEsquerda = -120.0;

  /// Distância entre o topo da área segura e a marca.
  static const _margemTopo = K.s32 + K.s24 + K.s8;

  @override
  Widget build(BuildContext context) {
    final margem = K.s32;
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: alturaMinima),
      child: ClipRect(
        child: Stack(
          children: [
            const Positioned(
              top: _grandeTopo,
              right: _grandeDireita,
              child: _Circulo(diametro: _grande, cor: KColors.laranjaClaro),
            ),
            const Positioned(
              left: _pequenoEsquerda,
              top: _pequenoTopo,
              child: _Circulo(diametro: _pequeno, cor: KColors.laranjaEscuro),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  margem,
                  _margemTopo,
                  margem,
                  K.s24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const KisaluMark(),
                    const SizedBox(height: K.s16 + K.s4),
                    Semantics(
                      header: true,
                      child: Text(
                        'Kisalu Express',
                        style: KTypography.marca.copyWith(
                          color: KColors.branco,
                        ),
                      ),
                    ),
                    const SizedBox(height: K.s8),
                    Text(
                      'Quem sabe, resolve.',
                      style: KTypography.slogan.copyWith(
                        color: KColors.branco.withValues(alpha: .85),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Circulo extends StatelessWidget {
  const _Circulo({required this.diametro, required this.cor});

  final double diametro;
  final Color cor;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: diametro,
      height: diametro,
      decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
    ),
  );
}
