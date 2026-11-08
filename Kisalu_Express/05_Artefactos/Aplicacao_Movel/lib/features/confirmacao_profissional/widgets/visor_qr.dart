import 'package:flutter/material.dart';

import '../../../core/theme/k_colors.dart';
import '../../../core/theme/k_tokens.dart';

/// Visor estático do ecrã 16: quatro cantos laranja e uma linha de leitura.
/// É só desenho (sem câmara, RM03): o nome acessível diz como confirmar.
class VisorQr extends StatelessWidget {
  const VisorQr({super.key});

  /// Lado do quadrado do visor, medido no Figma.
  static const lado = 248.0;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label:
          'Visor da câmara. Aponte para o código do cliente ou escreva o '
          'código abaixo.',
      child: SizedBox.square(
        dimension: lado,
        child: CustomPaint(painter: _VisorPainter()),
      ),
    );
  }
}

class _VisorPainter extends CustomPainter {
  const _VisorPainter();

  static const _braco = 58.0;
  static const _raio = K.s24;
  static const _espessura = 4.0;
  static const _margemLinha = K.s24 - K.s4;

  @override
  void paint(Canvas canvas, Size size) {
    final cantos = Paint()
      ..color = KColors.laranjaVivo
      ..style = PaintingStyle.stroke
      ..strokeWidth = _espessura
      ..strokeCap = StrokeCap.round;
    final w = size.width;
    final h = size.height;

    final caminho = Path()
      // Superior esquerdo
      ..moveTo(0, _braco)
      ..lineTo(0, _raio)
      ..quadraticBezierTo(0, 0, _raio, 0)
      ..lineTo(_braco, 0)
      // Superior direito
      ..moveTo(w - _braco, 0)
      ..lineTo(w - _raio, 0)
      ..quadraticBezierTo(w, 0, w, _raio)
      ..lineTo(w, _braco)
      // Inferior direito
      ..moveTo(w, h - _braco)
      ..lineTo(w, h - _raio)
      ..quadraticBezierTo(w, h, w - _raio, h)
      ..lineTo(w - _braco, h)
      // Inferior esquerdo
      ..moveTo(_braco, h)
      ..lineTo(_raio, h)
      ..quadraticBezierTo(0, h, 0, h - _raio)
      ..lineTo(0, h - _braco);
    canvas.drawPath(caminho, cantos);

    canvas.drawLine(
      Offset(_margemLinha, h / 2),
      Offset(w - _margemLinha, h / 2),
      cantos,
    );
  }

  @override
  bool shouldRepaint(_VisorPainter oldDelegate) => false;
}
