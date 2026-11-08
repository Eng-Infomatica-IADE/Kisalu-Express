import 'package:flutter/material.dart';

import '../../../core/theme/k_colors.dart';
import '../../../core/theme/k_tokens.dart';
import '../../../core/theme/k_typography.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/categoria.dart';

/// "Que serviços presta?": chips de multisseleção e "Mais…" (ecrã 12).
class EscolhaServicos extends StatelessWidget {
  const EscolhaServicos({
    super.key,
    required this.categorias,
    required this.escolhidos,
    required this.onAlternar,
    required this.onMais,
    this.mostrarMais = true,
    this.erro,
  });

  final List<Categoria> categorias;
  final Set<String> escolhidos;
  final ValueChanged<String> onAlternar;
  final VoidCallback onMais;

  /// false depois de "Mais…" (já estão todos).
  final bool mostrarMais;
  final String? erro;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Que serviços presta?',
          style: KTypography.corpo13.copyWith(
            color: KColors.neutro700,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: K.s4),
        Wrap(
          spacing: K.s8,
          runSpacing: K.chipEntreLinhas,
          children: [
            for (final c in categorias)
              // Selecionado a Ébano, como os chips do ecrã 15 (v3.1).
              KChip(
                rotulo: c.nome,
                variante: KChipVariante.filtro,
                maior: true,
                selecionado: escolhidos.contains(c.id),
                onSelecionar: (_) => onAlternar(c.id),
              ),
            if (mostrarMais)
              KChip(
                rotulo: 'Mais…',
                variante: KChipVariante.etiqueta,
                maior: true,
                onSelecionar: (_) => onMais(),
              ),
          ],
        ),
        if (erro != null)
          Padding(
            padding: const EdgeInsets.only(top: K.s4),
            child: KMensagemErro(erro!),
          ),
      ],
    );
  }
}
