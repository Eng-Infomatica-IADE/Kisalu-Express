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
import '../controllers/inicio_controller.dart';
import '../widgets/banner_qr.dart';

/// Ecrã 02 · Início — ver docs/design/SCREENS.md#ecra-02.
/// Vive dentro do `AppShell` (que dá o Scaffold e a barra inferior).
class InicioView extends StatelessWidget {
  const InicioView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (c) => InicioController(
        c.read<KisaluRepository>(),
        saudacaoPara: KFormat.saudacao,
      )..carregar(),
      child: const _InicioCorpo(),
    );
  }
}

class _InicioCorpo extends StatelessWidget {
  const _InicioCorpo();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<InicioController>();
    final margem = K.margemPara(context);
    return SafeArea(
      bottom: false,
      child: KEstadoBuilder<InicioDados>(
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
              'Ainda não há profissionais perto de si. '
              'Tente alargar a zona de pesquisa.',
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

  final InicioDados dados;
  final double margem;

  @override
  Widget build(BuildContext context) {
    final c = context.watch<InicioController>();
    final text = Theme.of(context).textTheme;
    void novoPedido() => context.push(AppRoutes.novoPedidoInicio);

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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        '${dados.saudacao}, ${dados.utilizador.nome}',
                        style: KTypography.titulo24,
                      ),
                    ),
                    const SizedBox(height: K.s4),
                    Text.rich(
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
                          TextSpan(text: dados.utilizador.zona),
                        ],
                      ),
                      style: KTypography.corpo13,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: K.s8),
              Transform.translate(
                // O alvo de 48 dp tem 2 dp de folga: alinha o quadrado à margem.
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
          const SizedBox(height: K.s16 + K.s4 / 2),
          KSearchField(soLeitura: true, onTap: novoPedido),
          if (c.bannerVisivel) ...[
            const SizedBox(height: K.s16 + K.s4 / 2),
            BannerQr(onFechar: c.fecharBanner),
          ],
          const SizedBox(height: K.s8 - 1),
          KSecaoTitulo(
            titulo: 'Serviços',
            rotuloAcao: 'Ver todos',
            onAcao: () => context.push(AppRoutes.categorias),
          ),
          const SizedBox(height: K.s4 + 1),
          KGrelhaCategorias(
            categorias: dados.categorias,
            selecionada: c.categoriaSelecionada,
            onSelecionar: (_) => novoPedido(),
          ),
          const SizedBox(height: K.s8),
          KSecaoTitulo(
            titulo: 'Perto de si',
            acessorio: KChipAcao(
              rotulo: 'Mapa',
              icone: KIcons.localizacao,
              onTap: () => context.push(AppRoutes.mapa),
            ),
          ),
          const SizedBox(height: K.s8 + 1),
          if (dados.profissionais.isEmpty)
            Text(
              'Ainda não há profissionais perto de si. '
              'Tente alargar a zona de pesquisa.',
              style: text.bodyMedium!.copyWith(color: KColors.neutro700),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: K.s16 + K.s4),
              itemCount: dados.profissionais.length,
              separatorBuilder: (_, _) => const SizedBox(height: K.s16 + K.s4),
              itemBuilder: (_, i) {
                final p = dados.profissionais[i];
                return KCartaoProfissional(
                  profissional: p,
                  onAbrir: () => context.push(AppRoutes.profissional(p.id)),
                );
              },
            ),
        ],
      ),
    );
  }
}
