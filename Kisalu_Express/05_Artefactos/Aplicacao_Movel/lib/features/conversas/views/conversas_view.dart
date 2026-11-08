import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/k_colors.dart';
import '../../../core/theme/k_icons.dart';
import '../../../core/theme/k_tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/repositories/kisalu_repository.dart';
import '../controllers/conversas_controller.dart';
import '../widgets/conversa_linha.dart';

/// Ecrã 18 · Conversas (separador) — ver docs/design/SCREENS.md#ecra-18.
/// Sem conversas mostra o estado vazio, no estilo do ecrã 09.
class ConversasView extends StatelessWidget {
  const ConversasView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (c) =>
          ConversasController(c.read<KisaluRepository>())..carregar(),
      child: const _Conteudo(),
    );
  }
}

class _Conteudo extends StatelessWidget {
  const _Conteudo();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ConversasController>();
    final margem = K.margemPara(context);
    return KAoVoltar(
      aoVoltar: c.recarregar,
      child: _estado(context, c, margem),
    );
  }

  Widget _estado(BuildContext context, ConversasController c, double margem) {
    return KEstadoBuilder<ConversasDados>(
      estado: c.estado,
      onTentar: c.carregar,
      carregar: (_) => SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.all(margem),
          child: const KSkeletonLista(),
        ),
      ),
      vazio: (_) => KEstadoVazioCentrado(
        filho: KEmptyState(
          icone: KIcons.conversa,
          titulo: 'Ainda não tem conversas',
          mensagem:
              'Quando aceitar uma proposta, pode falar com o profissional '
              'aqui.',
          rotuloAcao: 'Ver os meus pedidos',
          onAcao: () => context.go(AppRoutes.pedidos),
        ),
      ),
      sucesso: (context, dados) => SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(margem, K.s8 + 2, margem, K.s16),
              child: Semantics(
                header: true,
                child: Text(
                  'Conversas',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: KColors.laranja,
                onRefresh: c.recarregar,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(margem, 0, margem, K.s24),
                  children: [
                    KCard(
                      padding: const EdgeInsets.symmetric(vertical: K.s4),
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        itemCount: dados.conversas.length,
                        itemBuilder: (context, i) {
                          final conversa = dados.conversas[i];
                          return ConversaLinha(
                            conversa: conversa,
                            agora: dados.agora,
                            onTap: () =>
                                context.push(AppRoutes.conversa(conversa.id)),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
