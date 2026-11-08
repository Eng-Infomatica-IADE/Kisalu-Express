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
import '../../../models/estado_pedido.dart';
import '../../../models/pedido.dart';
import '../controllers/trabalho_detalhe_controller.dart';

/// Detalhe de um trabalho (profissional), aberto a partir dos Pedidos. Não
/// existe no Figma: segue o Style Guide (ver SCREENS.md, "Ecrãs e ações
/// acrescentados depois do QA"). Morada e contacto só depois de o cliente
/// aceitar a proposta (RNF10).
class TrabalhoDetalheView extends StatelessWidget {
  const TrabalhoDetalheView({super.key, required this.pedidoId});

  final String pedidoId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (c) =>
          TrabalhoDetalheController(c.read<KisaluRepository>(), pedidoId)
            ..carregar(),
      child: const _Corpo(),
    );
  }
}

class _Corpo extends StatelessWidget {
  const _Corpo();

  void _voltar(BuildContext context) =>
      context.canPop() ? context.pop() : context.go(AppRoutes.pedidos);

  @override
  Widget build(BuildContext context) {
    final c = context.watch<TrabalhoDetalheController>();
    final margem = K.margemPara(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            KTopBar(titulo: 'O trabalho', onVoltar: () => _voltar(context)),
            Expanded(
              child: KEstadoBuilder<Pedido>(
                estado: c.estado,
                onTentar: c.carregar,
                rotuloNaoEncontrado: 'Ver os meus pedidos',
                onNaoEncontrado: () => context.go(AppRoutes.pedidos),
                vazio: (_) => const SizedBox.shrink(),
                sucesso: (context, pedido) => RefreshIndicator(
                  color: KColors.laranja,
                  onRefresh: c.recarregar,
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(margem, K.s8, margem, K.s24),
                    children: [
                      _Resumo(pedido: pedido),
                      const SizedBox(height: K.s16),
                      _Cliente(pedido: pedido),
                      const SizedBox(height: K.s16),
                      _Morada(pedido: pedido),
                      const SizedBox(height: K.s24),
                      const _Acoes(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Resumo extends StatelessWidget {
  const _Resumo({required this.pedido});

  final Pedido pedido;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final etapa = pedido.etapa;
    return KCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: K.s8,
            runSpacing: K.s8,
            children: [
              KStatusBadge.estado(pedido.estado),
              if (pedido.estado == EstadoPedido.emCurso && etapa != null)
                KStatusBadge.destaque(etapa.rotulo),
            ],
          ),
          const SizedBox(height: K.s8),
          Text(pedido.titulo, style: text.titleLarge),
          if (pedido.descricao.isNotEmpty) ...[
            const SizedBox(height: K.s8),
            Text(
              pedido.descricao,
              style: text.bodyMedium!.copyWith(color: KColors.neutro700),
            ),
          ],
          if (pedido.valor != null) ...[
            const SizedBox(height: K.s12),
            KLinhaChaveValor.preco(
              rotulo: 'Valor combinado',
              valor: pedido.valor!,
            ),
          ],
        ],
      ),
    );
  }
}

class _Cliente extends StatelessWidget {
  const _Cliente({required this.pedido});

  final Pedido pedido;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final nome = pedido.clienteNome ?? pedido.cliente ?? 'Cliente';
    final telemovel = pedido.clienteTelemovel;
    final conversa = pedido.conversaId;
    return KCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const KSecaoTitulo(titulo: 'Cliente'),
          const SizedBox(height: K.s8),
          Row(
            children: [
              KAvatar(nome: nome),
              const SizedBox(width: K.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nome, style: KTypography.nomeLista),
                    if (telemovel != null)
                      Text(
                        KFormat.telemovel(telemovel),
                        style: text.bodyMedium!.copyWith(
                          color: KColors.neutro700,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: K.s12),
          Wrap(
            spacing: K.s8,
            runSpacing: K.s8,
            children: [
              if (telemovel != null)
                KSecondaryButton(
                  rotulo: 'Ligar',
                  icone: KIcons.telefone,
                  larguraTotal: false,
                  compacto: true,
                  // Sem pacote de chamadas (RM03): fica para depois.
                  onPressed: () => mostrarKSnack(context, 'Em breve'),
                ),
              if (conversa != null)
                KSecondaryButton(
                  rotulo: 'Conversa',
                  icone: KIcons.conversa,
                  larguraTotal: false,
                  compacto: true,
                  onPressed: () => context.push(AppRoutes.conversa(conversa)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Morada extends StatelessWidget {
  const _Morada({required this.pedido});

  final Pedido pedido;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final morada = pedido.morada;
    final ponto = pedido.pontoReferencia;
    return KCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const KSecaoTitulo(titulo: 'Onde é'),
          const SizedBox(height: K.s8),
          KLinhaIcone(icone: KIcons.localizacao, texto: morada ?? pedido.zona),
          if (ponto != null) ...[
            const SizedBox(height: K.s8),
            Text(
              'Ponto de referência: $ponto',
              style: text.bodyMedium!.copyWith(color: KColors.neutro700),
            ),
          ],
          if (morada == null) ...[
            const SizedBox(height: K.s8),
            Text(
              'A morada exata aparece quando o cliente aceita a sua proposta.',
              style: text.bodyMedium!.copyWith(color: KColors.neutro700),
            ),
          ],
        ],
      ),
    );
  }
}

/// "Estou a caminho" / "Comecei o trabalho" com confirmação (RNF08).
class _Acoes extends StatelessWidget {
  const _Acoes();

  Future<void> _mudar(
    BuildContext context,
    EtapaServico etapa,
    String pergunta,
    String texto,
  ) async {
    final c = context.read<TrabalhoDetalheController>();
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (dialogo) => AlertDialog(
        title: Text(pergunta),
        content: Text(texto),
        actions: [
          KTextLink(
            rotulo: 'Agora não',
            onPressed: () => Navigator.of(dialogo).pop(false),
          ),
          KTextLink(
            rotulo: 'Sim, avisar',
            onPressed: () => Navigator.of(dialogo).pop(true),
          ),
        ],
      ),
    );
    if (confirmou != true || !context.mounted) return;
    final ok = await c.mudarEtapa(etapa);
    if (!context.mounted) return;
    mostrarKSnack(
      context,
      ok ? 'Feito. O cliente já foi avisado.' : c.erro ?? 'Tente outra vez.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<TrabalhoDetalheController>();
    final text = Theme.of(context).textTheme;
    if (!c.ativo) return const SizedBox.shrink();
    void comecar() => _mudar(
      context,
      EtapaServico.emCurso,
      'Começou o trabalho?',
      'Avisamos o cliente. No fim, peça-lhe o código de 6 dígitos.',
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (c.podeIrACaminho) ...[
          KPrimaryButton(
            rotulo: 'Estou a caminho',
            aCarregar: c.aMudar,
            onPressed: () => _mudar(
              context,
              EtapaServico.aCaminho,
              'Está a caminho?',
              'Avisamos o cliente de que já saiu.',
            ),
          ),
          const SizedBox(height: K.s8),
        ],
        if (c.podeComecar && c.podeIrACaminho)
          KSecondaryButton(rotulo: 'Comecei o trabalho', onPressed: comecar)
        else if (c.podeComecar)
          KPrimaryButton(
            rotulo: 'Comecei o trabalho',
            aCarregar: c.aMudar,
            onPressed: comecar,
          ),
        if (c.faltaConfirmar) ...[
          Text(
            'Quando acabar, peça ao cliente o código de 6 dígitos.',
            style: text.bodyLarge,
          ),
          const SizedBox(height: K.s12),
          KPrimaryButton(
            rotulo: 'Confirmar serviço',
            icone: KIcons.codigoQr,
            onPressed: () => context.go(AppRoutes.qr),
          ),
        ],
      ],
    );
  }
}
