import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kisalu_express/data/repositories/kisalu_repository.dart';
import 'package:kisalu_express/data/repositories/mock_kisalu_repository.dart';
import 'package:kisalu_express/features/autenticacao/views/codigo_sms_view.dart';
import 'package:kisalu_express/models/pedido_codigo_sms.dart';
import 'package:kisalu_express/models/utilizador.dart';

import '../../../helpers/ecra_apoio.dart';

class _SemRede extends MockKisaluRepository {
  @override
  Future<PedidoCodigoSms> codigoSmsPendente() => throw const SemRedeException();
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> abrir(
    WidgetTester t, {
    double escala = 1,
    KisaluRepository? repo,
  }) => montarEcra(
    t,
    const CodigoSmsView(),
    escala: escala,
    repo: repo,
    destinos: ['/inicio', '/registo-profissional', '/login'],
    comScaffold: false,
  );

  testWidgets('mostra os textos-chave do Figma', (t) async {
    await abrir(t);
    for (final s in [
      'Confirmar número',
      'Introduza o código',
      'Enviámos um código de 6 dígitos para\n+244 923 000 000.',
      'Reenviar código em 0:42',
      'Confirmar',
      'Alterar número',
      '4',
      '8',
      '2',
      '1',
      '7',
    ]) {
      expect(find.text(s), findsOneWidget, reason: s);
    }
    expect(t.takeException(), isNull);
  });

  testWidgets('a contagem do reenvio desce de segundo a segundo', (t) async {
    await abrir(t);
    await t.pump(const Duration(seconds: 1));
    expect(find.text('Reenviar código em 0:41'), findsOneWidget);
    await t.pump(const Duration(seconds: 41));
    expect(find.text('Reenviar código'), findsOneWidget);
    expect(find.textContaining('Reenviar código em'), findsNothing);
  });

  testWidgets('"Reenviar código" recomeça a contagem', (t) async {
    await abrir(t);
    await t.pump(const Duration(seconds: 42));
    await t.tap(find.text('Reenviar código'));
    await t.pump();
    await t.pump();
    expect(find.text('Reenviar código em 0:42'), findsOneWidget);
  });

  testWidgets('com menos de 6 dígitos o Confirmar fica desativado', (t) async {
    await abrir(t);
    await t.enterText(find.byType(TextField), '48217');
    await t.pump();
    await t.tap(find.text('Confirmar'), warnIfMissed: false);
    await t.pumpAndSettle();
    expect(find.text('DESTINO /inicio'), findsNothing);
    await t.enterText(find.byType(TextField), '482173');
    await t.pump();
    await t.tap(find.text('Confirmar'));
    await t.pumpAndSettle();
    expect(find.text('DESTINO /inicio'), findsOneWidget);
  });

  testWidgets('diz que o código se preenche sozinho', (t) async {
    await abrir(t);
    expect(
      find.text('O código preenche-se sozinho quando o SMS chegar.'),
      findsOneWidget,
    );
  });

  testWidgets('escrever apaga o erro', (t) async {
    await abrir(t);
    await t.enterText(find.byType(TextField), '000000');
    await t.pump();
    await t.tap(find.text('Confirmar'));
    await t.pumpAndSettle();
    expect(find.textContaining('não está certo'), findsOneWidget);
    await t.enterText(find.byType(TextField), '4821');
    await t.pump();
    expect(find.textContaining('não está certo'), findsNothing);
  });

  testWidgets('o campo só aceita dígitos e no máximo 6', (t) async {
    await abrir(t);
    await t.enterText(find.byType(TextField), '12ab34cd567890');
    await t.pump();
    final campo = t.widget<TextField>(find.byType(TextField));
    expect(campo.controller!.text, '123456');
  });

  testWidgets('código errado (000000) fica no ecrã com a mensagem', (t) async {
    await abrir(t);
    await t.enterText(find.byType(TextField), '000000');
    await t.pump();
    await t.tap(find.text('Confirmar'));
    await t.pumpAndSettle();
    expect(
      find.text('O código não está certo. Confirme o SMS e tente outra vez.'),
      findsOneWidget,
    );
    expect(find.text('DESTINO /inicio'), findsNothing);
  });

  testWidgets('cliente confirma e vai para o Início', (t) async {
    await abrir(t);
    await t.enterText(find.byType(TextField), '482173');
    await t.pump();
    await t.tap(find.text('Confirmar'));
    await t.pumpAndSettle();
    expect(find.text('DESTINO /inicio'), findsOneWidget);
  });

  testWidgets('profissional que cria conta vai para o registo', (t) async {
    final repo = MockKisaluRepository();
    await repo.pedirCodigoSms(
      '+244923000000',
      PerfilUtilizador.profissional,
      criarConta: true,
    );
    await abrir(t, repo: repo);
    await t.enterText(find.byType(TextField), '482173');
    await t.pump();
    await t.tap(find.text('Confirmar'));
    await t.pumpAndSettle();
    expect(find.text('DESTINO /registo-profissional'), findsOneWidget);
    expect(repo.perfilAtivo, PerfilUtilizador.profissional);
  });

  testWidgets('"Alterar número" volta ao Login', (t) async {
    await abrir(t);
    await t.tap(find.text('Alterar número'));
    await t.pumpAndSettle();
    expect(find.text('DESTINO /login'), findsOneWidget);
  });

  testWidgets('falha ao carregar mostra o estado de erro', (t) async {
    await abrir(t, repo: _SemRede());
    expect(find.text('Não foi possível carregar'), findsOneWidget);
    expect(find.text('Tentar outra vez'), findsOneWidget);
  });

  testWidgets('sem overflow com texto a 200 %', (t) async {
    await abrir(t, escala: 2);
    expect(t.takeException(), isNull);
  });
}
