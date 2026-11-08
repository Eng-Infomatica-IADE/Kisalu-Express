import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kisalu_express/core/widgets/widgets.dart';

import '../../helpers/montar_widget.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('mostrarKSnack', () {
    testWidgets('mostra a mensagem e a ação', (tester) async {
      var desfeito = false;
      await tester.pumpWidget(
        montarWidget(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => mostrarKSnack(
                context,
                'Proposta aceite. O Joaquim já foi avisado.',
                rotuloAcao: 'Desfazer',
                onAcao: () => desfeito = true,
              ),
              child: const Text('aceitar'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('aceitar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 750));
      expect(
        find.text('Proposta aceite. O Joaquim já foi avisado.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Desfazer'));
      expect(desfeito, isTrue);
    });
  });
}
