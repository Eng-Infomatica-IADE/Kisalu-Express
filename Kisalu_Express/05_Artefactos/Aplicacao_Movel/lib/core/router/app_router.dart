import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/ajuda/views/ajuda_view.dart';
import '../../features/autenticacao/views/codigo_sms_view.dart';
import '../../features/autenticacao/views/login_view.dart';
import '../../features/avaliacao/views/avaliar_servico_view.dart';
import '../../features/categorias/views/todos_servicos_view.dart';
import '../../features/confirmacao_profissional/views/ler_qr_view.dart';
import '../../features/confirmacao_profissional/views/servico_confirmado_view.dart';
import '../../features/conversas/views/conversa_view.dart';
import '../../features/conversas/views/conversas_view.dart';
import '../../features/dev/views/dev_components_view.dart';
import '../../features/dev/views/dev_gallery_view.dart';
import '../../features/inicio/views/inicio_view.dart';
import '../../features/inicio_profissional/views/inicio_profissional_view.dart';
import '../../features/mapa/views/mapa_view.dart';
import '../../features/notificacoes/views/notificacoes_view.dart';
import '../../features/novo_pedido/controllers/novo_pedido_controller.dart';
import '../../features/novo_pedido/views/novo_pedido_view.dart';
import '../../features/pedidos/views/historico_pedidos_view.dart';
import '../../features/pedidos/views/pedido_detalhe_view.dart';
import '../../features/perfil/views/perfil_view.dart';
import '../../features/profissional/views/perfil_profissional_view.dart';
import '../../features/proposta/views/enviar_proposta_view.dart';
import '../../features/confirmacao_qr/views/confirmar_servico_view.dart';
import '../../features/registo_profissional/views/registo_profissional_view.dart';
import '../../features/registo_profissional/views/verificar_identidade_view.dart';
import '../../features/trabalho/views/trabalho_detalhe_view.dart';
import '../widgets/app_shell.dart';
import 'app_routes.dart';
import 'por_perfil.dart';
import 'rota_nao_encontrada_view.dart';

final _rootKey = GlobalKey<NavigatorState>();

/// `?vazio=1` mostra o ecrã 09 na galeria. Só em debug: um parâmetro de URL
/// nunca altera o estado em produção (SEGURANCA.md, T22). É o único sítio
/// que o lê.
bool _vazioForcado(GoRouterState state) =>
    kDebugMode && state.uri.queryParameters['vazio'] == '1';

/// Constrói a view só se o `:id` tiver formato válido; senão mostra "não
/// encontrado". Um id válido mas desconhecido é tratado pela própria view.
Widget _comId(
  GoRouterState state,
  Widget Function(String id) construir, {
  String parametro = 'id',
}) {
  final id = state.pathParameters[parametro];
  return AppRoutes.idValido(id)
      ? construir(id!)
      : const RotaNaoEncontradaView();
}

