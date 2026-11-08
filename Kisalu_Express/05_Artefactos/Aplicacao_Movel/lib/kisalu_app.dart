import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/router/app_router.dart';
import 'core/router/app_routes.dart';
import 'core/theme/k_theme.dart';
import 'data/repositories/kisalu_repository.dart';
import 'data/repositories/mock_kisalu_repository.dart';
import 'data/repositories/rest_kisalu_repository.dart';

class KisaluApp extends StatefulWidget {
  const KisaluApp({super.key, this.repository, this.localInicial});

  /// `RestKisaluRepository` quando há `KISALU_API` (ver `main.dart`). Sem
  /// valor, usa um [MockKisaluRepository] novo.
  final KisaluRepository? repository;

  /// Rota de arranque: o Início quando a sessão guardada continua válida
  /// (`retomarSessao`, em `main.dart`); sem valor, o Login.
  final String? localInicial;

  @override
  State<KisaluApp> createState() => _KisaluAppState();
}

class _KisaluAppState extends State<KisaluApp> {
  late final GoRouter _router = createRouter(
    initialLocation: widget.localInicial,
  );
  late final KisaluRepository _repositorio =
      widget.repository ?? MockKisaluRepository();

  /// Só o repositório REST tem sessão que pode expirar (401).
  Listenable? get _sessaoExpirada => switch (_repositorio) {
    final RestKisaluRepository r => r.sessaoExpirada,
    _ => null,
  };

  @override
  void initState() {
    super.initState();
    _sessaoExpirada?.addListener(_voltarAoLogin);
  }

  void _voltarAoLogin() => _router.go(AppRoutes.login);

  @override
  Widget build(BuildContext context) {
    return Provider<KisaluRepository>.value(
      value: _repositorio,
      child: MaterialApp.router(
        title: 'Kisalu Express',
        debugShowCheckedModeBanner: false,
        theme: KTheme.light(),
        locale: const Locale('pt', 'PT'),
        routerConfig: _router,
      ),
    );
  }

  @override
  void dispose() {
    _sessaoExpirada?.removeListener(_voltarAoLogin);
    _router.dispose();
    super.dispose();
  }
}
