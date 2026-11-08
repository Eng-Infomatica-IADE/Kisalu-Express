import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/k_colors.dart';
import '../../../core/theme/k_icons.dart';
import '../../../core/theme/k_tokens.dart';
import '../../../core/theme/k_typography.dart';
import '../../../core/utils/k_format.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/repositories/kisalu_repository.dart';
import '../controllers/servico_confirmado_controller.dart';
import '../widgets/banner_fotos.dart';
import '../widgets/linha_resumo.dart';

/// Ecrã 17 · Serviço confirmado (profissional) — ver
/// docs/design/SCREENS.md#ecra-17.
class ServicoConfirmadoView extends StatelessWidget {
  const ServicoConfirmadoView({super.key, required this.pedidoId});

  final String pedidoId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (c) =>
          ServicoConfirmadoController(c.read<KisaluRepository>(), pedidoId)
            ..carregar(),
      child: const _Conteudo(),
    );
  }
}

class _Conteudo extends StatelessWidget {
  const _Conteudo();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ServicoConfirmadoController>();
    final margem = K.margemPara(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Sem seta: o serviço está concluído e não se volta ao leitor.
            const KTopBar(titulo: 'Serviço confirmado', mostrarVoltar: false),
            Expanded(
              child: KEstadoBuilder<ServicoConfirmadoDados>(
                estado: c.estado,
                onTentar: c.carregar,
                rotuloNaoEncontrado: 'Voltar ao Início',
                onNaoEncontrado: () => context.go(AppRoutes.inicio),
                carregar: (_) => Padding(
                  padding: EdgeInsets.all(margem),
                  child: const KSkeletonLista(),
                ),
                vazio: (_) => const SizedBox(),
                sucesso: (context, dados) =>
                    _Resumo(dados: dados, margem: margem),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Resumo extends StatelessWidget {
  const _Resumo({required this.dados, required this.margem});

  final ServicoConfirmadoDados dados;
  final double margem;

  @override
  Widget build(BuildContext context) {
    final servico = dados.servico;
    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(margem, K.s16, margem, K.s16 + 3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: K.sucessoCirculo - K.s8,
                    height: K.sucessoCirculo - K.s8,
                    decoration: const BoxDecoration(
                      color: KColors.sucessoFundo,
                      shape: BoxShape.circle,
                    ),
                    child: const ExcludeSemantics(
                      child: Icon(
                        KIcons.concluido,
                        size: K.icone32,
                        color: KColors.sucesso,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: K.s8 + 2),
                Semantics(
                  header: true,
                  child: Text(
                    'Trabalho concluído',
                    textAlign: TextAlign.center,
                    style: KTypography.titulo22,
                  ),
                ),
                const SizedBox(height: K.s8),
                Text(
                  '${servico.cliente} confirmou o valor combinado.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge!
                      .copyWith(color: KColors.neutro500),
                ),
                const SizedBox(height: K.s16 + 2),
                KCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: K.s16,
                    vertical: K.s12,
                  ),
                  child: Column(
                    children: [
                      LinhaResumo(rotulo: 'Serviço', valor: servico.servico),
                      LinhaResumo(
                        rotulo: 'Valor combinado',
                        valor: KFormat.kz(servico.valor),
                      ),
                      LinhaResumo(
                        rotulo: 'Data',
                        valor: KFormat.dataHora(servico.data, dados.agora),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: K.s16),
                const BannerFotos(),
                const Spacer(),
                const SizedBox(height: K.s24),
                KPrimaryButton(
                  rotulo: 'Adicionar fotos',
                  icone: KIcons.adicionar,
                  onPressed: () => mostrarKSnack(
                    context,
                    'Fotos adicionadas ao seu perfil.',
                  ),
                ),
                const SizedBox(height: K.s4 + 1),
                Center(
                  child: KTextLink(
                    grande: true,
                    rotulo: 'Voltar ao Início',
                    onPressed: () => context.go(AppRoutes.inicio),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
