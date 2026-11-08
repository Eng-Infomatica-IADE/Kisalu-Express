import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/state/estado_ui.dart';
import '../../../core/theme/k_colors.dart';
import '../../../core/theme/k_icons.dart';
import '../../../core/theme/k_tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/repositories/kisalu_repository.dart';
import '../../../models/ordenacao_propostas.dart';
import '../../../models/pedido.dart';
import '../../../models/proposta.dart';
import '../controllers/pedido_detalhe_controller.dart';
import '../widgets/confirmar_proposta_sheet.dart';
import '../widgets/pedido_detalhe_aceite_cartao.dart';
import '../widgets/pedido_detalhe_cartao.dart';
import '../widgets/pedido_detalhe_proposta_cartao.dart';

/// Ecrã 04 · O meu pedido — ver docs/design/SCREENS.md#ecra-04.
/// Vive dentro do `AppShell` (a barra inferior é da casca).
class PedidoDetalheView extends StatelessWidget {
  const PedidoDetalheView({super.key, required this.pedidoId});
  final String pedidoId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (c) =>
          PedidoDetalheController(c.read<KisaluRepository>(), pedidoId)
            ..carregar(),
      child: const _PedidoDetalheCorpo(),
    );
  }
}

enum _AcaoMenu { editar, cancelar }

class _PedidoDetalheCorpo extends StatelessWidget {
  const _PedidoDetalheCorpo();

