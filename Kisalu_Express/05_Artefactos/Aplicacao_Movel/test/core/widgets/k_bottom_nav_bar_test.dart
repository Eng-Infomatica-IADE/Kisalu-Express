import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kisalu_express/core/theme/k_colors.dart';
import 'package:kisalu_express/core/theme/k_theme.dart';
import 'package:kisalu_express/core/widgets/widgets.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Widget montar({
    int indice = 0,
    bool qrDisponivel = true,
    ValueChanged<int>? onSelecionar,
    double escalaTexto = 1,
  }) {
    return MaterialApp(
      theme: KTheme.light(),
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(360, 740),
          textScaler: TextScaler.linear(escalaTexto),
        ),
        child: Scaffold(
          bottomNavigationBar: KBottomNavBar(
            indiceAtual: indice,
            qrDisponivel: qrDisponivel,
            onSelecionar: onSelecionar ?? (_) {},
          ),
        ),
      ),
    );
  }

  Color corDoRotulo(WidgetTester tester, String rotulo) =>
      tester.widget<Text>(find.text(rotulo)).style!.color!;

  testWidgets('mostra os 5 separadores com rótulo', (tester) async {
    await tester.pumpWidget(montar());
    for (final rotulo in ['Início', 'Pedidos', 'QR', 'Conversas', 'Perfil']) {
      expect(find.text(rotulo), findsOneWidget);
    }
  });

  testWidgets('o separador ativo fica laranja', (tester) async {
    await tester.pumpWidget(montar(indice: 1));
    expect(corDoRotulo(tester, 'Pedidos'), KColors.laranja);
    expect(corDoRotulo(tester, 'Início'), KColors.neutro500);
  });

  testWidgets('tocar num separador devolve o índice', (tester) async {
    final tocados = <int>[];
    await tester.pumpWidget(montar(onSelecionar: tocados.add));
    await tester.tap(find.text('Conversas'));
    await tester.tap(find.text('QR'));
    expect(tocados, [3, 2]);
  });

  testWidgets('QR desativado continua tocável e anuncia porquê', (
    tester,
  ) async {
    final tocados = <int>[];
    await tester.pumpWidget(
      montar(qrDisponivel: false, onSelecionar: tocados.add),
    );
    expect(corDoRotulo(tester, 'QR'), KColors.neutro500);
    expect(
      find.bySemanticsLabel('QR, sem serviços para confirmar'),
      findsOneWidget,
    );
    await tester.tap(find.text('QR'));
    expect(tocados, [2]);
  });

  testWidgets('alvos de toque têm pelo menos 48 dp', (tester) async {
    await tester.pumpWidget(montar());
    final barra = tester.getSize(find.byType(KBottomNavBar));
    expect(barra.height, greaterThanOrEqualTo(76));
    expect(barra.width / 5, greaterThanOrEqualTo(48));
  });

  testWidgets('aguenta texto a 200 % sem overflow', (tester) async {
    await tester.pumpWidget(montar(escalaTexto: 2));
    expect(tester.takeException(), isNull);
  });
}
