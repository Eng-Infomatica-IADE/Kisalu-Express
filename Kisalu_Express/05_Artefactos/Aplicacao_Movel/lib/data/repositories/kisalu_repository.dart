import 'package:flutter/foundation.dart';

import '../../models/avaliacao.dart';
import '../../models/categoria.dart';
import '../../models/codigo_confirmacao.dart';
import '../../models/comprovativo.dart';
import '../../models/conversa.dart';
import '../../models/estado_pedido.dart';
import '../../models/mensagem.dart';
import '../../models/notificacao.dart';
import '../../models/novo_pedido.dart';
import '../../models/nova_proposta.dart';
import '../../models/painel_profissional.dart';
import '../../models/pedido.dart';
import '../../models/pedido_codigo_sms.dart';
import '../../models/pedido_perto.dart';
import '../../models/pergunta_ajuda.dart';
import '../../models/pin_mapa.dart';
import '../../models/profissional.dart';
import '../../models/registo_profissional.dart';
import '../../models/resultado_reporte.dart';
import '../../models/servico_confirmado.dart';
import '../../models/trabalho_por_confirmar.dart';
import '../../models/utilizador.dart';
import '../../models/verificacao_identidade.dart';
import 'kisalu_exception.dart';

export 'kisalu_exception.dart';

/// Contrato de acesso a dados (camada Model do MVC).
///
/// Duas implementações: `MockKisaluRepository` (dados fictícios em memória)
/// e `RestKisaluRepository` (kisalu-api, ver docs/CONTRATO-API.md).
///
/// Regras:
/// - Devolve modelos, nunca JSON nem tipos HTTP.
/// - `null` (ou lista vazia) significa "não existe"; falha significa
///   [KisaluException]. As duas coisas não se confundem.
/// - O valor em Kz vem sempre do servidor (proposta aceite): nenhum método
///   aceita um valor como confirmação.
abstract interface class KisaluRepository {
  /// Avisa quando um pedido muda de estado (aceitar, desfazer, cancelar,
  /// confirmar): quem mostra o serviço em curso volta a ler.
  Listenable get alteracoes;

  /// Relógio do repositório. As views formatam datas relativas contra isto
  /// (`KFormat.dataCurta(d, agora)`), nunca contra `DateTime.now()`.
  DateTime agora();

  /// true nos dados fictícios: atalhos de demonstração (tocar no QR abre o
  /// ecrã 06) só existem aqui.
  bool get modoDemonstracao;

  // ------------------------------------------------------------------ sessão

  /// Perfil com que a sessão está a usar a app. Decide o Início, o QR e os
  /// Pedidos (ecrãs 14 e 16 no modo profissional). Muda com [mudarPerfil] e
  /// avisa por [alteracoes].
  PerfilUtilizador get perfilAtivo;

  /// 20 · "Mudar para profissional" / "Mudar para cliente", e depois de
  /// confirmar o código SMS.
  Future<void> mudarPerfil(PerfilUtilizador perfil);

  /// Utilizador com sessão (02: "Boa tarde, Maria", "Talatona, Luanda", sino;
  /// 20: perfil). Segue o [perfilAtivo].
  Future<Utilizador> utilizador();

  /// Valor com que se pré-preenche o campo do ecrã 01; null = vazio.
  Future<String?> telemovelPredefinido();

  /// 01 · "Receber código SMS" / "Criar conta" (a resposta não revela se o
  /// número já tem conta). Também o "Reenviar código" do 11. Guarda o pedido
  /// em memória para o ecrã 11 ([codigoSmsPendente]).
  Future<void> pedirCodigoSms(
    String telemovel,
    PerfilUtilizador perfil, {
    bool criarConta = false,
  });

  /// 11 · O pedido de código em curso. Sem pedido, devolve o de demonstração.
  Future<PedidoCodigoSms> codigoSmsPendente();

  /// Valor com que o ecrã 11 arranca; null = vazio.
  Future<String?> codigoSmsPredefinido();

  /// 11 · "Confirmar". Lança [ValidacaoException] se errado. Devolve true
  /// quando a pessoa entrou como profissional e ainda tem de fazer o registo
  /// (conta nova, "Criar conta" ou registo incompleto).
  Future<bool> validarCodigoSms(String telemovel, String codigo);

