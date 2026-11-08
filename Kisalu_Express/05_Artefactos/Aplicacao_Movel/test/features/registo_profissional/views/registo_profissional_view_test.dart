import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kisalu_express/data/repositories/kisalu_repository.dart';
import 'package:kisalu_express/data/repositories/mock_kisalu_repository.dart';
import 'package:kisalu_express/features/registo_profissional/views/registo_profissional_view.dart';
import 'package:kisalu_express/models/categoria.dart';
import 'package:kisalu_express/models/utilizador.dart';

import '../../../helpers/ecra_apoio.dart';

class _SemRede extends MockKisaluRepository {
  @override
  Future<List<Categoria>> categorias() => throw const SemRedeException();
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> abrir(
    WidgetTester t, {
    double escala = 1,
    KisaluRepository? repo,
  }) => montarEcra(
    t,
    const RegistoProfissionalView(),
    escala: escala,
    repo: repo,
    destinos: ['/verificar-identidade'],
    comScaffold: false,
  );

  testWidgets('mostra os textos-chave do Figma', (t) async {
    await abrir(t);
    for (final s in [
      'Criar perfil',
      'Fotografia de perfil (opcional)',
      'Adicionar fotografia',
      'Nome completo',
      'Joaquim Manuel',
      'JM',
      'Que serviços presta?',
      'Canalizador',
      'Pedreiro',
      'Eletricista',
      'Pintor',
      'Mais…',
      'Anos de experiência',
      '10',
      'Zona de atuação',
      'Viana, Luanda',
      'Raio de deslocação',
      '10 km',
      'Continuar',
    ]) {
      expect(find.text(s), findsWidgets, reason: s);
    }
    expect(
      find.bySemanticsLabel('Passo 1 de 2 · O seu perfil'),
      findsOneWidget,
    );
    expect(t.takeException(), isNull);
  });

  testWidgets('"Mais…" mostra os restantes serviços e desaparece', (t) async {
    await abrir(t);
    expect(find.text('Carpinteiro'), findsNothing);
    await t.tap(find.text('Mais…'));
    await t.pumpAndSettle();
    expect(find.text('Carpinteiro'), findsOneWidget);
    expect(find.text('Transporte'), findsOneWidget);
    expect(find.text('Mais…'), findsNothing);
  });

  testWidgets('sem serviços escolhidos pede pelo menos um', (t) async {
    await abrir(t);
    await t.tap(find.text('Canalizador'));
    await t.tap(find.text('Pedreiro'));
    await t.pumpAndSettle();
    await t.ensureVisible(find.text('Continuar'));
    await t.pump();
    await t.tap(find.text('Continuar'));
    await t.pumpAndSettle();
    expect(find.text('Escolha pelo menos um serviço.'), findsOneWidget);
    expect(find.text('DESTINO /verificar-identidade'), findsNothing);
    // Voltar a escolher um serviço apaga o erro.
    await t.tap(find.text('Pintor'));
    await t.pumpAndSettle();
    expect(find.text('Escolha pelo menos um serviço.'), findsNothing);
  });

  testWidgets('nome vazio mostra o erro ao continuar', (t) async {
    await abrir(t);
    await t.enterText(find.widgetWithText(TextField, 'Joaquim Manuel'), '');
    await t.ensureVisible(find.text('Continuar'));
    await t.pump();
    await t.tap(find.text('Continuar'));
    await t.pumpAndSettle();
    expect(find.text('Escreva o seu nome.'), findsOneWidget);
    expect(find.text('DESTINO /verificar-identidade'), findsNothing);
  });

  testWidgets('anos de experiência só aceita números e até 60', (t) async {
    await abrir(t);
    final campo = find.byType(TextField).at(1);
    await t.enterText(campo, '7a');
    expect(t.widget<TextField>(campo).controller!.text, '7');
    await t.enterText(campo, '99');
    await t.ensureVisible(find.text('Continuar'));
    await t.pump();
    await t.tap(find.text('Continuar'));
    await t.pumpAndSettle();
    expect(find.text('Escreva um valor até 60 anos.'), findsOneWidget);
  });

  testWidgets('o avatar acompanha o nome escrito', (t) async {
    await abrir(t);
    await t.enterText(
      find.widgetWithText(TextField, 'Joaquim Manuel'),
      'Ana Cardoso',
    );
    await t.pump();
    expect(find.text('AC'), findsOneWidget);
  });

  testWidgets('o cursor muda o raio de deslocação', (t) async {
    await abrir(t);
    final slider = find.byType(Slider);
    await t.drag(slider, const Offset(-150, 0));
    await t.pumpAndSettle();
    expect(find.text('10 km'), findsNothing);
    // O valor escolhido e os limites "1 km" e "30 km".
    expect(find.textContaining(' km'), findsNWidgets(3));
    expect(find.text('30 km'), findsOneWidget);
  });

  testWidgets('continuar válido guarda, passa a profissional e avança', (
    t,
  ) async {
    final repo = MockKisaluRepository();
    await abrir(t, repo: repo);
    await t.ensureVisible(find.text('Continuar'));
    await t.pump();
    await t.tap(find.text('Continuar'));
    await t.pumpAndSettle();
    expect(find.text('DESTINO /verificar-identidade'), findsOneWidget);
    expect(repo.perfilAtivo, PerfilUtilizador.profissional);
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
