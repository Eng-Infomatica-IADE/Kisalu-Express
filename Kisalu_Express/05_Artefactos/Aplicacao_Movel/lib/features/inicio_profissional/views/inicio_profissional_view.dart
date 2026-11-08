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
import '../../../models/painel_profissional.dart';
import '../controllers/inicio_profissional_controller.dart';
import '../widgets/cartao_disponibilidade.dart';
import '../widgets/cartao_pedido_perto.dart';
import '../widgets/estatistica_cartao.dart';

/// Ecrã 14 · Início do profissional — ver docs/design/SCREENS.md#ecra-14.
/// Vive dentro do `AppShell` (separador Início em modo profissional).
class InicioProfissionalView extends StatelessWidget {
  const InicioProfissionalView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (c) => InicioProfissionalController(
        c.read<KisaluRepository>(),
        saudacaoPara: KFormat.saudacao,
      )..carregar(),
      child: const _Corpo(),
    );
  }
}

class _Corpo extends StatelessWidget {
  const _Corpo();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<InicioProfissionalController>();
    final margem = K.margemPara(context);
    return SafeArea(
      bottom: false,
      child: KEstadoBuilder<InicioProfissionalDados>(
        estado: c.estado,
        onTentar: c.carregar,
        carregar: (_) => Padding(
          padding: EdgeInsets.all(margem),
          child: const KSkeletonLista(),
        ),
        vazio: (_) => Padding(
          padding: EdgeInsets.all(margem),
          child: const Center(
            child: Text(
              'Ainda não há pedidos perto de si.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        sucesso: (context, dados) => KAoVoltar(
          aoVoltar: c.recarregar,
          child: RefreshIndicator(
            color: KColors.laranja,
            onRefresh: c.recarregar,
            child: _Conteudo(dados: dados, margem: margem),
          ),
        ),
      ),
    );
  }
}

class _Conteudo extends StatelessWidget {
  const _Conteudo({required this.dados, required this.margem});

  final InicioProfissionalDados dados;
  final double margem;

  @override
  Widget build(BuildContext context) {
    final c = context.watch<InicioProfissionalController>();
    final painel = dados.painel;
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(margem, K.s8 + 2, margem, K.s24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        '${dados.saudacao}, ${painel.nome}',
                        style: KTypography.titulo24,
                      ),
                    ),
                    const SizedBox(height: K.s4),
                    _Zona(painel: painel),
                  ],
                ),
              ),
              const SizedBox(width: K.s8),
              Transform.translate(
                // Como no Início do cliente: alinha o quadrado à margem.
                offset: const Offset(2, 2),
                child: KIconButton(
                  icone: KIcons.notificacoes,
                  rotulo: 'Notificações',
                  mostrarPonto: dados.naoLidas > 0,
                  onPressed: () async {
                    await context.push(AppRoutes.notificacoes);
                    await c.recarregar();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: K.s16),
          CartaoDisponibilidade(
            disponivel: c.disponivel,
            onMudar: c.mudarDisponibilidade,
          ),
          const SizedBox(height: K.s12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: EstatisticaCartao(
                    valor: '${painel.pedidosNovos}',
                    legenda: 'Pedidos novos',
                  ),
                ),
                const SizedBox(width: K.s12),
                Expanded(
                  child: EstatisticaCartao(
                    valor: KFormat.decimal(painel.rating),
                    legenda: 'Avaliação',
                  ),
                ),
                const SizedBox(width: K.s12),
                Expanded(
                  child: EstatisticaCartao(
                    valor: '${painel.servicos}',
                    legenda: 'Serviços',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: K.s4),
          KSecaoTitulo(
            titulo: 'Pedidos perto de si',
            rotuloAcao: 'Ver todos',
            onAcao: () => mostrarKSnack(context, 'Em breve'),
          ),
          const SizedBox(height: K.s8),
          if (painel.pedidos.isEmpty)
            Text(
              'Ainda não há pedidos perto de si.',
              style: Theme.of(context).textTheme.bodyMedium!
                  .copyWith(color: KColors.neutro700),
            )
          else
            for (final p in painel.pedidos) ...[
              CartaoPedidoPerto(
                pedido: p,
                agora: dados.agora,
                onVer: () => context.push(AppRoutes.enviarProposta(p.id)),
              ),
              const SizedBox(height: K.s16),
            ],
        ],
      ),
    );
  }
}

/// "Viana · até 10 km", com o pin laranja.
class _Zona extends StatelessWidget {
  const _Zona({required this.painel});

  final PainelProfissional painel;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          const WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Icon(
              KIcons.localizacao,
              size: K.icone16,
              color: KColors.laranja,
            ),
          ),
          const TextSpan(text: '  '),
          TextSpan(text: '${painel.zona} · até ${painel.raioKm} km'),
        ],
      ),
      style: KTypography.corpo13,
    );
  }
}
