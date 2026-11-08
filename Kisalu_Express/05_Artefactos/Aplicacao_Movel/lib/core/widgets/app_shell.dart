import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/kisalu_repository.dart';
import '../../models/pedido.dart';
import '../../models/utilizador.dart';
import 'k_bottom_nav_bar.dart';

/// Casca dos 5 separadores. O QR fica desativado quando o repositório não
/// tem serviço em curso (ecrã 09) ou quando a galeria força o estado vazio
/// (`/qr?vazio=1`). Volta a ler sempre que o repositório avisa que um pedido
/// mudou (aceitar, desfazer, confirmar). No modo profissional o QR está
/// sempre disponível (ecrã 16: ler o código do cliente).
class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.navigationShell,
    this.qrVazioForcado = false,
  });

  final StatefulNavigationShell navigationShell;
  final bool qrVazioForcado;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late final KisaluRepository _repositorio = context.read<KisaluRepository>();
  late Future<Pedido?> _servicoEmCurso = _repositorio.servicoEmCurso();

  void _reler() {
    setState(() {
      _servicoEmCurso = _repositorio.servicoEmCurso();
    });
  }

  @override
  void initState() {
    super.initState();
    _repositorio.alteracoes.addListener(_reler);
  }

  @override
  void dispose() {
    _repositorio.alteracoes.removeListener(_reler);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shell = widget.navigationShell;
    final modoProfissional =
        _repositorio.perfilAtivo == PerfilUtilizador.profissional;
    return Scaffold(
      body: shell,
      bottomNavigationBar: FutureBuilder<Pedido?>(
        future: _servicoEmCurso,
        builder: (context, snapshot) => KBottomNavBar(
          indiceAtual: shell.currentIndex,
          qrDisponivel:
              modoProfissional ||
              (snapshot.data != null && !widget.qrVazioForcado),
          onSelecionar: (i) =>
              shell.goBranch(i, initialLocation: i == shell.currentIndex),
        ),
      ),
    );
  }
}
