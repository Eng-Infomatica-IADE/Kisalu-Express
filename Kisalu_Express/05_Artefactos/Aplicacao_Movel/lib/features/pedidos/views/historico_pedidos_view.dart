import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/k_colors.dart';
import '../../../core/theme/k_icons.dart';
import '../../../core/theme/k_tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/repositories/kisalu_repository.dart';
import '../../../models/estado_pedido.dart';
import '../../../models/filtro_pedidos.dart';
import '../../../models/pedido.dart';
import '../controllers/historico_pedidos_controller.dart';
import '../widgets/historico_comprovativo_folha.dart';
import '../widgets/historico_pedido_cartao.dart';

/// Ecrã 07 · Os seus pedidos — ver docs/design/SCREENS.md#ecra-07.
class HistoricoPedidosView extends StatelessWidget {
  const HistoricoPedidosView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) =>
          HistoricoPedidosController(context.read<KisaluRepository>())
            ..carregar(),
      child: const _Conteudo(),
    );
  }
}

class _Conteudo extends StatelessWidget {
  const _Conteudo();

  Future<void> _verComprovativo(BuildContext context, Pedido pedido) async {
    final controller = context.read<HistoricoPedidosController>();
    final comprovativo = await controller.comprovativo(pedido.id);
    if (!context.mounted) return;
    if (comprovativo == null) {
      mostrarKSnack(context, 'Ainda não há comprovativo para este pedido.');
      return;
    }
    await mostrarKFolha<void>(
      context,
      builder: (folha) => HistoricoComprovativoFolha(
        comprovativo: comprovativo,
        onPartilhar: () {
          Navigator.of(folha).pop();
          mostrarKSnack(context, 'Em breve');
        },
        // Só dentro da garantia de 7 dias (RF11, `pode_reclamar`).
        onReportar: pedido.podeReclamar
            ? () {
                Navigator.of(folha).pop();
                mostrarKFolhaProblema(context, pedido.id);
              }
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<HistoricoPedidosController>();
    final text = Theme.of(context).textTheme;
    final margem = K.margemPara(context);

    return KAoVoltar(
      aoVoltar: controller.recarregar,
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(margem, K.s8 + 2, margem, K.s12),
                child: Semantics(
                  header: true,
                  child: Text('Os seus pedidos', style: text.headlineSmall),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: margem),
                child: Row(
                  children: [
                    for (final f in FiltroPedidos.values) ...[
                      if (f != FiltroPedidos.todos) const SizedBox(width: K.s8),
                      KChip(
                        rotulo: f.rotulo,
                        compacto: true,
                        selecionado: controller.filtro == f,
                        onSelecionar: (_) => controller.escolherFiltro(f),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: KEstadoBuilder<List<Pedido>>(
                  estado: controller.estado,
                  onTentar: controller.carregar,
                  carregar: (_) => Padding(
                    padding: EdgeInsets.all(margem),
                    child: const KSkeletonLista(),
                  ),
                  vazio: (_) => _Mensagem(
                    margem: margem,
                    icone: KIcons.pedidos,
                    titulo: 'Ainda não tem pedidos',
                    texto: 'Quando publicar um pedido, ele aparece aqui.',
                  ),
                  sucesso: (context, _) {
                    final pedidos = controller.filtrados;
                    if (pedidos.isEmpty) {
                      return _Mensagem(
                        margem: margem,
                        icone: KIcons.pedidos,
                        titulo:
                            'Sem pedidos ${controller.filtro.rotulo.toLowerCase()}',
                        texto: 'Escolha outro filtro para ver os restantes.',
                      );
                    }
                    return RefreshIndicator(
                      color: KColors.laranja,
                      onRefresh: controller.recarregar,
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          margem,
                          K.s12,
                          margem,
                          K.s24,
                        ),
                        itemCount: pedidos.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: K.s16 + K.s4 / 2),
                        itemBuilder: (context, i) {
                          final p = pedidos[i];
                          final acoes = controller.mostraAcoes(p);
                          return HistoricoPedidoCartao(
                            pedido: p,
                            agora: controller.agora,
                            // Profissional: detalhe do trabalho. Cliente: novo
                            // (com propostas por ver) ou em curso abre o ecrã 04;
                            // concluídos e cancelados usam as ações.
                            onTap: controller.modoProfissional
                                ? () => context.push(AppRoutes.trabalho(p.id))
                                : (p.estado == EstadoPedido.emCurso ||
                                      p.estado == EstadoPedido.novo)
                                ? () => context.go(AppRoutes.pedido(p.id))
                                : null,
                            onPedirDeNovo: acoes
                                ? () =>
                                      context.push(AppRoutes.pedirDeNovo(p.id))
                                : null,
                            onVerComprovativo: acoes
                                ? () => _verComprovativo(context, p)
                                : null,
                            onAvaliar: controller.podeAvaliar(p)
                                ? () => context.push(AppRoutes.avaliar(p.id))
                                : null,
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Mensagem extends StatelessWidget {
  const _Mensagem({
    required this.margem,
    required this.icone,
    required this.titulo,
    required this.texto,
  });

  final double margem;
  final IconData icone;
  final String titulo;
  final String texto;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: margem + K.s16),
      child: KEmptyState(icone: icone, titulo: titulo, mensagem: texto),
    ),
  );
}
