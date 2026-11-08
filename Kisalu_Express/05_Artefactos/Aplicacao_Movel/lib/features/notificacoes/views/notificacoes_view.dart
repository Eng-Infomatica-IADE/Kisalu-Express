import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/k_colors.dart';
import '../../../core/theme/k_icons.dart';
import '../../../core/theme/k_tokens.dart';
import '../../../core/theme/k_typography.dart';
import '../../../core/utils/k_format.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/repositories/kisalu_repository.dart';
import '../../../models/notificacao.dart';
import '../controllers/notificacoes_controller.dart';

/// Lista de notificações (RF08). Não existe no Figma: segue o Style Guide
/// (ver SCREENS.md, "Ecrãs e ações acrescentados depois do QA").
class NotificacoesView extends StatelessWidget {
  const NotificacoesView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (c) =>
          NotificacoesController(c.read<KisaluRepository>())..carregar(),
      child: const _Corpo(),
    );
  }
}

class _Corpo extends StatelessWidget {
  const _Corpo();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<NotificacoesController>();
    final margem = K.margemPara(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const KTopBar(titulo: 'Notificações'),
            Expanded(
              child: KEstadoBuilder<List<Notificacao>>(
                estado: c.estado,
                onTentar: c.carregar,
                carregar: (_) => Padding(
                  padding: EdgeInsets.all(margem),
                  child: const KSkeletonLista(),
                ),
                vazio: (_) => Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: margem + K.s16),
                    child: const KEmptyState(
                      icone: KIcons.notificacoes,
                      titulo: 'Sem notificações',
                      mensagem:
                          'Quando receber propostas ou o profissional estiver '
                          'a caminho, avisamos aqui.',
                    ),
                  ),
                ),
                sucesso: (context, lista) => RefreshIndicator(
                  color: KColors.laranja,
                  onRefresh: c.recarregar,
                  child: ListView.separated(
                    padding: EdgeInsets.fromLTRB(margem, K.s8, margem, K.s24),
                    itemCount: lista.length,
                    separatorBuilder: (_, _) => const SizedBox(height: K.s12),
                    itemBuilder: (_, i) =>
                        _Linha(notificacao: lista[i], agora: c.agora),
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

class _Linha extends StatelessWidget {
  const _Linha({required this.notificacao, required this.agora});

  final Notificacao notificacao;
  final DateTime agora;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final nova = !notificacao.lida;
    return KCard(
      destacado: nova,
      rotuloSemantico:
          '${nova ? 'Nova. ' : ''}${notificacao.titulo}. ${notificacao.corpo}',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: K.iconeQuadrado,
            height: K.iconeQuadrado,
            decoration: BoxDecoration(
              color: KColors.tomClaro,
              borderRadius: BorderRadius.circular(K.raioBotao),
            ),
            child: const Icon(
              KIcons.notificacoes,
              size: K.icone24,
              color: KColors.brasa,
            ),
          ),
          const SizedBox(width: K.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: K.s8,
                  runSpacing: K.s4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(notificacao.titulo, style: KTypography.nomeLista),
                    if (nova) KStatusBadge.destaque('Nova', compacta: true),
                  ],
                ),
                const SizedBox(height: K.s4),
                Text(notificacao.corpo, style: text.bodyMedium),
                const SizedBox(height: K.s4),
                Text(
                  KFormat.dataCurta(notificacao.criadaEm, agora),
                  style: text.bodySmall!.copyWith(color: KColors.neutro500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
