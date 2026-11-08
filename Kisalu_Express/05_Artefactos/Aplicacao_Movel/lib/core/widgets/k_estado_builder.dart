import 'package:flutter/material.dart';

import '../state/estado_ui.dart';
import '../theme/k_icons.dart';
import 'k_empty_state.dart';
import 'k_skeleton.dart';

/// Desenha um [EstadoUi] com os quatro desvios do Style Guide, para os
/// ecrãs não repetirem o `switch`:
/// - a carregar → [carregar] ou esqueletos;
/// - sucesso → [sucesso];
/// - vazio → [vazio] (obrigatório: cada ecrã tem o seu texto);
/// - erro → mensagem em português com "Tentar outra vez" ([onTentar]);
///   `naoEncontrado` → estado "não encontrado" com [rotuloNaoEncontrado].
class KEstadoBuilder<T> extends StatelessWidget {
  const KEstadoBuilder({
    super.key,
    required this.estado,
    required this.sucesso,
    required this.vazio,
    this.carregar,
    this.onTentar,
    this.rotuloNaoEncontrado,
    this.onNaoEncontrado,
  });

  final EstadoUi<T> estado;
  final Widget Function(BuildContext context, T dados) sucesso;
  final WidgetBuilder vazio;
  final WidgetBuilder? carregar;
  final VoidCallback? onTentar;

  /// Ação do estado "não encontrado", ex. "Ver os meus pedidos".
  final String? rotuloNaoEncontrado;
  final VoidCallback? onNaoEncontrado;

  @override
  Widget build(BuildContext context) => switch (estado) {
    Carregar() => carregar?.call(context) ?? const KSkeletonLista(),
    Sucesso(:final dados) => sucesso(context, dados),
    Vazio() => vazio(context),
    Erro(:final naoEncontrado, :final mensagem) =>
      naoEncontrado
          ? KEmptyState(
              icone: KIcons.pesquisa,
              titulo: 'Não encontrado',
              mensagem: mensagem,
              rotuloAcao: rotuloNaoEncontrado,
              onAcao: onNaoEncontrado,
            )
          : KEmptyState(
              icone: KIcons.aviso,
              titulo: 'Não foi possível carregar',
              mensagem: mensagem,
              rotuloAcao: onTentar == null ? null : 'Tentar outra vez',
              onAcao: onTentar,
            ),
  };
}