  /// Perfil · "Terminar sessão". Apaga o token guardado no aparelho.
  Future<void> terminarSessao();

  /// Arranque: se há token guardado e a API o aceita (`GET /eu`), a sessão
  /// continua e devolve true (a app abre no Início do perfil ativo).
  Future<bool> retomarSessao();

  // ------------------------------------------------------------ 02 · Início

  /// Todas as categorias (13). A grelha do Início usa as `emDestaque`.
  Future<List<Categoria>> categorias();

  /// Ordenados por distância.
  Future<List<Profissional>> profissionaisPertoDeSi();

  // ----------------------------------------------------- 03 · Profissional

  /// null → "não encontrado".
  Future<Profissional?> profissional(String id);

  // ------------------------------------------------- 04 · Pedido e propostas

  /// Detalhe com propostas; null → "não encontrado".
  Future<Pedido?> pedido(String id);

  /// 04 · "Cancelar pedido". Lança [ValidacaoException] se já não for possível.
  Future<void> cancelarPedido(String id);

  /// 08 · "Confirmar proposta". Lança [ValidacaoException] se a proposta já
  /// não estiver disponível. Devolve o pedido já em curso.
  Future<Pedido> aceitarProposta(String pedidoId, String propostaId);

  /// 08 · "Desfazer" no SnackBar. Lança [ValidacaoException] se for tarde.
  Future<void> desfazerAceitacao(String pedidoId);

  /// 04 · "Recusar" uma proposta (RF05). Não há desfazer na API.
  Future<void> recusarProposta(String pedidoId, String propostaId);

  /// 04 · "Editar pedido": grava as alterações (PATCH) enquanto não há
  /// proposta aceite. A zona fica a mesma. Devolve o pedido atualizado.
  Future<Pedido> editarPedido(String pedidoId, NovoPedido alteracoes);

  /// 07 · "Pedir de novo": novo pedido pré-preenchido a partir de um antigo.
  Future<NovoPedido> pedirDeNovo(String pedidoId);

  // ----------------------------------------------------- 05 / 09 · QR Code

  /// Serviço à espera de confirmação por QR; null → ecrã 09.
  Future<Pedido?> servicoEmCurso();

  /// Token do QR + código numérico, só em memória. Lança
  /// [NaoEncontradoException] se o pedido não está em curso.
  Future<CodigoConfirmacao> codigoConfirmacao(String pedidoId);

  /// 05 e 07 · "Reportar problema" (prazo de 7 dias, RF11). Lança
  /// [ValidacaoException] com a mensagem da API se a garantia acabou (422).
  Future<ResultadoReporte> reportarProblema(String pedidoId, String descricao);

  // ---------------------------------------------------------- 06 · Avaliar

  /// Comprovativo do serviço confirmado (06 e 07); null se não existe.
  Future<Comprovativo?> comprovativo(String pedidoId);

  /// Avaliação guardada como rascunho; null → ecrã sem seleção.
  Future<NovaAvaliacao?> rascunhoAvaliacao(String pedidoId);

  /// 06 · "Enviar avaliação". Lança [ValidacaoException] se já foi avaliado.
  Future<void> enviarAvaliacao(String pedidoId, NovaAvaliacao avaliacao);

  // ------------------------------------------------------------ 07 · Histórico

  /// Mais recentes primeiro. Os filtros aplicam-se na view (`FiltroPedidos`).
  Future<List<Pedido>> historico();

  // ------------------------------------------------------- 10 · Novo pedido

  /// Rascunho guardado (passo "Rever o pedido"); null → sem rascunho.
  Future<NovoPedido?> rascunhoPedido();

  /// Guarda o rascunho no aparelho (RM07: sem rede não se perde nada).
  Future<void> guardarRascunhoPedido(NovoPedido rascunho);

  /// Depois de publicar, o rascunho deixa de existir.
  Future<void> apagarRascunhoPedido();

  /// Verifica a ligação. Lança [SemRedeException] se não houver.
  Future<void> verificarLigacao();

  /// 10 · "Publicar pedido". Lança [SemRedeException] sem ligação.
  Future<PedidoPublicado> publicarPedido(NovoPedido novoPedido);

  // --------------------------------------------- 12 · 13 · Registo profissional

