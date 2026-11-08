/// Caminhos de navegação. Usar sempre estas constantes (nunca strings soltas).
abstract final class AppRoutes {
  static const login = '/login'; // 01
  static const inicio = '/inicio'; // 02 · separador Início
  static const pedidos = '/pedidos'; // 07 · separador Pedidos
  static const qr = '/qr'; // 05 / 09 · separador QR
  static const conversas = '/conversas'; // 18 · separador Conversas
  static const perfil = '/perfil'; // 20 · separador Perfil
  static const novoPedido = '/novo-pedido'; // 10 (retoma o rascunho)
  static const codigoSms = '/codigo-sms'; // 11
  static const registoProfissional = '/registo-profissional'; // 12
  static const verificarIdentidade = '/verificar-identidade'; // 13
  static const categorias = '/categorias'; // 21
  static const mapa = '/mapa'; // 22
  static const notificacoes = '/notificacoes'; // sino (02, 14) e Perfil
  static const ajuda = '/ajuda'; // Login e Perfil (RF16)

  /// Novo pedido a começar no passo 1. É o único valor aceite de `?novo=`.
  static const novoPedidoInicio = '/novo-pedido?novo=1';
  static const dev = '/dev'; // galeria de ecrãs (só desenvolvimento)
  static const devComponentes = '/dev/componentes'; // galeria de componentes K*

  // Padrões com `:id`, só para o router.
  static const padraoProfissional = '/profissional/:id';
  static const padraoAvaliar = '/pedidos/:id/avaliar';
  static const padraoEnviarProposta = '/enviar-proposta/:pedidoId';
  static const padraoServicoConfirmado = '/servico-confirmado/:pedidoId';
  static const padraoConversa = '/conversas/:id';
  static const padraoTrabalho = '/trabalhos/:id';

  static String profissional(String id) =>
      '/profissional/${Uri.encodeComponent(id)}'; // 03
  static String pedido(String id) =>
      '/pedidos/${Uri.encodeComponent(id)}'; // 04 (+ folha 08)
  static String avaliar(String id) =>
      '/pedidos/${Uri.encodeComponent(id)}/avaliar'; // 06

  static String enviarProposta(String pedidoId) =>
      '/enviar-proposta/${Uri.encodeComponent(pedidoId)}'; // 15
  static String servicoConfirmado(String pedidoId) =>
      '/servico-confirmado/${Uri.encodeComponent(pedidoId)}'; // 17
  static String conversa(String id) =>
      '/conversas/${Uri.encodeComponent(id)}'; // 19

  /// Detalhe do trabalho aceite (profissional, a partir dos Pedidos).
  static String trabalho(String id) => '/trabalhos/${Uri.encodeComponent(id)}';

  /// QR de um pedido concreto (a partir do detalhe 04).
  static String qrDoPedido(String id) =>
      '$qr?pedido=${Uri.encodeQueryComponent(id)}';

  /// 04 · "Editar pedido": formulário pré-preenchido, grava com PATCH.
  static String editarPedido(String id) =>
      '$novoPedido?editar=${Uri.encodeQueryComponent(id)}';

  /// 07 · "Pedir de novo": novo pedido a partir de um antigo.
  static String pedirDeNovo(String id) =>
      '$novoPedido?de=${Uri.encodeQueryComponent(id)}';

  static final _idValido = RegExp(r'^[A-Za-z0-9_-]{1,64}$');

  /// Formato aceite para `:id` até a API definir o seu (SEGURANCA.md).
  static bool idValido(String? id) => id != null && _idValido.hasMatch(id);
}
