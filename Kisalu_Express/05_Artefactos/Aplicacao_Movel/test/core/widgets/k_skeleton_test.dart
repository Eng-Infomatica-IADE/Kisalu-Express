import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kisalu_express/core/theme/k_colors.dart';
import 'package:kisalu_express/core/widgets/widgets.dart';

import '../../helpers/montar_widget.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Widget montar(Widget filho, {double escalaTexto = 1}) =>
      montarWidget(filho, escalaTexto: escalaTexto, rolavel: true);

  group('KSkeleton', () {
    testWidgets('bloco usa areia200 e tem as medidas pedidas', (tester) async {
      await tester.pumpWidget(
        montar(
          const Align(
            alignment: Alignment.topLeft,
            child: KSkeleton(largura: 120, altura: 20),
          ),
        ),
      );
      expect(tester.getSize(find.byType(KSkeleton)), const Size(120, 20));
      final caixa = tester.widget<Container>(find.byType(Container).last);
      expect((caixa.decoration! as BoxDecoration).color, KColors.areia200);
    });

    testWidgets('lista tem o número de itens pedido', (tester) async {
      await tester.pumpWidget(montar(const KSkeletonLista(itens: 4)));
      expect(find.byType(KSkeleton), findsNWidgets(4));
    });
  });
}
