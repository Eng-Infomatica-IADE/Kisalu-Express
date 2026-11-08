import 'package:flutter/material.dart';

import '../../../core/theme/k_colors.dart';
import '../../../core/theme/k_tokens.dart';
import '../../../core/widgets/widgets.dart';

/// Mapa estático (placeholder): fundo `areia100`, grelha de ruas branca e pin
/// da marca. Mostra só a zona aproximada, nunca a morada (RNF10).
class PedidoDetalheMapa extends StatelessWidget {
  const PedidoDetalheMapa({super.key});

  static const _altura = 90.0;
  static const _pinLargura = K.s24 - K.s4 / 2;
  static const _pinAltura = K.s32;
  static const _pinTopo = K.s16 + K.s4 + 1;

  /// Posição horizontal do pin (-1 a 1), medida no Figma.
  static const _pinX = -.044;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Mapa da zona aproximada do pedido',
      image: true,
      excludeSemantics: true,
      child: SizedBox(
        height: _altura,
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(K.raioMiniatura),
                child: const CustomPaint(painter: _RuasPainter()),
              ),
            ),
            Positioned.fill(
              top: _pinTopo,
              child: const Align(
                alignment: Alignment(_pinX, -1),
                child: KisaluMark(
                  largura: _pinLargura,
                  altura: _pinAltura,
                  cor: KColors.laranja,
                  corLetra: KColors.branco,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RuasPainter extends CustomPainter {
  const _RuasPainter();

  // Eixo das ruas em fração do mapa (medidas do Figma).
  static const _verticais = [0.136, 0.42, 0.705];
  static const _horizontais = [0.31, 0.53, 0.75];
  static const _largura = K.s4 + K.s4 / 2;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = KColors.areia100);
    final rua = Paint()..color = KColors.branco;
    for (final f in _verticais) {
      canvas.drawRect(
        Rect.fromLTWH(size.width * f - _largura / 2, 0, _largura, size.height),
        rua,
      );
    }
    for (final f in _horizontais) {
      canvas.drawRect(
        Rect.fromLTWH(0, size.height * f - _largura / 2, size.width, _largura),
        rua,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RuasPainter oldDelegate) => false;
}
