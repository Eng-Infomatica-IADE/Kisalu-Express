import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kisalu_express/core/theme/k_theme.dart';
import 'package:kisalu_express/data/repositories/kisalu_repository.dart';
import 'package:kisalu_express/data/repositories/mock_kisalu_repository.dart';
import 'package:provider/provider.dart';

/// Apoio dos testes de ecrã de autenticacao, inicio, profissional,
/// conversas e perfil: ecrã de 390 × 844, repositório injetado e um router
/// em que cada destino mostra "DESTINO" seguido do caminho.
void prepararEcra(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<GoRouter> montarEcra(
  WidgetTester tester,
  Widget ecra, {
  KisaluRepository? repo,
  double escala = 1,
  List<String> destinos = const [],
  bool comScaffold = true,
}) async {
  prepararEcra(tester);
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => comScaffold ? Scaffold(body: ecra) : ecra,
      ),
      for (final d in destinos)
        GoRoute(
          path: d,
          builder: (_, state) =>
              Scaffold(body: Center(child: Text('DESTINO ${state.uri.path}'))),
        ),
    ],
  );
  await tester.pumpWidget(
    Provider<KisaluRepository>.value(
      value: repo ?? MockKisaluRepository(),
      child: MaterialApp.router(
        theme: KTheme.light(),
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(escala)),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}