  Future<void> _abrirMenu(BuildContext botao) async {
    final controller = botao.read<PedidoDetalheController>();
    final router = GoRouter.of(botao);
    final caixa = botao.findRenderObject()! as RenderBox;
    final overlay = Overlay.of(botao).context.findRenderObject()! as RenderBox;
    final posicao = RelativeRect.fromRect(
      Rect.fromPoints(
        caixa.localToGlobal(Offset.zero, ancestor: overlay),
        caixa.localToGlobal(
          caixa.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );
    final escolha = await showMenu<_AcaoMenu>(
      context: botao,
      position: posicao,
      color: KColors.branco,
      items: [
        // Com proposta aceite já não se edita (a API recusa).
        if (controller.podeEditar)
          const PopupMenuItem(
            value: _AcaoMenu.editar,
            height: K.alvoMinimo,
            child: Text('Editar pedido'),
          ),
        const PopupMenuItem(
          value: _AcaoMenu.cancelar,
          height: K.alvoMinimo,
          child: Text('Cancelar pedido'),
        ),
      ],
    );
    if (!botao.mounted) return;
    switch (escolha) {
      case _AcaoMenu.editar:
        await router.push(AppRoutes.editarPedido(controller.pedidoId));
        await controller.recarregar();
      case _AcaoMenu.cancelar:
        await _cancelar(botao, controller);
      case null:
        break;
    }
  }

  Future<void> _cancelar(
    BuildContext context,
    PedidoDetalheController controller,
  ) async {
    final estado = controller.estado;
    final n = estado is Sucesso<Pedido> ? estado.dados.propostas.length : 0;
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (dialogo) => AlertDialog(
        title: const Text('Cancelar este pedido?'),
        content: Text(
          n == 1
              ? 'O profissional que enviou proposta vai ser avisado.'
              : 'Os $n profissionais que enviaram proposta vão ser avisados.',
        ),
        actions: [
          KTextLink(
            rotulo: 'Manter pedido',
            onPressed: () => Navigator.of(dialogo).pop(false),
          ),
          KTextLink(
            rotulo: 'Cancelar pedido',
            destrutivo: true,
            onPressed: () => Navigator.of(dialogo).pop(true),
          ),
        ],
      ),
    );
    if (confirmou != true || !context.mounted) return;
    final router = GoRouter.of(context);
    final erro = await controller.cancelar();
    if (!context.mounted) return;
    if (erro != null) {
      mostrarKSnack(context, erro);
    } else {
      mostrarKSnack(context, 'Pedido cancelado.');
      router.go(AppRoutes.pedidos);
    }
  }

  Future<void> _aceitar(
    BuildContext context,
    PedidoDetalheController controller,
    Proposta proposta,
  ) async {
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final aceite = await mostrarConfirmarProposta(
      context,
      pedidoId: controller.pedidoId,
      proposta: proposta,
    );
    if (aceite == null) return;
    controller.aoAceitar(aceite);
    final nome = proposta.profissional.primeiroNome;
    router.go(AppRoutes.qrDoPedido(controller.pedidoId));
    // O SnackBar desaparece sozinho (não tapa a barra de escrita da
    // conversa) e ao sair do QR. Depois disso, "Desfazer aceitação" continua
    // no detalhe 04 durante os 5 min que a API permite.
    messenger.hideCurrentSnackBar();
    final aberto = messenger.showSnackBar(
      SnackBar(
        persist: false,
        duration: _duracaoDesfazer,
        content: Text(
          'Proposta aceite. O $nome já foi avisado. '
          'Pode desfazer nos próximos 5 minutos.',
        ),
        action: SnackBarAction(
          label: 'Desfazer',
          onPressed: () => _desfazer(messenger, controller),
        ),
      ),
    );
    void aoNavegar() {
      if (router.routeInformationProvider.value.uri.path != AppRoutes.qr) {
        aberto.close();
      }
    }

    router.routerDelegate.addListener(aoNavegar);
    aberto.closed.whenComplete(
      () => router.routerDelegate.removeListener(aoNavegar),
    );
  }

  static const _duracaoDesfazer = Duration(seconds: 10);

  Future<void> _desfazer(
    ScaffoldMessengerState messenger,
    PedidoDetalheController controller,
  ) async {
    final erro = await controller.desfazerAceitacao();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            erro ??
                'Aceitação desfeita. As propostas voltaram a estar abertas.',
          ),
        ),
      );
  }

  Future<void> _recusar(
    BuildContext context,
    PedidoDetalheController controller,
    Proposta proposta,
  ) async {
    final nome = proposta.profissional.primeiroNome;
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (dialogo) => AlertDialog(
        title: const Text('Recusar esta proposta?'),
        content: Text(
          'A proposta do $nome sai da lista e ele é avisado. '
          'Não é possível desfazer.',
        ),
        actions: [
          KTextLink(
            rotulo: 'Manter',
            onPressed: () => Navigator.of(dialogo).pop(false),
          ),
          KTextLink(
            rotulo: 'Recusar',
            destrutivo: true,
            onPressed: () => Navigator.of(dialogo).pop(true),
          ),
        ],
      ),
    );
    if (confirmou != true || !context.mounted) return;
    final erro = await controller.recusar(proposta.id);
    if (!context.mounted) return;
    mostrarKSnack(context, erro ?? 'Proposta recusada.');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<PedidoDetalheController>();
    final margem = K.margemPara(context);
    return KAoVoltar(aoVoltar: c.recarregar, child: _corpo(context, c, margem));
  }

  Widget _corpo(
    BuildContext context,
    PedidoDetalheController c,
    double margem,
  ) {
    return ColoredBox(
      color: KColors.areia50,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            KTopBar(
              titulo: 'O meu pedido',
              acao: c.estado is Sucesso<Pedido>
                  ? Builder(
                      builder: (botao) => KIconButton(
                        icone: KIcons.mais,
                        rotulo: 'Mais opções do pedido',
                        onPressed: () => _abrirMenu(botao),
                      ),
                    )
                  : null,
            ),
            Expanded(
              child: KEstadoBuilder<Pedido>(
                estado: c.estado,
                onTentar: c.carregar,
                rotuloNaoEncontrado: 'Ver os meus pedidos',
                onNaoEncontrado: () => context.go(AppRoutes.pedidos),
                vazio: (_) => const SizedBox.shrink(),
                sucesso: (context, pedido) {
                  final propostas = c.propostas;
                  final conversa = pedido.conversaId;
                  return RefreshIndicator(
                    color: KColors.laranja,
                    onRefresh: c.recarregar,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(margem, K.s8, margem, K.s24),
                      children: [
                        PedidoDetalheCartao(pedido: pedido, agora: c.agora),
                        if (c.temAceite) ...[
                          const SizedBox(height: K.s16 + K.s4 / 2),
                          const KSecaoTitulo(titulo: 'Proposta aceite'),
                          const SizedBox(height: K.s12),
                          PedidoDetalheAceiteCartao(
                            pedido: pedido,
                            agora: c.agora,
                            onConversa: () => conversa == null
                                ? context.go(AppRoutes.conversas)
                                : context.push(AppRoutes.conversa(conversa)),
                            onVerQr: c.podeVerQr
                                ? () => context.go(
                                    AppRoutes.qrDoPedido(pedido.id),
                                  )
                                : null,
                            onDesfazer: c.podeDesfazer
                                ? () => _desfazer(
                                    ScaffoldMessenger.of(context),
                                    c,
                                  )
                                : null,
                          ),
                        ] else if (propostas.isNotEmpty) ...[
                          const SizedBox(height: K.s16 + K.s4 / 2),
                          const KSecaoTitulo(titulo: 'Propostas recebidas'),
                          const SizedBox(height: K.s12 + 1),
                          Wrap(
                            spacing: K.s8,
                            children: [
                              for (final o in OrdenacaoPropostas.values)
                                KChip(
                                  rotulo: o.rotulo,
                                  selecionado: c.ordenacao == o,
                                  onSelecionar: (_) => c.ordenar(o),
                                ),
                            ],
                          ),
                          const SizedBox(height: K.s12),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            itemCount: propostas.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: K.s16 + K.s4),
                            itemBuilder: (context, i) {
                              final p = propostas[i];
                              return PedidoDetalhePropostaCartao(
                                proposta: p,
                                agora: c.agora,
                                destacado: i == 0,
                                onVerPerfil: () => context.push(
                                  AppRoutes.profissional(p.profissional.id),
                                ),
                                onAceitar: c.podeAceitar
                                    ? () => _aceitar(context, c, p)
                                    : null,
                                onRecusar: c.podeAceitar
                                    ? () => _recusar(context, c, p)
                                    : null,
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
