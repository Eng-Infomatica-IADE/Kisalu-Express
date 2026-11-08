import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router/app_routes.dart';
import '../theme/k_icons.dart';
import 'k_icon_button.dart';

/// Voltar, sempre no canto superior esquerdo com nome acessível "Voltar".
/// Sem [onPressed], volta ao ecrã anterior ou, se não houver, ao Início.
class KBackButton extends StatelessWidget {
  const KBackButton({
    super.key,
    this.onPressed,
    this.contorno = true,
    this.escuro = false,
  });

  final VoidCallback? onPressed;
  final bool contorno;

  /// Sobre fundo Ébano (ecrã 16).
  final bool escuro;

  @override
  Widget build(BuildContext context) => KIconButton(
    icone: KIcons.voltar,
    rotulo: 'Voltar',
    contorno: contorno,
    escuro: escuro,
    onPressed:
        onPressed ??
        () => context.canPop() ? context.pop() : context.go(AppRoutes.inicio),
  );
}
