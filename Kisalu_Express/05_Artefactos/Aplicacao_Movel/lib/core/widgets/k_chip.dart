import 'package:flutter/material.dart';

import '../theme/k_colors.dart';
import '../theme/k_tokens.dart';
import '../theme/k_typography.dart';

/// Tipo de chip (Style Guide, cap. 06, p. 12).
enum KChipVariante {
  /// Filtros e ordenação (07: Todos · Em curso…; 04: Preço ↑ · Avaliação…).
  /// Selecionado = fundo Ébano, texto branco.
  filtro,

  /// Etiquetas de multisseleção (06: Pontual · Preço justo…).
  /// Selecionada = fundo laranja, texto branco.
  etiqueta,

  /// Só informação, não clicável (03: especialidades).
  informativo,
}

/// Chip em pílula: 34 dp visíveis dentro de um alvo de toque de 48 dp.
/// O estado selecionado distingue-se pela cor e pela forma (preenchido vs.
/// contorno), nunca só pela cor (RNF05). `onSelecionar: null` → desativado.
class KChip extends StatelessWidget {
  const KChip({
    super.key,
    required this.rotulo,
    this.selecionado = false,
    this.onSelecionar,
    this.icone,
    this.variante = KChipVariante.filtro,
    this.compacto = false,
    this.maior = false,
  });

  final String rotulo;
  final bool selecionado;

  /// Recebe o novo estado (`!selecionado`).
  final ValueChanged<bool>? onSelecionar;
  final IconData? icone;
  final KChipVariante variante;

  /// Menos padding lateral (filtros do histórico, 07).
  final bool compacto;

  /// Texto de 14 sp em vez de 13 (registo do profissional, ecrã 12).
  final bool maior;

  bool get _informativo => variante == KChipVariante.informativo;
  bool get _ativo => _informativo || onSelecionar != null;

  Color _corTexto(Color base) => _ativo ? KColors.neutro700 : base;

  @override
  Widget build(BuildContext context) {
    final preenchido = selecionado && !_informativo;
    final Color fundo = !_ativo
        ? KColors.areia100
        : preenchido
        ? (variante == KChipVariante.etiqueta ? KColors.laranja : KColors.ebano)
        : KColors.branco;
    final Color texto = !_ativo
        ? KColors.neutro500
        : preenchido
        ? KColors.branco
        : KColors.ebano;
    final borda = !_ativo || preenchido
        ? null
        : Border.all(color: KColors.areia400);

    final pilula = AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      constraints: const BoxConstraints(minHeight: K.chipAltura),
      padding: EdgeInsets.symmetric(
        horizontal: compacto ? K.s12 : K.s12 + K.s4 / 2,
        vertical: K.s4,
      ),
      decoration: BoxDecoration(
        color: fundo,
        border: borda,
        borderRadius: BorderRadius.circular(K.raioPilula),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icone != null) ...[
            Icon(icone, size: K.icone16, color: texto),
            const SizedBox(width: K.s4),
          ],
          Flexible(
            child: Text(
              rotulo,
              style:
                  (maior
                          ? Theme.of(context).textTheme.bodyMedium!
                          : KTypography.corpo13)
                      .copyWith(
                        color: preenchido ? texto : _corTexto(texto),
                        fontWeight:
                            preenchido && variante == KChipVariante.filtro
                            ? FontWeight.w700
                            : switch (variante) {
                                KChipVariante.filtro => FontWeight.w700,
                                KChipVariante.etiqueta => FontWeight.w500,
                                KChipVariante.informativo => FontWeight.w400,
                              },
                      ),
            ),
          ),
        ],
      ),
    );

    if (_informativo) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: K.s4),
        child: pilula,
      );
    }

    return Semantics(
      button: true,
      selected: selecionado,
      enabled: _ativo,
      label: rotulo,
      onTap: onSelecionar == null ? null : () => onSelecionar!(!selecionado),
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTap: onSelecionar == null ? null : () => onSelecionar!(!selecionado),
        child: ConstrainedBox(
          // Alvo de 48 dp à volta da pílula de 32 dp.
          constraints: const BoxConstraints(minHeight: K.alvoMinimo),
          child: Center(widthFactor: 1, child: pilula),
        ),
      ),
    );
  }
}
