import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kisalu_express/data/repositories/kisalu_repository.dart';
import 'package:kisalu_express/data/repositories/mock_kisalu_repository.dart';
import 'package:kisalu_express/features/mapa/views/mapa_view.dart';
import 'package:kisalu_express/features/mapa/widgets/pin_profissional.dart';
import 'package:kisalu_express/models/pin_mapa.dart';

import '../../../helpers/ecra_apoio.dart';

class _SemRede extends MockKisaluRepository {
  @override
  Future<List<PinMapa>> pinsMapa() => throw const SemRedeException();
}

class _Vazio extends MockKisaluRepository {
  @override
  Future<List<PinMapa>> pinsMapa() async => [];
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> abrir(
    WidgetTester t, {
    double escala = 1,
    KisaluRepository? repo,
  }) => montarEcra(
    t,
    const MapaView(),
    escala: escala,
    repo: repo,
    destinos: ['/inicio', '/profissional/:id'],
    comScaffold: false,
  );

  testWidgets('mostra os textos-chave do Figma', (t) async {
    await abrir(t);
    for (final s in [
      'Perto de si',
      'Lista',
      'Canalizador · 1,2 km',
      'JM',
      'Ver perfil',
      'Está aqui',
      ' · Verificado',
    ]) {
      expect(find.text(s), findsOneWidget, reason: s);
    }
    expect(find.bySemanticsLabel('Centrar no meu local'), findsOneWidget);
    expect(
      find.textContaining('Joaquim Manuel', findRichText: true),
      findsOneWidget,
    );
    expect(find.textContaining('4,8', findRichText: true), findsOneWidget);
    expect(find.textContaining('(126)', findRichText: true), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('há um pin por profissional, todos com alvo de 48 dp', (t) async {
    await abrir(t);
    for (final nome in [
      'Joaquim Manuel',
      'Ana Cardoso',
      'Rui Santos',
      'Paulo Neto',
    ]) {
      final pin = find.bySemanticsLabel('Ver $nome no mapa');
      expect(pin, findsOneWidget, reason: nome);
    }
    expect(find.byType(PinProfissional), findsNWidgets(4));
    for (final caixa
        in t
            .widgetList(find.byType(PinProfissional))
            .map((w) => t.getSize(find.byWidget(w)))) {
      expect(caixa.width, greaterThanOrEqualTo(48));
      expect(caixa.height, greaterThanOrEqualTo(48));
    }
  });

  testWidgets('tocar noutro pin muda o cartão de baixo', (t) async {
    await abrir(t);
    await t.tap(find.bySemanticsLabel('Ver Ana Cardoso no mapa'));
    await t.pumpAndSettle();
    expect(
      find.textContaining('Ana Cardoso', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('Canalizador · 1,2 km'), findsNothing);
    expect(find.text('Cabeleireira · 2,0 km'), findsOneWidget);
  });

  testWidgets('"Ver" abre o perfil do profissional', (t) async {
    await abrir(t);
    await t.tap(find.text('Ver perfil'));
    await t.pumpAndSettle();
    expect(find.text('DESTINO /profissional/p1'), findsOneWidget);
  });

  testWidgets('o cartão do pin escolhido abre o perfil desse profissional', (
    t,
  ) async {
    await abrir(t);
    await t.tap(find.bySemanticsLabel('Ver Paulo Neto no mapa'));
    await t.pumpAndSettle();
    await t.tap(find.text('Ver perfil'));
    await t.pumpAndSettle();
    expect(find.text('DESTINO /profissional/p4'), findsOneWidget);
  });

  testWidgets('"Lista" volta (sem histórico, vai ao Início)', (t) async {
    await abrir(t);
    await t.tap(find.text('Lista'));
    await t.pumpAndSettle();
    expect(find.text('DESTINO /inicio'), findsOneWidget);
  });

  testWidgets('o botão de voltar também funciona', (t) async {
    await abrir(t);
    await t.tap(find.bySemanticsLabel('Voltar'));
    await t.pumpAndSettle();
    expect(find.text('DESTINO /inicio'), findsOneWidget);
  });

  testWidgets('sem profissionais mostra o estado vazio', (t) async {
    await abrir(t, repo: _Vazio());
    expect(find.text('Sem profissionais no mapa'), findsOneWidget);
    expect(find.text('Lista'), findsOneWidget);
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
