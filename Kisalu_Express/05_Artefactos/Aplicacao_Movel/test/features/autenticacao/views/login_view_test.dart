import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kisalu_express/features/autenticacao/views/login_view.dart';

import '../../../helpers/ecra_apoio.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> abrir(WidgetTester t, {double escala = 1}) => montarEcra(
    t,
    const LoginView(),
    escala: escala,
    destinos: ['/codigo-sms', '/ajuda'],
    comScaffold: false,
  );

  testWidgets('mostra os textos-chave do Figma', (t) async {
    await abrir(t);
    for (final s in [
      'Kisalu Express',
      'Quem sabe, resolve.',
      'Entrar ou criar conta',
      'Sou cliente',
      'Sou profissional',
      'Telemóvel',
      '+244 923 000 000',
      'Enviamos um código por SMS: sem palavra-passe.',
      'Receber código SMS',
      'Criar conta',
      'Ao continuar aceita os Termos e a Política de Privacidade (RGPD).',
      'Precisa de ajuda? Fale connosco',
    ]) {
      expect(find.text(s), findsOneWidget, reason: s);
    }
    expect(t.takeException(), isNull);
  });

  testWidgets('número válido avança para o código SMS', (t) async {
    await abrir(t);
    await t.tap(find.text('Receber código SMS'));
    await t.pumpAndSettle();
    expect(find.text('DESTINO /codigo-sms'), findsOneWidget);
  });

  testWidgets('"Criar conta" segue o mesmo fluxo', (t) async {
    await abrir(t);
    await t.tap(find.text('Criar conta'));
    await t.pumpAndSettle();
    expect(find.text('DESTINO /codigo-sms'), findsOneWidget);
  });

  testWidgets('número incompleto mostra erro e não avança', (t) async {
    await abrir(t);
    await t.enterText(find.byType(TextField), '+244 923 45');
    await t.tap(find.text('Receber código SMS'));
    await t.pumpAndSettle();
    expect(
      find.text('Faltam 4 números. Um número angolano tem 9 dígitos.'),
      findsOneWidget,
    );
    expect(find.text('DESTINO /codigo-sms'), findsNothing);
  });

  testWidgets('o controlo segmentado alterna o perfil', (t) async {
    await abrir(t);
    await t.tap(find.text('Sou profissional'));
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
    expect(find.text('Sou profissional'), findsOneWidget);
  });

  testWidgets('a ajuda abre as perguntas frequentes', (t) async {
    await abrir(t);
    // Com a fonte de teste (Ahem, muito larga) o conteúdo passa os 844 dp.
    await t.dragUntilVisible(
      find.text('Precisa de ajuda? Fale connosco'),
      find.byType(CustomScrollView),
      const Offset(0, -100),
    );
    await t.pumpAndSettle();
    await t.tap(find.text('Precisa de ajuda? Fale connosco'));
    await t.pumpAndSettle();
    expect(find.text('DESTINO /ajuda'), findsOneWidget);
  });

  testWidgets('sem overflow com texto a 200 %', (t) async {
    await abrir(t, escala: 2);
    expect(t.takeException(), isNull);
  });
}
