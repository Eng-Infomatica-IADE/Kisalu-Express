import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kisalu_express/data/repositories/kisalu_repository.dart';
import 'package:kisalu_express/data/repositories/mock_kisalu_repository.dart';
import 'package:kisalu_express/features/profissional/views/perfil_profissional_view.dart';
import 'package:kisalu_express/models/profissional.dart';

import '../../../helpers/ecra_apoio.dart';

class _SemRede extends MockKisaluRepository {
  @override
  Future<Profissional?> profissional(String id) =>
      throw const SemRedeException();
}

class _PoucosTrabalhos extends MockKisaluRepository {
  @override
  Future<Profissional?> profissional(String id) async {
    final p = (await super.profissional(id))!;
    return Profissional(
      id: p.id,
      nome: p.nome,
      categoria: p.categoria,
      zona: p.zona,
      distanciaKm: p.distanciaKm,
      rating: p.rating,
      numAvaliacoes: p.numAvaliacoes,
      servicosConfirmados: p.servicosConfirmados,
      anosExperiencia: p.anosExperiencia,
      verificado: p.verificado,
      maoDeObraDesde: p.maoDeObraDesde,
      especialidades: p.especialidades,
      trabalhosFeitos: p.trabalhosFeitos,
      totalTrabalhosFeitos: 3,
      avaliacoes: p.avaliacoes,
    );
  }
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> abrir(
    WidgetTester t, {
    String id = 'p1',
    double escala = 1,
    KisaluRepository? repo,
  }) => montarEcra(
    t,
    PerfilProfissionalView(profissionalId: id),
    escala: escala,
    repo: repo,
    comScaffold: false,
    destinos: ['/novo-pedido', '/inicio'],
  );

  testWidgets('mostra os textos-chave do Figma', (t) async {
    await abrir(t);
    for (final s in [
      'VERIFICADO',
      'Joaquim Manuel',
      'Canalizador · Talatona, Luanda',
      '4,8',
      'Avaliação',
      '126',
      'Serviços',
      '6 anos',
      'Experiência',
      'Especialidades',
      'Fugas de água',
      'Esquentadores',
      'Desentupimentos',
      'Loiças sanitárias',
      'Trabalhos feitos',
      'Ver todos (41)',
      'Antes/depois',
      'Esquentador',
      'Loiça sanitária',
      'Fotos de serviços confirmados por QR na Kisalu',
      'mão de obra desde',
      '8.000 Kz',
      'Pedir serviço',
    ]) {
      expect(find.text(s), findsOneWidget, reason: s);
    }
    expect(find.bySemanticsLabel('Voltar'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('mostra as avaliações recentes ao descer', (t) async {
    await abrir(t);
    await t.scrollUntilVisible(find.text('Pedro K.'), 200);
    expect(find.text('Avaliações recentes'), findsOneWidget);
    expect(
      find.text('Chegou a horas e resolveu a fuga em 40 min. Recomendo!'),
      findsOneWidget,
    );
    expect(find.text('Maria S.'), findsOneWidget);
  });

  testWidgets('não mostra contacto nem morada (RNF10)', (t) async {
    await abrir(t);
    expect(find.textContaining('+244'), findsNothing);
    expect(find.textContaining('Morada'), findsNothing);
  });

  testWidgets('"Pedir serviço" abre o novo pedido', (t) async {
    await abrir(t);
    await t.tap(find.text('Pedir serviço'));
    await t.pumpAndSettle();
    expect(find.text('DESTINO /novo-pedido'), findsOneWidget);
  });

  testWidgets('"Ver todos" mostra "Em breve"', (t) async {
    await abrir(t);
    await t.tap(find.text('Ver todos (41)'));
    await t.pump();
    expect(find.text('Em breve'), findsOneWidget);
  });

  testWidgets('profissional inexistente mostra "não encontrado"', (t) async {
    await abrir(t, id: 'zzz');
    expect(find.text('Não encontrado'), findsOneWidget);
    expect(find.text('Voltar ao Início'), findsOneWidget);
    await t.tap(find.text('Voltar ao Início'));
    await t.pumpAndSettle();
    expect(find.text('DESTINO /inicio'), findsOneWidget);
  });

  testWidgets('estado de erro de rede', (t) async {
    await abrir(t, repo: _SemRede());
    expect(find.text('Não foi possível carregar'), findsOneWidget);
    expect(find.text('Tentar outra vez'), findsOneWidget);
  });

  testWidgets('sem overflow com texto a 200 %', (t) async {
    // Total de 1 dígito: com a fonte de teste (Ahem, muito larga) o "Ver todos
    // (41)" não cabe ao lado do título a 200 %, ao contrário da fonte real.
    await abrir(t, escala: 2, repo: _PoucosTrabalhos());
    expect(t.takeException(), isNull);
  });

  testWidgets('mostra o bloco "Avaliações em números" do Joaquim', (t) async {
    await abrir(t);
    await t.scrollUntilVisible(find.text('n = 126 avaliações'), 200);
    expect(find.text('Avaliações em números'), findsOneWidget);
    expect(find.text('Entre 4,7 e 4,9 com 95% de confiança'), findsOneWidget);
  });
}
