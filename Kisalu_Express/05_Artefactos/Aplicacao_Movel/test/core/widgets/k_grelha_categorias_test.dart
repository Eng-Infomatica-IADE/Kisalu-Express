import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kisalu_express/core/widgets/widgets.dart';
import 'package:kisalu_express/data/mock/mock_categorias.dart';

import '../../helpers/montar_widget.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('KGrelhaCategorias', () {
    testWidgets('mostra todas as categorias numa grelha de 4 colunas', (
      tester,
    ) async {
      await tester.pumpWidget(
        montarWidget(
          KGrelhaCategorias(
            categorias: MockCategorias.todas,
            onSelecionar: (_) {},
          ),
          rolavel: true,
        ),
      );
      expect(find.byType(KCategoryTile), findsNWidgets(13));
      final grelha = tester.widget<GridView>(find.byType(GridView));
      final delegate =
          grelha.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 4);
    });

    testWidgets('é construída a pedido (GridView.builder)', (tester) async {
      await tester.pumpWidget(
        montarWidget(
          KGrelhaCategorias(
            categorias: MockCategorias.todas,
            onSelecionar: (_) {},
          ),
          rolavel: true,
        ),
      );
      expect(
        tester.widget<GridView>(find.byType(GridView)).childrenDelegate,
        isA<SliverChildBuilderDelegate>(),
      );
    });

    testWidgets('devolve a categoria tocada', (tester) async {
      String? tocada;
      await tester.pumpWidget(
        montarWidget(
          KGrelhaCategorias(
            categorias: MockCategorias.todas,
            onSelecionar: (c) => tocada = c.id,
          ),
          rolavel: true,
        ),
      );
      await tester.tap(find.text('Pintor'));
      expect(tocada, 'pintor');
    });

    testWidgets('só destaca a categoria selecionada (se houver)', (
      tester,
    ) async {
      await tester.pumpWidget(
        montarWidget(
          KGrelhaCategorias(
            categorias: MockCategorias.todas,
            selecionada: 'canalizador',
            onSelecionar: (_) {},
          ),
          rolavel: true,
        ),
      );
      final destacadas = tester
          .widgetList<KCategoryTile>(find.byType(KCategoryTile))
          .where((t) => t.selecionada);
      expect(destacadas, hasLength(1));
      expect(destacadas.single.rotulo, 'Canalizador');
    });

    testWidgets('sem selecionada nenhuma fica destacada', (tester) async {
      await tester.pumpWidget(
        montarWidget(
          KGrelhaCategorias(
            categorias: MockCategorias.todas,
            onSelecionar: (_) {},
          ),
          rolavel: true,
        ),
      );
      expect(
        tester
            .widgetList<KCategoryTile>(find.byType(KCategoryTile))
            .any((t) => t.selecionada),
        isFalse,
      );
    });

    testWidgets('sem overflow com texto a 200 %', (tester) async {
      await tester.pumpWidget(
        montarWidget(
          KGrelhaCategorias(
            categorias: MockCategorias.todas,
            onSelecionar: (_) {},
          ),
          rolavel: true,
          escalaTexto: 2,
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
