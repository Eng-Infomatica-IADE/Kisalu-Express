import 'package:flutter/material.dart';

import '../theme/k_colors.dart';
import '../theme/k_tokens.dart';

/// Logótipo isolado da Kisalu: um pin com a letra K.
///
/// O desenho mantém a proporção do logótipo em qualquer tamanho. A área
/// continua a ser suficientemente grande para não ser confundida com um
/// controlo tocável quando o mark é usado como decoração.
class KisaluMark extends StatelessWidget {
  const KisaluMark({
    super.key,
    this.largura = K.markLargura,
    this.altura = K.markAltura,
    this.cor = KColors.branco,
    this.corLetra,
    this.rotulo = 'Kisalu',
  });

  final double largura;
  final double altura;
  final Color cor;
  final Color? corLetra;
  final String rotulo;

  @override
  Widget build(BuildContext context) {
    final letra =
        corLetra ?? (cor == KColors.branco ? KColors.brasa : KColors.ebano);
    return Semantics(
      label: rotulo,
      image: true,
      child: SizedBox(
        width: largura,
        height: altura,
        child: Stack(
          fit: StackFit.expand,
          children: [CustomPaint(painter: _KisaluMarkPainter(cor, letra))],
        ),
      ),
    );
  }
}

class _KisaluMarkPainter extends CustomPainter {
  const _KisaluMarkPainter(this.cor, this.corLetra);

  final Color cor;
  final Color corLetra;

  @override
  void paint(Canvas canvas, Size size) {
    final escalaX = size.width / K.markLargura;
    final escalaY = size.height / K.markAltura;
    canvas.save();
    canvas.scale(escalaX, escalaY);
    final path = Path()
      ..moveTo(29.5, 0)
      ..cubicTo(45.8, 0, 59, 12, 59, 28)
      ..lineTo(59, 46)
      ..lineTo(34, 82)
      ..quadraticBezierTo(29.5, 88, 25, 82)
      ..lineTo(0, 46)
      ..lineTo(0, 28)
      ..cubicTo(0, 12, 13.2, 0, 29.5, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = cor);

    final letra = Path()
      ..moveTo(14, 15)
      ..lineTo(23, 15)
      ..lineTo(23, 28)
      ..lineTo(33, 15)
      ..lineTo(44, 15)
      ..lineTo(31.5, 30)
      ..lineTo(45, 47)
      ..lineTo(34, 47)
      ..lineTo(23, 34)
      ..lineTo(23, 47)
      ..lineTo(14, 47)
      ..close();
    canvas.drawPath(letra, Paint()..color = corLetra);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_KisaluMarkPainter oldDelegate) =>
      oldDelegate.cor != cor || oldDelegate.corLetra != corLetra;
}
