import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kisalu_express/data/repositories/kisalu_repository.dart';
import 'package:kisalu_express/data/repositories/mock_kisalu_repository.dart';
import 'package:kisalu_express/features/confirmacao_profissional/views/servico_confirmado_view.dart';
import 'package:kisalu_express/models/servico_confirmado.dart';

import '../../../helpers/ecra_apoio.dart';

class _SemRede extends MockKisaluRepository {
  @override
  Future<ServicoConfirmado?> servicoConfirmado(String pedidoId) =>
      throw const SemRedeException();
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> abrir(
    WidgetTester t, {
    double escala = 1,
    KisaluRepository? repo,
    String id = 'tp1',
  }) => montarEcra(
    t,
    ServicoConfirmadoView(pedidoId: id),
    escala: escala,
    repo: repo,
    destinos: ['/inicio'],
    comScaffold: false,
  );

  testWidgets('mostra os textos-chave do Figma', (t) async {
    await abrir(t);
    for (final s in [
      'Serviço confirmado',
      'Trabalho concluído',
      'Maria K. confirmou o valor combinado.',
      'Serviço',
      'Fuga de água na cozinha',
      'Valor combinado',
      '12.500 Kz',
      'Data',
      'Hoje, 15:52',
      'Mostre este trabalho no seu perfil',
      'Os clientes escolhem primeiro quem mostra fotos de trabalhos feitos.',
      'Adicionar fotos',
      'Voltar ao Início',
    ]) {
      expect(find.text(s), findsOneWidget, reason: s);
    }
    expect(t.takeException(), isNull);
  });

  testWidgets('"Adicionar fotos" simula e avisa', (t) async {
    await abrir(t);
    await t.tap(find.text('Adicionar fotos'));
    await t.pump();
    expect(find.text('Fotos adicionadas ao seu perfil.'), findsOneWidget);
  });

  testWidgets('"Voltar ao Início" vai para o Início', (t) async {
    await abrir(t);
    await t.tap(find.text('Voltar ao Início'));
    await t.pumpAndSettle();
    expect(find.text('DESTINO /inicio'), findsOneWidget);
  });

  testWidgets('não tem seta de voltar: o serviço está concluído', (t) async {
    await abrir(t);
    expect(find.bySemanticsLabel('Voltar'), findsNothing);
  });

  testWidgets('serviço desconhecido mostra "Não encontrado"', (t) async {
    await abrir(t, id: 'zzz');
    expect(find.text('Não encontrado'), findsOneWidget);
    expect(find.text('Voltar ao Início'), findsOneWidget);
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
