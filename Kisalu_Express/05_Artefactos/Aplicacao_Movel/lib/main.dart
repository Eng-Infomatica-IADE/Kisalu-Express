import 'package:flutter/material.dart';

import 'core/router/app_routes.dart';
import 'data/repositories/rest_kisalu_repository.dart';
import 'kisalu_app.dart';
import 'services/api_client.dart';
import 'services/armazenamento_local.dart';

/// Com `--dart-define=KISALU_API=http://10.0.2.2:3000/api` a app fala com a
/// kisalu-api; sem ele usa os dados fictícios do mock.
///
/// Com a API, a sessão fica guardada no aparelho (RF01): se o token ainda
/// for aceite, a app abre no Início do perfil ativo em vez do Login.
Future<void> main() async {
  const url = ApiClient.urlAmbiente;
  if (url.isEmpty) {
    runApp(const KisaluApp());
    return;
  }
  WidgetsFlutterBinding.ensureInitialized();
  final repositorio = RestKisaluRepository(
    ApiClient(baseUrl: url),
    tokens: TokenSeguro(),
    rascunhos: RascunhoEmPreferencias(),
  );
  final comSessao = await repositorio.retomarSessao();
  runApp(
    KisaluApp(
      repository: repositorio,
      localInicial: comSessao ? AppRoutes.inicio : null,
    ),
  );
}