  /// Passo 1 pré-preenchido; null → formulário vazio.
  Future<RegistoProfissional?> rascunhoRegistoProfissional();

  /// 12 · "Continuar". Guarda o registo e passa a sessão a profissional.
  Future<void> guardarRegistoProfissional(RegistoProfissional registo);

  /// 13 · Estado dos documentos.
  Future<VerificacaoIdentidade> verificacaoIdentidade();

  /// 13 · "Alterar" no documento de identidade (simulado: não há câmara).
  Future<void> adicionarDocumento();

  /// 13 · Simula a fotografia do rosto.
  Future<void> adicionarFotoRosto();

  /// 13 · "Enviar para verificação". Lança [ValidacaoException] se falta
  /// algum documento.
  Future<void> enviarParaVerificacao();

  // ------------------------------------------------ 14 · Início profissional

  Future<PainelProfissional> painelProfissional();

  /// 14 · Interruptor "Disponível para trabalhar".
  Future<void> definirDisponibilidade(bool disponivel);

  // ------------------------------------------------------ 15 · Enviar proposta

  /// Pedido visto pelo profissional (sem morada nem contacto, RNF10);
  /// null → "não encontrado".
  Future<PedidoPerto?> pedidoPerto(String id);

  /// 15 · Valores com que a proposta arranca (os do Figma); null → a zero.
  Future<NovaProposta?> rascunhoProposta(String pedidoId);

  /// 15 · "Enviar proposta". Lança [ValidacaoException] se o valor não é
  /// válido e [NaoEncontradoException] se o pedido não existe.
  Future<void> enviarProposta(NovaProposta proposta);

  // ------------------------------------------------ 16 · 17 · Ler QR

  /// 16 · Trabalho em curso à espera do código do cliente; null = nenhum.
  Future<TrabalhoPorConfirmar?> trabalhoPorConfirmar();

  /// 16 · Todos os trabalhos à espera de código (o ecrã lista-os quando há
  /// mais do que um).
  Future<List<TrabalhoPorConfirmar>> trabalhosPorConfirmar();

  /// Detalhe do trabalho · "Estou a caminho" / "Comecei o trabalho".
  /// Lança [ValidacaoException] se a etapa já não for possível.
  Future<void> mudarEtapaServico(String pedidoId, EtapaServico etapa);

  /// Valor com que o campo do ecrã 16 arranca; null = vazio.
  Future<String?> codigoClientePredefinido();

  /// 16 · "Confirmar serviço" com o código de 6 dígitos que o cliente diz.
  /// O código identifica o pedido certo entre vários ativos. Lança
  /// [ValidacaoException] se não confere.
  Future<ServicoConfirmado> confirmarServicoComCodigo(String codigo);

  /// 17 · null → "não encontrado".
  Future<ServicoConfirmado?> servicoConfirmado(String pedidoId);

  // -------------------------------------------------------- 18 · 19 · Conversas

  /// Mais recentes primeiro.
  Future<List<Conversa>> conversas();

  /// Conversa com as mensagens; null → "não encontrado".
  Future<Conversa?> conversa(String id);

  /// 19 · Envia a mensagem (1 a 1.000 caracteres). Lança
  /// [ValidacaoException] se vazia ou longa e [NaoEncontradoException] se a
  /// conversa não existe.
  Future<Mensagem> enviarMensagem(String conversaId, String texto);

  /// 19 · Ao abrir, as mensagens passam a lidas.
  Future<void> marcarConversaLida(String conversaId);

  // ------------------------------------------------- Notificações e Ajuda

  /// Sino dos ecrãs 02 e 14 e Perfil · "Notificações" (RF08).
  Future<CaixaNotificacoes> notificacoes();

  /// Total por ler (ponto vermelho do sino).
  Future<int> notificacoesPorLer();

  /// Ao abrir a lista, todas passam a lidas.
  Future<void> marcarNotificacoesLidas();

  /// Login e Perfil · "Ajuda" (RF16). Funciona sem sessão.
  Future<List<PerguntaAjuda>> perguntasAjuda();

  // ---------------------------------------------------------------- 22 · Mapa

  /// Profissionais posicionados no mapa estático.
  Future<List<PinMapa>> pinsMapa();
}
