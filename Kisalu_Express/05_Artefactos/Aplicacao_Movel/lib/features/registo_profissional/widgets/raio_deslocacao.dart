import 'package:flutter/material.dart';

import '../../../core/theme/k_colors.dart';
import '../../../core/theme/k_tokens.dart';
import '../../../core/theme/k_typography.dart';
import '../controllers/registo_profissional_controller.dart';

/// "Raio de deslocação · 10 km" com cursor (ecrã 12). O cursor tem alvo de
/// 48 dp e nome acessível com o valor atual.
class RaioDeslocacao extends StatelessWidget {
  const RaioDeslocacao({super.key, required this.km, required this.onMudar});

  final int km;
  final ValueChanged<double> onMudar;

  @override
  Widget build(BuildContext context) {
    final legenda = KTypography.corpo13.copyWith(
      color: KColors.neutro700,
      fontWeight: FontWeight.w500,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text('Raio de deslocação', style: legenda)),
            Text(
              '$km km',
              style: legenda.copyWith(
                color: KColors.laranja,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: K.s4,
            activeTrackColor: KColors.laranja,
            inactiveTrackColor: KColors.areia200,
            thumbColor: KColors.laranja,
            overlayColor: KColors.tomClaro,
            thumbShape: const RoundSliderThumbShape(
              // Cursor de 24 dp (v3.1), mais fácil de agarrar.
              enabledThumbRadius: K.s12,
            ),
            trackShape: const _PistaCompleta(),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: K.s16),
          ),
          child: Semantics(
            label: 'Raio de deslocação, $km km',
            // Alvo de 48 dp; sobe 4 dp para o cursor ficar como no Figma.
            child: Transform.translate(
              offset: const Offset(0, -K.s4),
              child: SizedBox(
                height: K.alvoMinimo,
                child: Slider(
                  value: km.toDouble(),
                  min: RegistoProfissionalController.raioMinimo.toDouble(),
                  max: RegistoProfissionalController.raioMaximo.toDouble(),
                  onChanged: onMudar,
                ),
              ),
            ),
          ),
        ),
        // Limites do raio, para se saber até onde se pode ir.
        ExcludeSemantics(
          child: Transform.translate(
            offset: const Offset(0, -K.s8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${RegistoProfissionalController.raioMinimo} km',
                  style: KTypography.corpo13.copyWith(color: KColors.neutro500),
                ),
                Text(
                  '${RegistoProfissionalController.raioMaximo} km',
                  style: KTypography.corpo13.copyWith(color: KColors.neutro500),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Pista que ocupa a largura toda (a normal deixa uma margem do tamanho do
/// cursor), como no Figma.
class _PistaCompleta extends RoundedRectSliderTrackShape {
  const _PistaCompleta();

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final altura = sliderTheme.trackHeight ?? 0;
    return Rect.fromLTWH(
      offset.dx,
      offset.dy + (parentBox.size.height - altura) / 2,
      parentBox.size.width,
      altura,
    );
  }
}
