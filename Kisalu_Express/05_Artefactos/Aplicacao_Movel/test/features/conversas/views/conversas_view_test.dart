import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kisalu_express/data/repositories/kisalu_repository.dart';
import 'package:kisalu_express/data/repositories/mock_kisalu_repository.dart';
import 'package:kisalu_express/features/conversas/views/conversas_view.dart';
import 'package:kisalu_express/models/conversa.dart';

import '../../../helpers/ecra_apoio.dart';

class _SemConversas extends MockKisaluRepository {
  @override
  Future<List<Conversa>> conversas() async => [];
}

class _SemRede extends MockKisaluRepository {
  @override
  Future<List<Conversa>> conversas() => throw const SemRedeException();
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> abrir(
    WidgetTester t, {
    double escala = 1,
    KisaluRepository? repo,
  }) => montarEcra(
    t,
    const ConversasView(),
    escala: escala,
    repo: repo,
    destinos: ['/pedidos', '/conversas/:id'],
  );

  testWidgets('mostra as 3 conversas do Figma', (t) async {
    await abrir(t);
    for (final s in [
      'Conversas',
      'Joaquim Manuel',
      'Chego às 15h40, como combinado.',
      '15:02',
      '2',
      'Carlos Dias',
      'Obrigado pela preferência!',
      '24 set',
      'Nuno Ferreira',
      'O filtro já está limpo.',
      '12 set',
      'JM',
      'CD',
      'NF',
    ]) {
      expect(find.text(s), findsOneWidget, reason: s);
    }
    expect(t.takeException(), isNull);
  });

  testWidgets('tocar numa conversa abre o ecrã 19 com o seu id', (t) async {
    await abrir(t);
    await t.tap(find.text('Carlos Dias'));
    await t.pumpAndSettle();
    expect(find.text('DESTINO /conversas/c2'), findsOneWidget);
  });

  testWidgets('a primeira conversa leva a c1', (t) async {
    await abrir(t);
    await t.tap(find.text('Joaquim Manuel'));
    await t.pumpAndSettle();
    expect(find.text('DESTINO /conversas/c1'), findsOneWidget);
  });

  testWidgets('sem conversas mantém o estado vazio e vai para os pedidos', (
    t,
  ) async {
    await abrir(t, repo: _SemConversas());
    expect(find.text('Ainda não tem conversas'), findsOneWidget);
    expect(find.text('Ver os meus pedidos'), findsOneWidget);
    await t.tap(find.text('Ver os meus pedidos'));
    await t.pumpAndSettle();
    expect(find.text('DESTINO /pedidos'), findsOneWidget);
  });

  testWidgets('falha de rede mostra o estado de erro', (t) async {
    await abrir(t, repo: _SemRede());
    expect(find.text('Não foi possível carregar'), findsOneWidget);
    expect(find.text('Tentar outra vez'), findsOneWidget);
  });

  testWidgets('sem overflow com texto a 200 %', (t) async {
    await abrir(t, escala: 2);
    expect(t.takeException(), isNull);
  });
}
