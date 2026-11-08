import 'package:flutter/material.dart';

import '../../../core/theme/k_colors.dart';
import '../../../core/theme/k_tokens.dart';
import '../../../core/theme/k_typography.dart';

/// Mapa estático desenhado à mão (ecrã 22, sem pacote de mapas): quarteirões
/// areia com ruas brancas, e um ponto verde com a posição de quem usa a app
/// e a legenda "Está aqui".
/// É decoração: o leitor de ecrã ignora-o.
class MapaEstatico extends StatelessWidget {
  const MapaEstatico({super.key});

  /// Posição do ponto "você está aqui", em fração do mapa.
  static const utilizadorX = .51;
  static const utilizadorY = .5775;
  static const _ponto = K.s12 + K.s4;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: LayoutBuilder(
        builder: (context, caixa) => Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _RuasPainter())),
            Positioned(
              left: caixa.maxWidth * utilizadorX - _ponto / 2,
              top: caixa.maxHeight * utilizadorY - _ponto / 2,
              child: Container(
                width: _ponto,
                height: _ponto,
                decoration: BoxDecoration(
                  color: KColors.sucesso,
                  shape: BoxShape.circle,
                  border: Border.all(color: KColors.branco, width: K.s4 / 2),
                ),
              ),
            ),
            Positioned(
              left: caixa.maxWidth * utilizadorX + _ponto / 2 + K.s4,
              top: caixa.maxHeight * utilizadorY - K.s12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: K.s8,
                  vertical: K.s4 / 2,
                ),
                decoration: BoxDecoration(
                  color: KColors.branco,
                  borderRadius: BorderRadius.circular(K.raioPilula),
                  border: Border.all(color: KColors.areia400),
                ),
                child: Text(
                  'Está aqui',
                  style: KTypography.corpo13.copyWith(
                    color: KColors.ebano,
                    fontWeight: FontWeight.w700,
                  ),
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

  // Medidas do Figma (dp): ruas de 10 dp, a cada 88 dp na vertical (a
  // primeira em 30) e a cada 170 dp na horizontal (a primeira em 145).
  static const _rua = K.s8 + K.s4 / 2;
  static const _origemX = 30.0;
  static const _passoX = 88.0;
  static const _origemY = 145.0;
  static const _passoY = 170.0;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = KColors.areia100);
    final rua = Paint()..color = KColors.branco;
    for (var x = _origemX; x < size.width; x += _passoX) {
      canvas.drawRect(Rect.fromLTWH(x, 0, _rua, size.height), rua);
    }
    for (var y = _origemY; y < size.height; y += _passoY) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, _rua), rua);
    }
  }

  @override
  bool shouldRepaint(_RuasPainter oldDelegate) => false;
}
