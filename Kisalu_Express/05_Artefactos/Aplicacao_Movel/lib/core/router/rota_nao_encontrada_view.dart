import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/k_icons.dart';
import '../theme/k_tokens.dart';
import '../widgets/k_empty_state.dart';
import 'app_routes.dart';

/// Ecrã de erro do router: rota desconhecida ou `:id` com formato inválido.
/// Não mostra detalhes técnicos da rota.
class RotaNaoEncontradaView extends StatelessWidget {
  const RotaNaoEncontradaView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(K.margemPara(context)),
            child: KEmptyState(
              icone: KIcons.aviso,
              titulo: 'Não encontrámos esta página',
              mensagem: 'O endereço pode estar errado ou já não existir.',
              rotuloAcao: 'Ir para o início',
              onAcao: () => context.go(AppRoutes.inicio),
            ),
          ),
        ),
      ),
    );
  }
}
