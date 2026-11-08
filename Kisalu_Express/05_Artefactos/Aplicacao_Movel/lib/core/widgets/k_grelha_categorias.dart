import 'package:flutter/material.dart';

import '../../models/categoria.dart';
import '../theme/k_icons.dart';
import '../theme/k_tokens.dart';
import 'k_category_tile.dart';

/// Grelha 4 × N de categorias (ecrãs 02 e 21): quadrados de largura fixa com
/// o espaço distribuído entre eles, como no Figma. [selecionada] null → nenhuma
/// destacada (21).
class KGrelhaCategorias extends StatelessWidget {
  const KGrelhaCategorias({
    super.key,
    required this.categorias,
    this.selecionada,
    required this.onSelecionar,
  });

  final List<Categoria> categorias;
  final String? selecionada;
  final ValueChanged<Categoria> onSelecionar;

  static const colunas = 4;

  /// Altura do rótulo mais alto, para a célula caber com texto ampliado.
  double _alturaRotulo(BuildContext context) {
    final estilo = Theme.of(context).textTheme.bodySmall!;
    final escalador = MediaQuery.textScalerOf(context);
    var maior = 0.0;
    for (final categoria in categorias) {
      final pintor = TextPainter(
        text: TextSpan(text: categoria.nome, style: estilo),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        textScaler: escalador,
      )..layout(maxWidth: K.categoriaTile);
      if (pintor.height > maior) maior = pintor.height;
      pintor.dispose();
    }
    return maior;
  }

  @override
  Widget build(BuildContext context) {
    final alturaRotulo = _alturaRotulo(context);
    return LayoutBuilder(
      builder: (context, restricoes) {
        final livre = restricoes.maxWidth - colunas * K.categoriaTile;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: categorias.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: colunas,
            crossAxisSpacing: livre > 0 ? livre / (colunas - 1) : 0,
            mainAxisSpacing: K.s12 + 2,
            mainAxisExtent:
                K.categoriaTile + K.s4 + K.s4 / 2 + alturaRotulo.ceilToDouble(),
          ),
          itemBuilder: (_, i) {
            final categoria = categorias[i];
            return KCategoryTile(
              icone: KIcons.categoria(categoria.id),
              rotulo: categoria.nome,
              selecionada: categoria.id == selecionada,
              onTap: () => onSelecionar(categoria),
            );
          },
        );
      },
    );
  }
}
