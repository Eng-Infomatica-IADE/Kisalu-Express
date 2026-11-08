import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/k_colors.dart';
import '../../../core/theme/k_icons.dart';
import '../../../core/theme/k_tokens.dart';
import '../../../core/theme/k_typography.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/repositories/kisalu_repository.dart';
import '../controllers/confirmar_servico_controller.dart';
import '../widgets/passos_confirmacao.dart';
import '../widgets/problema_folha.dart';
import '../widgets/qr_codigo_cartao.dart';

/// Separador QR. Ecrã 05 · Confirmar serviço (há serviço em curso) ou
/// ecrã 09 · estado vazio (não há) — ver docs/design/SCREENS.md#ecra-05.
class ConfirmarServicoView extends StatelessWidget {
  const ConfirmarServicoView({
    super.key,
    this.forcarVazio = false,
    this.pedidoId,
    this.intervaloVerificacao,
  });

  /// Mostra o ecrã 09 mesmo com serviço em curso (galeria dev: `/qr?vazio=1`).
  final bool forcarVazio;

  /// QR de um pedido concreto (`/qr?pedido=:id`, vindo do detalhe 04).
  final String? pedidoId;

  /// Intervalo do "já foi confirmado?"; por omissão 5 s.
  final Duration? intervaloVerificacao;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      // Outro pedido no URL → outro controller.
      key: ValueKey(pedidoId),
      create: (context) => ConfirmarServicoController(
        context.read<KisaluRepository>(),
        forcarVazio: forcarVazio,
        pedidoId: pedidoId,
        intervaloVerificacao:
            intervaloVerificacao ?? const Duration(seconds: 5),
      )..carregar(),
      child: const _Conteudo(),
    );
  }
}

class _Conteudo extends StatefulWidget {
  const _Conteudo();

  @override
  State<_Conteudo> createState() => _ConteudoState();
}

class _ConteudoState extends State<_Conteudo> {
  late final ConfirmarServicoController _controller = context
      .read<ConfirmarServicoController>();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_aoConcluir);
  }

  @override
  void dispose() {
    _controller.removeListener(_aoConcluir);
    super.dispose();
  }

  /// O profissional confirmou: abre a avaliação (06).
  void _aoConcluir() {
    final id = _controller.concluidoId;
    if (id == null || !mounted) return;
    _controller.avaliacaoAberta();
    context.push(AppRoutes.avaliar(id));
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ConfirmarServicoController>();
    final margem = K.margemPara(context);
    return KAoVoltar(
      aoVoltar: controller.recarregar,
      child: _corpo(context, controller, margem),
    );
  }

  Widget _corpo(
    BuildContext context,
    ConfirmarServicoController controller,
    double margem,
  ) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const KTopBar(titulo: 'Confirmar serviço'),
            Expanded(
              child: KEstadoBuilder<ServicoParaConfirmar>(
                estado: controller.estado,
                onTentar: controller.carregar,
                carregar: (_) => Padding(
                  padding: EdgeInsets.all(margem),
                  child: const KSkeletonLista(),
                ),
                vazio: (context) => Align(
                  alignment: Alignment.topCenter,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      margem + K.s24,
                      K.s32 * 2,
                      margem + K.s24,
                      K.s24,
                    ),
                    child: KEmptyState(
                      icone: KIcons.codigoQr,
                      titulo: 'Ainda não tem serviços para confirmar',
                      mensagem:
                          'Quando aceitar uma proposta, o código QR do '
                          'serviço aparece aqui.',
                      rotuloAcao: 'Ver os meus pedidos',
                      onAcao: () => context.go(AppRoutes.pedidos),
                    ),
                  ),
                ),
                sucesso: (context, servico) => _Servico(
                  servico: servico,
                  controller: controller,
                  margem: margem,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Servico extends StatelessWidget {
  const _Servico({
    required this.servico,
    required this.controller,
    required this.margem,
  });

  final ServicoParaConfirmar servico;
  final ConfirmarServicoController controller;
  final double margem;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(margem, K.s4, margem, K.s24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Mostre o código só quando o trabalho estiver concluído e '
            'verificado.',
            style: KTypography.corpo15.copyWith(color: KColors.neutro700),
          ),
          const SizedBox(height: K.s12 + K.s4 / 2),
          QrCodigoCartao(
            servico: servico,
            // Só nos dados fictícios: na API real o ecrã avança sozinho quando
            // o profissional confirma.
            onTocarQr: controller.atalhoDemonstracao
                ? () => context.push(AppRoutes.avaliar(servico.pedidoId))
                : null,
          ),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              KTextLink(
                rotulo: 'O trabalho tem um problema?',
                destrutivo: true,
                onPressed: () =>
                    mostrarKFolhaProblema(context, servico.pedidoId),
              ),
              KTextLink(
                rotulo: 'Como funciona?',
                onPressed: () => mostrarKFolha<void>(
                  context,
                  builder: (_) => const ComoFuncionaFolha(),
                ),
              ),
            ],
          ),
          const KCard(child: PassosConfirmacao()),
        ],
      ),
    );
  }
}