/// Mapa de navegação (Relatório Fase 1, 5.2):
/// - separadores (com barra inferior): Início, Pedidos (+ detalhe 04), QR,
///   Conversas, Perfil. Início e QR têm versão de profissional (14 e 16),
///   escolhida pelo perfil ativo da sessão (`PorPerfil`);
/// - ecrãs de fluxo em ecrã inteiro (sem barra): Login, Código SMS,
///   Registo e Verificação do profissional, Perfil do profissional, Avaliar,
///   Novo pedido, Enviar proposta, Serviço confirmado, Conversa, Todos os
///   serviços e Mapa.
///
/// A galeria `/dev` e o atalho `?vazio=1` só existem em modo debug.
/// A app arranca sempre no Login; a galeria abre-se à mão pelo URL `/dev`.
GoRouter createRouter({String? initialLocation}) => GoRouter(
  navigatorKey: _rootKey,
  initialLocation: initialLocation ?? AppRoutes.login,
  errorBuilder: (_, _) => const RotaNaoEncontradaView(),
  routes: [
    if (kDebugMode)
      GoRoute(
        path: AppRoutes.dev,
        builder: (_, _) => const DevGalleryView(),
        routes: [
          GoRoute(
            path: 'componentes',
            builder: (_, _) => const DevComponentsView(),
          ),
        ],
      ),
    GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginView()),
    GoRoute(
      path: AppRoutes.codigoSms,
      builder: (_, _) => const CodigoSmsView(),
    ),
    GoRoute(
      path: AppRoutes.registoProfissional,
      builder: (_, _) => const RegistoProfissionalView(),
    ),
    GoRoute(
      path: AppRoutes.verificarIdentidade,
      builder: (_, _) => const VerificarIdentidadeView(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (_, state, shell) => AppShell(
        navigationShell: shell,
        qrVazioForcado: _vazioForcado(state),
      ),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.inicio,
              builder: (_, _) => PorPerfil(
                cliente: (_) => const InicioView(),
                profissional: (_) => const InicioProfissionalView(),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.pedidos,
              builder: (_, _) => const HistoricoPedidosView(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (_, state) =>
                      _comId(state, (id) => PedidoDetalheView(pedidoId: id)),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.qr,
              builder: (_, state) => PorPerfil(
                cliente: (_) => ConfirmarServicoView(
                  forcarVazio: _vazioForcado(state),
                  // `?pedido=:id` vem do detalhe 04; sem ele, o mais recente.
                  pedidoId:
                      AppRoutes.idValido(state.uri.queryParameters['pedido'])
                      ? state.uri.queryParameters['pedido']
                      : null,
                ),
                profissional: (_) => const LerQrView(),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.conversas,
              builder: (_, _) => const ConversasView(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.perfil,
              builder: (_, _) => const PerfilView(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.padraoProfissional,
      parentNavigatorKey: _rootKey,
      builder: (_, state) =>
          _comId(state, (id) => PerfilProfissionalView(profissionalId: id)),
    ),
    GoRoute(
      path: AppRoutes.padraoAvaliar,
      parentNavigatorKey: _rootKey,
      builder: (_, state) =>
          _comId(state, (id) => AvaliarServicoView(pedidoId: id)),
    ),
    GoRoute(
      path: AppRoutes.padraoEnviarProposta,
      parentNavigatorKey: _rootKey,
      builder: (_, state) => _comId(
        state,
        (id) => EnviarPropostaView(pedidoId: id),
        parametro: 'pedidoId',
      ),
    ),
    GoRoute(
      path: AppRoutes.padraoServicoConfirmado,
      parentNavigatorKey: _rootKey,
      builder: (_, state) => _comId(
        state,
        (id) => ServicoConfirmadoView(pedidoId: id),
        parametro: 'pedidoId',
      ),
    ),
    GoRoute(
      path: AppRoutes.padraoConversa,
      parentNavigatorKey: _rootKey,
      builder: (_, state) =>
          _comId(state, (id) => ConversaView(conversaId: id)),
    ),
    GoRoute(
      path: AppRoutes.padraoTrabalho,
      parentNavigatorKey: _rootKey,
      builder: (_, state) =>
          _comId(state, (id) => TrabalhoDetalheView(pedidoId: id)),
    ),
    GoRoute(
      path: AppRoutes.notificacoes,
      parentNavigatorKey: _rootKey,
      builder: (_, _) => const NotificacoesView(),
    ),
    GoRoute(
      path: AppRoutes.ajuda,
      parentNavigatorKey: _rootKey,
      builder: (_, _) => const AjudaView(),
    ),
    GoRoute(
      path: AppRoutes.categorias,
      parentNavigatorKey: _rootKey,
      builder: (_, _) => const TodosServicosView(),
    ),
    GoRoute(
      path: AppRoutes.mapa,
      parentNavigatorKey: _rootKey,
      builder: (_, _) => const MapaView(),
    ),
    GoRoute(
      path: AppRoutes.novoPedido,
      parentNavigatorKey: _rootKey,
      builder: (_, state) {
        final q = state.uri.queryParameters;
        // Ids com formato inválido são ignorados (SEGURANCA.md).
        String? id(String chave) =>
            AppRoutes.idValido(q[chave]) ? q[chave] : null;
        return NovoPedidoView(
          // Só `?novo=1` inicia no passo 1; qualquer outro valor é ignorado.
          passoInicial: q['novo'] == '1' ? PassoNovoPedido.descricao : null,
          editarId: id('editar'),
          deId: id('de'),
        );
      },
    ),
  ],
);
