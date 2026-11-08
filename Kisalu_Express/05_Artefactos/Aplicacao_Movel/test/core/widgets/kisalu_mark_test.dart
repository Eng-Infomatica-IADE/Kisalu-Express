import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kisalu_express/core/theme/k_colors.dart';
import 'package:kisalu_express/core/theme/k_theme.dart';
import 'package:kisalu_express/core/theme/k_tokens.dart';
import 'package:kisalu_express/core/widgets/widgets.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('renderiza o pin com K e o rótulo acessível', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(theme: KTheme.light(), home: KisaluMark()),
    );

    expect(find.bySemanticsLabel('Kisalu'), findsOneWidget);
    final marca = tester.widget<KisaluMark>(find.byType(KisaluMark));
    expect(marca.largura, 59);
    expect(marca.altura, 85);
    semantics.dispose();
  });

  testWidgets('aceita tamanho e cores para os fundos da marca', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        theme: KTheme.light(),
        home: KisaluMark(
          largura: K.s32,
          altura: K.s32,
          cor: KColors.laranja,
          corLetra: KColors.branco,
          rotulo: 'Marca Kisalu',
        ),
      ),
    );

    expect(find.bySemanticsLabel('Marca Kisalu'), findsOneWidget);
    final marca = tester.widget<KisaluMark>(find.byType(KisaluMark));
    expect(marca.largura, 32);
    expect(marca.altura, 32);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });
}
