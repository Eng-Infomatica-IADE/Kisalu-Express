import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kisalu_express/core/widgets/widgets.dart';

import '../../helpers/montar_widget.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('KFolha', () {
    Widget app(Widget Function(BuildContext) abrir) =>
        montarWidget(Builder(builder: abrir), comMargem: false);

    testWidgets('abre, mostra o conteúdo e fecha', (tester) async {
      await tester.pumpWidget(
        app(
          (context) => TextButton(
            onPressed: () => mostrarKFolha<void>(
              context,
              builder: (ctx) => Column(
                children: [
                  const Text('Confirmar a proposta?'),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Voltar às propostas'),
                  ),
                ],
              ),
            ),
            child: const Text('abrir'),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      expect(find.byType(KFolha), findsOneWidget);
      expect(find.text('Confirmar a proposta?'), findsOneWidget);
      await tester.tap(find.text('Voltar às propostas'));
      await tester.pumpAndSettle();
      expect(find.byType(KFolha), findsNothing);
    });

    testWidgets('texto a 200 % não dá overflow', (tester) async {
      await tester.pumpWidget(
        montarWidget(
          const KFolha(child: Text('Conte-nos o que aconteceu. Tem 7 dias.')),
          escalaTexto: 2,
          comMargem: false,
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
