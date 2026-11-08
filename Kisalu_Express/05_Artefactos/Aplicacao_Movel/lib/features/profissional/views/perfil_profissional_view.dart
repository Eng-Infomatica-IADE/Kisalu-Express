import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/k_colors.dart';
import '../../../core/theme/k_tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/repositories/kisalu_repository.dart';
import '../../../models/profissional.dart';
import '../controllers/perfil_profissional_controller.dart';
import '../widgets/barra_pedir_servico.dart';
import '../widgets/cabecalho_perfil.dart';
import '../widgets/trabalhos_feitos.dart';

/// Ecrã 03 · Perfil do profissional — ver docs/design/SCREENS.md#ecra-03.
/// Não mostra contacto nem morada: só depois de aceitar (RNF10).
class PerfilProfissionalView extends StatelessWidget {
  const PerfilProfissionalView({super.key, required this.profissionalId});

  final String profissionalId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (c) => PerfilProfissionalController(
        c.read<KisaluRepository>(),
        profissionalId,
      )..carregar(),
      child: const _PerfilCorpo(),
    );
  }
}

class _PerfilCorpo extends StatelessWidget {
  const _PerfilCorpo();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<PerfilProfissionalController>();
    final margem = K.margemPara(context);
    // Fora do estado de sucesso, mostra só o voltar e o estado.
    Widget simples(Widget filho) => SafeArea(
      child: Padding(
        padding: EdgeInsets.all(margem),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const KBackButton(),
            Expanded(child: Center(child: filho)),
          ],
        ),
      ),
    );

    return Scaffold(
      backgroundColor: KColors.areia50,
      body: KEstadoBuilder<Profissional>(
        estado: c.estado,
        onTentar: c.carregar,
        rotuloNaoEncontrado: 'Voltar ao Início',
        onNaoEncontrado: () => context.go(AppRoutes.inicio),
        carregar: (_) => simples(const KSkeletonLista()),
        vazio: (_) => simples(const SizedBox()),
        sucesso: (context, p) => _Conteudo(profissional: p),
      ),
    );
  }
}

class _Conteudo extends StatelessWidget {
  const _Conteudo({required this.profissional});

  final Profissional profissional;

  @override
  Widget build(BuildContext context) {
    final p = profissional;
    final text = Theme.of(context).textTheme;
    final margem = K.margemPara(context);
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CabecalhoPerfil(profissional: p),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    margem,
                    K.s16 + 1,
                    margem,
                    K.s24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (p.especialidades.isNotEmpty) ...[
                        const KSecaoTitulo(titulo: 'Especialidades'),
                        const SizedBox(height: K.s12 + K.s4 - 1),
                        Wrap(
                          spacing: K.s8,
                          children: [
                            for (final e in p.especialidades)
                              KChip(
                                rotulo: e,
                                variante: KChipVariante.informativo,
                              ),
                          ],
                        ),
                        const SizedBox(height: K.s4 / 2),
                      ],
                      if (p.trabalhosFeitos.isNotEmpty) ...[
                        KSecaoTitulo(
                          titulo: 'Trabalhos feitos',
                          rotuloAcao: 'Ver todos (${p.totalTrabalhosFeitos})',
                          onAcao: () => mostrarKSnack(context, 'Em breve'),
                        ),
                        TrabalhosFeitos(trabalhos: p.trabalhosFeitos),
                        const SizedBox(height: K.s8),
                        Text(
                          'Fotos de serviços confirmados por QR na Kisalu',
                          style: text.bodySmall!.copyWith(
                            color: KColors.neutro500,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: K.s16 + K.s4),
                      ],
                      if (p.avaliacoes.isNotEmpty) ...[
                        const KSecaoTitulo(titulo: 'Avaliações recentes'),
                        const SizedBox(height: K.s12),
                        for (final a in p.avaliacoes) ...[
                          _CartaoAvaliacao(
                            autor: a.autor,
                            estrelas: a.estrelas,
                            comentario: a.comentario,
                          ),
                          const SizedBox(height: K.s12),
                        ],
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        BarraPedirServico(
          maoDeObraDesde: p.maoDeObraDesde,
          onPedir: () => context.push(AppRoutes.novoPedidoInicio),
        ),
      ],
    );
  }
}

class _CartaoAvaliacao extends StatelessWidget {
  const _CartaoAvaliacao({
    required this.autor,
    required this.estrelas,
    required this.comentario,
  });

  final String autor;
  final int estrelas;
  final String comentario;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return KCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              KAvatar(nome: autor, tamanho: K.avatarPequeno),
              const SizedBox(width: K.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      autor,
                      style: text.bodyMedium!.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    KEstrelas(valor: estrelas),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: K.s8),
          Text(comentario, style: text.bodyMedium),
        ],
      ),
    );
  }
}
