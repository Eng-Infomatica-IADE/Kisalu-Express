import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kisalu_express/core/router/por_perfil.dart';
import 'package:kisalu_express/data/repositories/kisalu_repository.dart';
import 'package:kisalu_express/data/repositories/mock_kisalu_repository.dart';
import 'package:kisalu_express/models/utilizador.dart';
import 'package:provider/provider.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> montar(WidgetTester tester, KisaluRepository repo) =>
      tester.pumpWidget(
        Provider<KisaluRepository>.value(
          value: repo,
          child: MaterialApp(
            home: PorPerfil(
              cliente: (_) => const Text('ECRÃ CLIENTE'),
              profissional: (_) => const Text('ECRÃ PROFISSIONAL'),
            ),
          ),
        ),
      );

  testWidgets('cliente por omissão', (tester) async {
    await montar(tester, MockKisaluRepository());
    expect(find.text('ECRÃ CLIENTE'), findsOneWidget);
    expect(find.text('ECRÃ PROFISSIONAL'), findsNothing);
  });

  testWidgets('profissional quando o perfil ativo é profissional', (
    tester,
  ) async {
    final repo = MockKisaluRepository();
    await repo.mudarPerfil(PerfilUtilizador.profissional);
    await montar(tester, repo);
    expect(find.text('ECRÃ PROFISSIONAL'), findsOneWidget);
  });

  testWidgets('troca de ecrã quando o repositório avisa da mudança', (
    tester,
  ) async {
    final repo = MockKisaluRepository();
    await montar(tester, repo);
    await repo.mudarPerfil(PerfilUtilizador.profissional);
    await tester.pump();
    expect(find.text('ECRÃ PROFISSIONAL'), findsOneWidget);
    await repo.mudarPerfil(PerfilUtilizador.cliente);
    await tester.pump();
    expect(find.text('ECRÃ CLIENTE'), findsOneWidget);
  });

  testWidgets('não reconstrói se o perfil não mudou', (tester) async {
    final repo = MockKisaluRepository();
    var construcoes = 0;
    await tester.pumpWidget(
      Provider<KisaluRepository>.value(
        value: repo,
        child: MaterialApp(
          home: PorPerfil(
            cliente: (_) {
              construcoes++;
              return const Text('ECRÃ CLIENTE');
            },
            profissional: (_) => const Text('ECRÃ PROFISSIONAL'),
          ),
        ),
      ),
    );
    final antes = construcoes;
    await repo.mudarPerfil(PerfilUtilizador.cliente); // já é cliente
    await tester.pump();
    expect(construcoes, antes);
  });
}
