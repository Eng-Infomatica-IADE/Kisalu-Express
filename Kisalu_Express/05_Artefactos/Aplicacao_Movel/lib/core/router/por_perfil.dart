import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/kisalu_repository.dart';
import '../../models/utilizador.dart';

/// Mostra um ecrã ou outro consoante o perfil ativo da sessão (Início e QR
/// têm versão de cliente e de profissional). Volta a decidir quando o
/// repositório avisa que o perfil mudou. É só composição de rotas: as views
/// continuam a não se conhecer.
class PorPerfil extends StatelessWidget {
  const PorPerfil({
    super.key,
    required this.cliente,
    required this.profissional,
  });

  final WidgetBuilder cliente;
  final WidgetBuilder profissional;

  @override
  Widget build(BuildContext context) {
    final repositorio = context.read<KisaluRepository>();
    return ListenableBuilder(
      listenable: repositorio.alteracoes,
      builder: (context, _) {
        final perfil = repositorio.perfilAtivo;
        return KeyedSubtree(
          key: ValueKey(perfil),
          child: perfil == PerfilUtilizador.profissional
              ? profissional(context)
              : cliente(context),
        );
      },
    );
  }
}
