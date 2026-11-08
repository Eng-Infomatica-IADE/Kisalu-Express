import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kisalu_express/data/repositories/kisalu_repository.dart';
import 'package:kisalu_express/data/repositories/mock_kisalu_repository.dart';
import 'package:kisalu_express/features/registo_profissional/views/verificar_identidade_view.dart';
import 'package:kisalu_express/models/verificacao_identidade.dart';

import '../../../helpers/ecra_apoio.dart';

class _SemRede extends MockKisaluRepository {
  @override
  Future<VerificacaoIdentidade> verificacaoIdentidade() =>
      throw const SemRedeException();
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> abrir(
    WidgetTester t, {
    double escala = 1,
    KisaluRepository? repo,
  }) => montarEcra(
    t,
    const VerificarIdentidadeView(),
    escala: escala,
    repo: repo,
    destinos: ['/inicio'],
    comScaffold: false,
  );

  testWidgets('mostra os textos-chave do Figma', (t) async {
    await abrir(t);
    for (final s in [
      'Verificar identidade',
      'Com o selo Verificado, os clientes sabem quem entra em casa deles.',
      'Documento de identidade',
      'Frente e verso · Alterar',
      'ENVIADO',
      'Fotografia do rosto',
      'Toque para tirar a fotografia',
      'Depois de enviar, avisamos por SMS com o resultado.',
      'Falta a fotografia do rosto para poder enviar.',
      'FALTA',
      'Usamos estes dados só para verificar a identidade. O documento não é '
          'mostrado a clientes.',
      'Enviar para verificação',
      'Fazer mais tarde',
    ]) {
      expect(find.text(s, findRichText: true), findsOneWidget, reason: s);
    }
    expect(
      find.bySemanticsLabel('Passo 2 de 2 · Selo Verificado'),
      findsOneWidget,
    );
    expect(t.takeException(), isNull);
  });

  testWidgets('sem a fotografia do rosto o envio fica desativado', (t) async {
    await abrir(t);
    expect(
      find.text('Falta a fotografia do rosto para poder enviar.'),
      findsOneWidget,
    );
    await t.ensureVisible(find.text('Enviar para verificação'));
    await t.pump();
    await t.tap(find.text('Enviar para verificação'), warnIfMissed: false);
    await t.pumpAndSettle();
    expect(find.text('DESTINO /inicio'), findsNothing);
  });

  testWidgets('com a fotografia o aviso do que falta desaparece', (t) async {
    await abrir(t);
    await t.tap(find.text('Fotografia do rosto'));
    await t.pumpAndSettle();
    expect(
      find.text('Falta a fotografia do rosto para poder enviar.'),
      findsNothing,
    );
  });

  testWidgets('tocar na linha do rosto simula a fotografia', (t) async {
    await abrir(t);
    await t.tap(find.text('Fotografia do rosto'));
    await t.pumpAndSettle();
    expect(find.text('ENVIADO'), findsNWidgets(2));
    expect(find.text('FALTA'), findsNothing);
  });

  testWidgets('com os dois documentos, enviar vai para o Início', (t) async {
    await abrir(t);
    await t.tap(find.text('Fotografia do rosto'));
    await t.pumpAndSettle();
    await t.ensureVisible(find.text('Enviar para verificação'));
    await t.pump();
    await t.tap(find.text('Enviar para verificação'));
    await t.pumpAndSettle();
    expect(find.text('DESTINO /inicio'), findsOneWidget);
  });

  testWidgets('"Fazer mais tarde" segue para o Início', (t) async {
    await abrir(t);
    await t.ensureVisible(find.text('Fazer mais tarde'));
    await t.pump();
    await t.tap(find.text('Fazer mais tarde'));
    await t.pumpAndSettle();
    expect(find.text('DESTINO /inicio'), findsOneWidget);
  });

  testWidgets('falha ao carregar mostra o estado de erro', (t) async {
    await abrir(t, repo: _SemRede());
    expect(find.text('Não foi possível carregar'), findsOneWidget);
  });

  testWidgets('sem overflow com texto a 200 %', (t) async {
    await abrir(t, escala: 2);
    expect(t.takeException(), isNull);
  });
}
