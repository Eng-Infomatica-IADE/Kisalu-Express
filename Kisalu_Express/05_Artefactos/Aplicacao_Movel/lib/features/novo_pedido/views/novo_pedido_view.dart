import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/k_tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/repositories/kisalu_repository.dart';
import '../../../models/novo_pedido.dart';
import '../controllers/novo_pedido_controller.dart';
import '../widgets/novo_pedido_passo_data.dart';
import '../widgets/novo_pedido_passo_descricao.dart';
import '../widgets/novo_pedido_passo_morada.dart';
import '../widgets/novo_pedido_passo_rever.dart';

/// Ecrã 10 · Novo pedido (passo 3 "Rever o pedido", sem rede) e passos 1, 2
/// e 4 — ver docs/design/SCREENS.md#ecra-10.
///
/// Com rascunho no repositório abre no passo de rever, como no Figma. Sem
/// rascunho (ou com [passoInicial]) percorre-se o fluxo desde o passo 1.
class NovoPedidoView extends StatelessWidget {
  const NovoPedidoView({
    super.key,
    this.passoInicial,
    this.pausaTentativa,
    this.editarId,
    this.deId,
  });

  final PassoNovoPedido? passoInicial;

  /// 04 · "Editar pedido" (`?editar=:id`).
  final String? editarId;

  /// 07 · "Pedir de novo" (`?de=:id`).
  final String? deId;

  /// Duração simulada de "Tentar outra vez"; por omissão 1 s.
  final Duration? pausaTentativa;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (c) => NovoPedidoController(
        c.read<KisaluRepository>(),
        pausaTentativa: pausaTentativa ?? const Duration(seconds: 1),
      )..carregar(passoInicial: passoInicial, editarId: editarId, deId: deId),
      child: const _NovoPedidoCorpo(),
    );
  }
}

class _NovoPedidoCorpo extends StatelessWidget {
  const _NovoPedidoCorpo();

  String _legenda(PassoNovoPedido p) => switch (p) {
    PassoNovoPedido.descricao => 'O que precisa',
    PassoNovoPedido.morada => 'Onde',
    PassoNovoPedido.rever => 'Rever o pedido',
    PassoNovoPedido.data => 'Quando',
  };

  void _voltar(BuildContext context, NovoPedidoController c) {
    if (!c.voltar()) context.pop();
  }

  Future<void> _publicar(BuildContext context, NovoPedidoController c) async {
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (!await c.publicar()) return;
    final editado = c.editado;
    if (editado != null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Pedido atualizado.')));
      router.go(AppRoutes.pedido(editado.id));
      return;
    }
    final p = c.publicado!;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Pedido publicado. Já avisámos ${p.profissionaisAvisados} '
            '${p.categoriaPlural} perto de si.',
          ),
        ),
      );
    router.go(AppRoutes.pedido(p.pedido.id));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<NovoPedidoController>();
    final margem = K.margemPara(context);
    return PopScope(
      canPop: !c.temPassoAnterior,
      onPopInvokedWithResult: (podeFechar, _) {
        if (!podeFechar) c.voltar();
      },
      child: Scaffold(
        body: SafeArea(
          child: KEstadoBuilder<NovoPedido>(
            estado: c.estado,
            onTentar: c.carregar,
            vazio: (_) => const SizedBox.shrink(),
            sucesso: (context, _) => Column(
              children: [
                KTopBar(
                  titulo: c.modo == ModoNovoPedido.editar
                      ? 'Editar pedido'
                      : 'Novo pedido',
                  onVoltar: () => _voltar(context, c),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(margem, K.s4, margem, 0),
                  child: KStepProgress(
                    total: 4,
                    atual: c.passo.numero,
                    legenda: _legenda(c.passo),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(margem, K.s12, margem, K.s16),
                    child: switch (c.passo) {
                      PassoNovoPedido.descricao =>
                        const NovoPedidoPassoDescricao(),
                      PassoNovoPedido.morada => const NovoPedidoPassoMorada(),
                      PassoNovoPedido.rever => const NovoPedidoPassoRever(),
                      PassoNovoPedido.data => const NovoPedidoPassoData(),
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(margem, K.s8, margem, K.s16),
                  child: _Rodape(onPublicar: () => _publicar(context, c)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Rodape extends StatelessWidget {
  const _Rodape({required this.onPublicar});

  final VoidCallback onPublicar;

  @override
  Widget build(BuildContext context) {
    final c = context.watch<NovoPedidoController>();
    if (c.passo != PassoNovoPedido.rever) {
      return KPrimaryButton(
        rotulo: c.passo == PassoNovoPedido.data ? 'Guardar data' : 'Continuar',
        onPressed: c.avancar,
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        KPrimaryButton(
          rotulo: c.semRede
              ? 'A aguardar rede…'
              : c.modo == ModoNovoPedido.editar
              ? 'Guardar alterações'
              : 'Publicar pedido',
          aCarregar: c.aPublicar,
          onPressed: c.semRede ? null : onPublicar,
        ),
        if (c.semRede)
          KTextLink(
            rotulo: 'Tentar outra vez',
            onPressed: c.aTentar ? null : c.tentarOutraVez,
          ),
      ],
    );
  }
}
