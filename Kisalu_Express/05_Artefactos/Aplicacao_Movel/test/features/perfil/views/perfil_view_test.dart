import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kisalu_express/data/repositories/kisalu_repository.dart';
import 'package:kisalu_express/data/repositories/mock_kisalu_repository.dart';
import 'package:kisalu_express/features/perfil/views/perfil_view.dart';
import 'package:kisalu_express/models/utilizador.dart';

import '../../../helpers/ecra_apoio.dart';

class _SemRede extends MockKisaluRepository {
  @override
  Future<void> terminarSessao() => throw const SemRedeException();
}

class _CarregarFalha extends MockKisaluRepository {
  @override
  Future<Utilizador> utilizador() => throw const SemRedeException();
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> abrir(
    WidgetTester t, {
    double escala = 1,
    KisaluRepository? repo,
  }) => montarEcra(
    t,
    const PerfilView(),
    escala: escala,
    repo: repo,
    destinos: [
      '/login',
      '/inicio',
      '/ajuda',
      '/notificacoes',
      '/registo-profissional',
    ],
  );

  testWidgets('mostra os textos-chave do Figma', (t) async {
    await abrir(t);
    for (final s in [
      'Perfil',
      'MK',
      'Maria Kiala',
      '+244 923 *** 000',
      'Talatona, Luanda',
      'Os meus dados',
      'Moradas guardadas',
      '2 moradas',
      'Profissionais favoritos',
      '3 guardados',
      'Notificações',
      'Ajuda e apoio',
      'Privacidade e dados',
      'Mudar para profissional',
      'Terminar sessão',
    ]) {
      expect(find.text(s), findsOneWidget, reason: s);
    }
    expect(t.takeException(), isNull);
  });

  testWidgets('o telemóvel aparece sempre mascarado', (t) async {
    await abrir(t);
    expect(find.text('+244 923 000 000'), findsNothing);
    expect(find.textContaining('923000000'), findsNothing);
  });

  testWidgets('as linhas do menu sem ecrã mostram "Em breve"', (t) async {
    await abrir(t);
    await t.tap(find.text('Os meus dados'));
    await t.pump();
    expect(find.text('Em breve'), findsOneWidget);
  });

  testWidgets('"Ajuda e apoio" e "Notificações" abrem os seus ecrãs', (
    t,
  ) async {
    await abrir(t);
    await t.tap(find.text('Ajuda e apoio'));
    await t.pumpAndSettle();
    expect(find.text('DESTINO /ajuda'), findsOneWidget);
    await abrir(t);
    await t.ensureVisible(find.text('Notificações'));
    await t.tap(find.text('Notificações'));
    await t.pumpAndSettle();
    expect(find.text('DESTINO /notificacoes'), findsOneWidget);
  });

  testWidgets('sem registo de profissional, "Mudar" abre o registo (12)', (
    t,
  ) async {
    final repo = MockKisaluRepository(registoProfissionalCompleto: false);
    await abrir(t, repo: repo);
    await t.ensureVisible(find.text('Mudar para profissional'));
    await t.tap(find.text('Mudar para profissional'));
    await t.pumpAndSettle();
    expect(find.text('DESTINO /registo-profissional'), findsOneWidget);
    expect(repo.perfilAtivo, PerfilUtilizador.cliente);
  });

  testWidgets('"Mudar para profissional" muda a sessão e vai ao Início', (
    t,
  ) async {
    final repo = MockKisaluRepository();
    await abrir(t, repo: repo);
    await t.tap(find.text('Mudar para profissional'));
    await t.pumpAndSettle();
    expect(repo.perfilAtivo, PerfilUtilizador.profissional);
    expect(find.text('DESTINO /inicio'), findsOneWidget);
  });

  testWidgets('em modo profissional oferece "Mudar para cliente"', (t) async {
    final repo = MockKisaluRepository();
    await repo.mudarPerfil(PerfilUtilizador.profissional);
    await abrir(t, repo: repo);
    expect(find.text('Joaquim Manuel'), findsOneWidget);
    expect(find.text('Mudar para cliente'), findsOneWidget);
    await t.tap(find.text('Mudar para cliente'));
    await t.pumpAndSettle();
    expect(repo.perfilAtivo, PerfilUtilizador.cliente);
    expect(find.text('DESTINO /inicio'), findsOneWidget);
  });

  testWidgets('"Terminar sessão" vai para o Login', (t) async {
    await abrir(t);
    await t.tap(find.text('Terminar sessão'));
    await t.pumpAndSettle();
    expect(find.text('Terminar sessão?'), findsOneWidget);
    await t.tap(find.text('Terminar sessão').last);
    await t.pumpAndSettle();
    expect(find.text('DESTINO /login'), findsOneWidget);
  });

  testWidgets('falha ao terminar sessão mostra erro e fica', (t) async {
    await abrir(t, repo: _SemRede());
    await t.tap(find.text('Terminar sessão'));
    await t.pumpAndSettle();
    expect(find.text('Terminar sessão?'), findsOneWidget);
    await t.tap(find.text('Terminar sessão').last);
    await t.pumpAndSettle();
    expect(
      find.textContaining(
        'Sem ligação. Confirme a sua rede e tente outra vez.',
        findRichText: true,
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining('Não foi possível concluir.', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('Maria Kiala'), findsOneWidget);
  });

  testWidgets('falha ao carregar mostra o estado de erro', (t) async {
    await abrir(t, repo: _CarregarFalha());
    expect(find.text('Não foi possível carregar'), findsOneWidget);
    expect(find.text('Tentar outra vez'), findsOneWidget);
  });

  testWidgets('sem overflow com texto a 200 %', (t) async {
    await abrir(t, escala: 2);
    expect(t.takeException(), isNull);
  });
}
