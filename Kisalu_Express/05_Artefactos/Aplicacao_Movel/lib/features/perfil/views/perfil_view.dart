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
import '../../../models/utilizador.dart';
import '../controllers/perfil_controller.dart';
import '../widgets/cartao_mudar_perfil.dart';
import '../widgets/linha_menu_perfil.dart';

/// Ecrã 20 · Perfil (separador) — ver docs/design/SCREENS.md#ecra-20.
/// Os dados aparecem mascarados e as linhas do menu ainda não têm destino.
class PerfilView extends StatelessWidget {
  const PerfilView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (c) => PerfilController(c.read<KisaluRepository>())..carregar(),
      child: const _Conteudo(),
    );
  }
}

class _Conteudo extends StatelessWidget {
  const _Conteudo();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<PerfilController>();
    final margem = K.margemPara(context);
    return SafeArea(
      bottom: false,
      child: KEstadoBuilder<PerfilDados>(
        estado: c.estado,
        onTentar: c.carregar,
        carregar: (_) => Padding(
          padding: EdgeInsets.all(margem),
          child: const KSkeletonLista(),
        ),
        vazio: (_) => const SizedBox(),
        sucesso: (context, dados) => _Perfil(dados: dados, margem: margem),
      ),
    );
  }
}

class _Perfil extends StatelessWidget {
  const _Perfil({required this.dados, required this.margem});

  final PerfilDados dados;
  final double margem;

  void _emBreve(BuildContext context) => mostrarKSnack(context, 'Em breve');

  Future<void> _mudar(BuildContext context) async {
    final destino = await context.read<PerfilController>().mudarPerfil();
    if (!context.mounted) return;
    switch (destino) {
      case DestinoMudarPerfil.inicio:
        context.go(AppRoutes.inicio);
      case DestinoMudarPerfil.registo:
        // Sem registo completo o painel 14 ficava vazio (QA-14).
        context.push(AppRoutes.registoProfissional);
      case DestinoMudarPerfil.nenhum:
        break;
    }
  }

  /// Pede confirmação numa folha (ecrã 20b) antes de terminar a sessão.
  Future<void> _terminar(BuildContext context) async {
    final confirmou = await mostrarKFolha<bool>(
      context,
      builder: (folha) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text('Terminar sessão?', style: KTypography.titulo22),
          ),
          const SizedBox(height: K.s8),
          Text(
            'Para voltar a entrar, recebe um novo código por SMS.',
            style: Theme.of(folha).textTheme.bodyLarge!
                .copyWith(color: KColors.neutro700),
          ),
          const SizedBox(height: K.s24),
          KPrimaryButton(
            rotulo: 'Terminar sessão',
            destrutivo: true,
            onPressed: () => Navigator.of(folha).pop(true),
          ),
          const SizedBox(height: K.s4),
          Center(
            child: KTextLink(
              rotulo: 'Cancelar',
              grande: true,
              onPressed: () => Navigator.of(folha).pop(false),
            ),
          ),
        ],
      ),
    );
    if (confirmou != true || !context.mounted) return;
    final terminou = await context.read<PerfilController>().terminarSessao();
    if (terminou && context.mounted) context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<PerfilController>();
    final u = dados.utilizador;
    final emModoProfissional =
        dados.perfilAtivo == PerfilUtilizador.profissional;
    void emBreve() => _emBreve(context);
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(margem, K.s8 + 2, margem, K.s24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              'Perfil',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          const SizedBox(height: K.s16),
          KCard(
            child: Row(
              children: [
                KAvatar(nome: u.nomeCompleto, tamanho: K.avatarPerfil),
                const SizedBox(width: K.s16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        u.nomeCompleto,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        KFormat.telemovelMascarado(u.telemovel),
                        style: Theme.of(context).textTheme.bodyMedium!
                            .copyWith(color: KColors.neutro700),
                      ),
                      Text(
                        u.zona,
                        style: KTypography.corpo13.copyWith(
                          color: KColors.neutro500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: K.s16),
          KCard(
            padding: const EdgeInsets.symmetric(vertical: K.s4),
            child: Column(
              children: [
                LinhaMenuPerfil(
                  icone: KIcons.perfil,
                  titulo: 'Os meus dados',
                  onTap: emBreve,
                ),
                LinhaMenuPerfil(
                  icone: KIcons.localizacao,
                  titulo: 'Moradas guardadas',
                  descricao: KFormat.moradas(u.moradasGuardadas),
                  onTap: emBreve,
                ),
                LinhaMenuPerfil(
                  icone: KIcons.favorito,
                  titulo: 'Profissionais favoritos',
                  descricao: '${u.favoritos} guardados',
                  onTap: emBreve,
                ),
                LinhaMenuPerfil(
                  icone: KIcons.notificacoes,
                  titulo: 'Notificações',
                  onTap: () => context.push(AppRoutes.notificacoes),
                ),
                LinhaMenuPerfil(
                  icone: KIcons.ajuda,
                  titulo: 'Ajuda e apoio',
                  onTap: () => context.push(AppRoutes.ajuda),
                ),
                LinhaMenuPerfil(
                  icone: KIcons.cadeado,
                  titulo: 'Privacidade e dados',
                  onTap: emBreve,
                ),
              ],
            ),
          ),
          const SizedBox(height: K.s16),
          CartaoMudarPerfil(
            pergunta: emModoProfissional
                ? 'Quer pedir serviços?'
                : 'Também presta serviços?',
            acao: emModoProfissional
                ? 'Mudar para cliente'
                : 'Mudar para profissional',
            aCarregar: c.aMudar,
            onTap: () => _mudar(context),
          ),
          if (c.erro != null) ...[
            const SizedBox(height: K.s12),
            KInlineAlert(
              tipo: KAlertaTipo.erro,
              titulo: 'Não foi possível concluir.',
              mensagem: c.erro!,
            ),
          ],
          const SizedBox(height: K.s4),
          Center(
            child: KTextLink(
              rotulo: 'Terminar sessão',
              grande: true,
              icone: KIcons.sair,
              destrutivo: true,
              onPressed: c.aTerminar ? null : () => _terminar(context),
            ),
          ),
        ],
      ),
    );
  }
}
