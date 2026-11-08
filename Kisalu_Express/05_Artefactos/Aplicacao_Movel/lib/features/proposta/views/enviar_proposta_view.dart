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
import '../../../models/nova_proposta.dart';
import '../controllers/enviar_proposta_controller.dart';
import '../widgets/linha_componente.dart';

/// Ecrã 15 · Enviar proposta — ver docs/design/SCREENS.md#ecra-15.
class EnviarPropostaView extends StatelessWidget {
  const EnviarPropostaView({super.key, required this.pedidoId});

  final String pedidoId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (c) =>
          EnviarPropostaController(c.read<KisaluRepository>(), pedidoId)
            ..carregar(),
      child: const _Conteudo(),
    );
  }
}

class _Conteudo extends StatelessWidget {
  const _Conteudo();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<EnviarPropostaController>();
    final margem = K.margemPara(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const KTopBar(titulo: 'Enviar proposta'),
            Expanded(
              child: KEstadoBuilder<EnviarPropostaDados>(
                estado: c.estado,
                onTentar: c.carregar,
                rotuloNaoEncontrado: 'Ir para o início',
                onNaoEncontrado: () => context.go(AppRoutes.inicio),
                carregar: (_) => Padding(
                  padding: EdgeInsets.all(margem),
                  child: const KSkeletonLista(),
                ),
                vazio: (_) => const SizedBox(),
                sucesso: (context, dados) =>
                    _Formulario(dados: dados, margem: margem),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Formulario extends StatelessWidget {
  const _Formulario({required this.dados, required this.margem});

  final EnviarPropostaDados dados;
  final double margem;

  Future<void> _enviar(BuildContext context) async {
    final c = context.read<EnviarPropostaController>();
    final enviada = await c.enviar();
    if (!enviada || !context.mounted) return;
    mostrarKSnack(context, 'Proposta enviada. O cliente já a pode ver.');
    context.go(AppRoutes.inicio);
  }

  String _rotuloChegada(ChegadaProposta chegada) => chegada.duracao != null
      ? KFormat.duracaoCurta(chegada.duracao!)
      // A hora que o cliente pediu, dita como tal (v3.1).
      : switch (dados.pedido.quando) {
          final quando? => 'Hora pedida, ${KFormat.horaRelogio(quando)}',
          null => 'Hora pedida',
        };

  @override
  Widget build(BuildContext context) {
    final c = context.watch<EnviarPropostaController>();
    final text = Theme.of(context).textTheme;
    final pedido = dados.pedido;
    final titulo = text.titleMedium!.copyWith(fontWeight: FontWeight.w700);
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(margem, K.s4, margem, K.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                KCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pedido.titulo, style: text.titleSmall),
                      const SizedBox(height: K.s4),
                      Text(
                        pedido.descricao,
                        style: text.bodyMedium!.copyWith(
                          color: KColors.neutro700,
                          height: 18 / 14,
                        ),
                      ),
                      const SizedBox(height: K.s8),
                      Wrap(
                        spacing: K.s16,
                        runSpacing: K.s4,
                        children: [
                          KLinhaIcone(
                            icone: KIcons.localizacao,
                            texto:
                                '${pedido.zona} · '
                                '${KFormat.km(pedido.distanciaKm)}',
                          ),
                          KLinhaIcone(
                            icone: KIcons.calendario,
                            texto: KFormat.quandoPedido(
                              pedido.quando,
                              dados.agora,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: K.s16 - 1),
                Semantics(
                  header: true,
                  child: Text('O que inclui o preço?', style: titulo),
                ),
                const SizedBox(height: K.s16),
                KCard(
                  padding: const EdgeInsets.symmetric(horizontal: K.s16 - 1),
                  child: Column(
                    children: [
                      for (final componente in ComponenteValor.values)
                        LinhaComponente(
                          rotulo: switch (componente) {
                            ComponenteValor.maoDeObra => 'Mão de obra',
                            ComponenteValor.material => 'Material',
                            ComponenteValor.deslocacao => 'Deslocação',
                          },
                          valorInicial: c.valores[componente] ?? 0,
                          erro: c.erros[componente],
                          onChanged: (t) => c.alterar(componente, t),
                          onSaiu: (t) => c.validarAoSair(componente, t),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: K.s16 - 1),
                Semantics(
                  header: true,
                  child: Text('Quando pode chegar?', style: titulo),
                ),
                const SizedBox(height: K.s12),
                Wrap(
                  spacing: K.s8,
                  runSpacing: K.chipEntreLinhas,
                  children: [
                    for (final opcao in ChegadaProposta.values)
                      KChip(
                        rotulo: _rotuloChegada(opcao),
                        selecionado: c.chegada == opcao,
                        onSelecionar: (_) => c.escolherChegada(opcao),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(margem, K.s4, margem, K.s32 - 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'O cliente vê o total e o que inclui. Depois de aceite, o '
                'valor fechado não muda.',
                style: KTypography.corpo13.copyWith(color: KColors.neutro700),
              ),
              const SizedBox(height: K.s8),
              Text(
                'Valor fechado',
                style: text.bodyMedium!.copyWith(color: KColors.neutro500),
              ),
              KPriceText(c.valorFechado, tamanho: KPriceText.destaque),
              const SizedBox(height: K.s12),
              if (c.erroGeral != null) ...[
                KInlineAlert(
                  tipo: KAlertaTipo.erro,
                  titulo: 'Não enviámos a proposta.',
                  mensagem: c.erroGeral!,
                ),
                const SizedBox(height: K.s12),
              ],
              KPrimaryButton(
                rotulo: 'Enviar proposta',
                aCarregar: c.aEnviar,
                onPressed: () => _enviar(context),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
