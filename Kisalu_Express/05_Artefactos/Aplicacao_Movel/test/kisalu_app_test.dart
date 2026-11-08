import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kisalu_express/kisalu_app.dart';

void main() {
  // Nos testes não há rede: as fontes caem no fallback do sistema.
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('a app arranca no Login', (tester) async {
    await tester.pumpWidget(const KisaluApp());
    await tester.pumpAndSettle();
    expect(find.text('Entrar ou criar conta'), findsOneWidget);
    expect(find.text('Kisalu · ecrãs (dev)'), findsNothing);
  });
}
