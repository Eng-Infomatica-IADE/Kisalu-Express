import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kisalu_express/data/repositories/kisalu_repository.dart';
import 'package:kisalu_express/data/repositories/mock_kisalu_repository.dart';
import 'package:kisalu_express/features/conversas/views/conversa_view.dart';
import 'package:kisalu_express/models/conversa.dart';
import 'package:kisalu_express/models/mensagem.dart';

import '../../../helpers/ecra_apoio.dart';

class _SemRede extends MockKisaluRepository {
  @override
  Future<Conversa?> conversa(String id) => throw const SemRedeException();
}

class _EnvioFalha extends MockKisaluRepository {
  @override
  Future<Mensagem> enviarMensagem(String conversaId, String texto) =>
      throw const SemRedeException();
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> abrir(
    WidgetTester t, {
    double escala = 1,
    KisaluRepository? repo,
    String id = 'c1',
  }) => montarEcra(
    t,
    ConversaView(conversaId: id),
    escala: escala,
    repo: repo,
    destinos: ['/conversas'],
    comScaffold: false,
  );

  Finder enviar() => find.bySemanticsLabel('Enviar mensagem');

  testWidgets('mostra os textos-chave do Figma', (t) async {
    await abrir(t);
    for (final s in [
      'Joaquim Manuel',
      'Fuga de água na cozinha · 12.500 Kz',
      'Boa tarde. Já tem o sifão para a reparação?',
      '14:51 · Lida',
      'Boa tarde, Maria. Sim, levo o sifão e o vedante.',
      '14:53',
      'Chego às 15h40, como combinado.',
      '15:02',
      'Escreva uma mensagem',
    ]) {
      expect(find.text(s), findsOneWidget, reason: s);
    }
    expect(t.takeException(), isNull);
  });

  testWidgets('enviar acrescenta a mensagem e limpa o campo', (t) async {
    await abrir(t);
    await t.enterText(find.byType(TextField), 'Perfeito, obrigada!');
    await t.pump();
    await t.tap(enviar());
    await t.pumpAndSettle();
    expect(find.text('Perfeito, obrigada!'), findsOneWidget);
    expect(
      t.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
    expect(find.text('15:00'), findsOneWidget);
  });

  testWidgets('o botão do teclado também envia', (t) async {
    await abrir(t);
    await t.enterText(find.byType(TextField), 'Até já');
    await t.pump();
    await t.testTextInput.receiveAction(TextInputAction.send);
    await t.pumpAndSettle();
    expect(find.text('Até já'), findsOneWidget);
  });

  testWidgets('campo vazio não envia', (t) async {
    await abrir(t);
    await t.tap(enviar());
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextField), '   ');
    await t.pump();
    await t.tap(enviar());
    await t.pumpAndSettle();
    expect(find.text('15:00'), findsNothing);
    expect(find.textContaining('Não enviámos'), findsNothing);
  });

  testWidgets('o campo limita a 1.000 caracteres', (t) async {
    await abrir(t);
    await t.enterText(find.byType(TextField), 'a' * 1200);
    await t.pump();
    expect(
      t.widget<TextField>(find.byType(TextField)).controller!.text.length,
      1000,
    );
  });

  testWidgets('o botão da foto mostra "Em breve"', (t) async {
    await abrir(t);
    await t.tap(find.bySemanticsLabel('Enviar fotografia'));
    await t.pump();
    expect(find.text('Em breve'), findsOneWidget);
  });

  testWidgets('falha ao enviar mostra o aviso e não acrescenta', (t) async {
    await abrir(t, repo: _EnvioFalha());
    await t.enterText(find.byType(TextField), 'Olá');
    await t.pump();
    await t.tap(enviar());
    await t.pumpAndSettle();
    expect(find.textContaining('Não enviámos a mensagem.'), findsOneWidget);
    expect(find.text('Olá'), findsOneWidget); // fica no campo
  });

  testWidgets('conversa desconhecida mostra "Não encontrado"', (t) async {
    await abrir(t, id: 'zzz');
    expect(find.text('Não encontrado'), findsOneWidget);
    expect(find.text('Ver as conversas'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('falha ao carregar mostra o estado de erro', (t) async {
    await abrir(t, repo: _SemRede());
    expect(find.text('Não foi possível carregar'), findsOneWidget);
  });

  testWidgets('sem overflow com texto a 200 %', (t) async {
    await abrir(t, escala: 2);
    expect(t.takeException(), isNull);
  });

  testWidgets('v3.1: botão de ligar e enviar desativado sem texto', (t) async {
    await abrir(t);
    expect(find.bySemanticsLabel(RegExp('^Ligar a ')), findsOneWidget);
    await t.tap(enviar(), warnIfMissed: false);
    await t.pumpAndSettle();
    expect(find.textContaining('Não enviámos'), findsNothing);
    expect(t.getSemantics(enviar()).flagsCollection.isEnabled, isNot(true));
  });
}
