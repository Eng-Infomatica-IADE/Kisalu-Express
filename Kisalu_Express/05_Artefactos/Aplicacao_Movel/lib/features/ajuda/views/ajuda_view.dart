import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/k_colors.dart';
import '../../../core/theme/k_icons.dart';
import '../../../core/theme/k_tokens.dart';
import '../../../core/theme/k_typography.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/repositories/kisalu_repository.dart';
import '../../../models/pergunta_ajuda.dart';
import '../controllers/ajuda_controller.dart';

/// Ajuda · perguntas frequentes (RF16), a partir do Login e do Perfil. Não
/// existe no Figma: segue o Style Guide (SCREENS.md, "Ecrãs e ações
/// acrescentados depois do QA").
class AjudaView extends StatelessWidget {
  const AjudaView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (c) => AjudaController(c.read<KisaluRepository>())..carregar(),
      child: const _Corpo(),
    );
  }
}

class _Corpo extends StatelessWidget {
  const _Corpo();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<AjudaController>();
    final margem = K.margemPara(context);
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const KTopBar(titulo: 'Ajuda'),
            Expanded(
              child: KEstadoBuilder<List<PerguntaAjuda>>(
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
                      icone: KIcons.ajuda,
                      titulo: 'Ainda não há perguntas',
                      mensagem: 'Volte mais tarde.',
                    ),
                  ),
                ),
                sucesso: (context, perguntas) => ListView(
                  padding: EdgeInsets.fromLTRB(margem, K.s8, margem, K.s24),
                  children: [
                    Text(
                      'Perguntas frequentes',
                      style: text.titleMedium!.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: K.s12),
                    KCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          for (final (i, p) in perguntas.indexed) ...[
                            if (i > 0)
                              const Divider(height: 1, color: KColors.areia200),
                            _Pergunta(pergunta: p),
                          ],
                        ],
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

class _Pergunta extends StatelessWidget {
  const _Pergunta({required this.pergunta});

  final PerguntaAjuda pergunta;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Theme(
      // Sem as linhas que o ExpansionTile desenha por omissão.
      data: Theme.of(context).copyWith(dividerColor: KColors.branco),
      child: ExpansionTile(
        minTileHeight: K.alvoMinimo,
        tilePadding: const EdgeInsets.symmetric(horizontal: K.s16),
        childrenPadding: const EdgeInsets.fromLTRB(K.s16, 0, K.s16, K.s16),
        iconColor: KColors.brasa,
        collapsedIconColor: KColors.neutro700,
        expandedAlignment: Alignment.centerLeft,
        title: Text(pergunta.pergunta, style: KTypography.nomeLista),
        children: [
          Text(
            pergunta.resposta,
            style: text.bodyLarge!.copyWith(color: KColors.neutro700),
          ),
        ],
      ),
    );
  }
}
