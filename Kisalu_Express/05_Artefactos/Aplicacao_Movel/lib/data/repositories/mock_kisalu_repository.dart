import 'package:flutter/foundation.dart';

import '../../models/avaliacao.dart';
import '../../models/categoria.dart';
import '../../models/codigo_confirmacao.dart';
import '../../models/comprovativo.dart';
import '../../models/conversa.dart';
import '../../models/estado_pedido.dart';
import '../../models/estatisticas_avaliacoes.dart';
import '../../models/mensagem.dart';
import '../../models/notificacao.dart';
import '../../models/nova_proposta.dart';
import '../../models/novo_pedido.dart';
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
import '../mock/mock_avisos.dart';
import '../mock/mock_categorias.dart';
import '../mock/mock_conversas.dart';
import '../mock/mock_estatisticas.dart';
import '../mock/mock_mapa.dart';
import '../mock/mock_painel_profissional.dart';
import '../mock/mock_pedidos.dart';
import '../mock/mock_profissionais.dart';
import '../mock/mock_sessao.dart';
import 'kisalu_repository.dart';

class _Sinal extends ChangeNotifier {
  void avisar() => notifyListeners();
}

/// Implementação em memória, com dados fictícios e relógio fixo. Tudo
/// devolve `Future`, para as views tratarem desde já o carregamento.
/// Cada instância tem o seu estado: os testes criam uma por teste.
class MockKisaluRepository implements KisaluRepository {
  MockKisaluRepository({
    this.semRede = true,
    bool comServicoEmCurso = true,
    this.latencia = Duration.zero,
    this.registoProfissionalCompleto = true,
  }) : _servicoEmCurso = comServicoEmCurso ? MockPedidos.ped1EmCurso : null,
       _historico = [...MockPedidos.historico],
       _historicoProfissional = [...MockPedidos.historicoProfissional],
       _detalhes = {'ped1': MockPedidos.ped1Novo};

  /// true → o ecrã 10 abre no estado do Figma (sem rede) e `publicarPedido`
  /// falha. Passar false para o estado "com rede".
  bool semRede;

  /// Atraso simulado de cada chamada (para ver os esqueletos).
  final Duration latencia;

  /// false → "Mudar para profissional" abre o registo (ecrã 12).
  bool registoProfissionalCompleto;

  final _alteracoes = _Sinal();

  @override
  Listenable get alteracoes => _alteracoes;

  Pedido? _servicoEmCurso;
  Pedido? _servicoAntesDeAceitar;
  final List<Pedido> _historico;
  final List<Pedido> _historicoProfissional;
  PerfilUtilizador _perfilAtivo = PerfilUtilizador.cliente;
  PedidoCodigoSms? _smsPendente;
  VerificacaoIdentidade _verificacao = MockPainelProfissional.verificacao;
  bool _disponivel = MockPainelProfissional.painel.disponivel;
  final Map<String, ServicoConfirmado> _confirmados = {};
  final List<NovaProposta> _propostasEnviadas = [];
  late final List<Conversa> _conversas = [...MockConversas.todas];
  final Map<String, Pedido> _detalhes;
  final Map<String, NovaAvaliacao> _avaliacoes = {};
  final List<({String pedidoId, String descricao})> _reportes = [];
  NovoPedido? _rascunho = MockSessao.rascunhoPedido;
  late final List<Notificacao> _notificacoes = [...MockAvisos.notificacoes];
  final List<({String pedidoId, String propostaId})> _recusadas = [];
  final Map<String, NovoPedido> _editados = {};

  /// Propostas recusadas nesta instância (para testes).
  List<({String pedidoId, String propostaId})> get recusadas => _recusadas;

  /// Pedidos editados nesta instância (para testes).
  Map<String, NovoPedido> get editados => _editados;

  /// Problemas reportados nesta instância (para testes).
  List<({String pedidoId, String descricao})> get reportes => _reportes;

  /// Propostas enviadas pelo profissional nesta instância (para testes).
  List<NovaProposta> get propostasEnviadas => _propostasEnviadas;

  /// Avaliações enviadas nesta instância (para testes).
  Map<String, NovaAvaliacao> get avaliacoesEnviadas => _avaliacoes;

  Future<void> _espera() async {
    if (latencia > Duration.zero) await Future<void>.delayed(latencia);
  }

  @override
  DateTime agora() => MockSessao.agora;

  @override
  bool get modoDemonstracao => true;

  // ------------------------------------------------------------------ sessão

  @override
  PerfilUtilizador get perfilAtivo => _perfilAtivo;

  @override
  Future<void> mudarPerfil(PerfilUtilizador perfil) async {
    await _espera();
    if (perfil == _perfilAtivo) return;
    _perfilAtivo = perfil;
    _alteracoes.avisar();
  }

  @override
  Future<Utilizador> utilizador() async {
    await _espera();
    final u = _perfilAtivo == PerfilUtilizador.profissional
        ? MockSessao.utilizadorProfissional
        : MockSessao.utilizador;
    return Utilizador(
      nome: u.nome,
      zona: u.zona,
      temNovidades: _notificacoes.any((n) => !n.lida),
      nomeCompleto: u.nomeCompleto,
      telemovel: u.telemovel,
      moradasGuardadas: u.moradasGuardadas,
      favoritos: u.favoritos,
      registoProfissionalCompleto: registoProfissionalCompleto,
    );
  }

  @override
  Future<String?> telemovelPredefinido() async {
    await _espera();
    return MockSessao.telemovelPredefinido;
  }

  @override
  Future<void> pedirCodigoSms(
    String telemovel,
    PerfilUtilizador perfil, {
    bool criarConta = false,
  }) async {
    await _espera();
    _smsPendente = PedidoCodigoSms(
      telemovel: telemovel,
      perfil: perfil,
      criarConta: criarConta,
    );
  }

  @override
  Future<PedidoCodigoSms> codigoSmsPendente() async {
    await _espera();
    return _smsPendente ??
        const PedidoCodigoSms(
          telemovel: '+244923000000',
          perfil: PerfilUtilizador.cliente,
        );
  }

  @override
  Future<String?> codigoSmsPredefinido() async {
    await _espera();
    return MockSessao.codigoSmsPredefinido;
  }

  /// Aceita qualquer código, exceto "000000" (para simular o erro). Só quem
  /// veio de "Criar conta" como profissional segue para o registo.
  @override
  Future<bool> validarCodigoSms(String telemovel, String codigo) async {
    await _espera();
    if (codigo.trim() == '000000') {
      throw const ValidacaoException(
        'O código não está certo. Confirme o SMS e tente outra vez.',
      );
    }
    final pendente = _smsPendente;
    return pendente != null &&
        pendente.perfil == PerfilUtilizador.profissional &&
        pendente.criarConta;
  }

  @override
  Future<void> terminarSessao() => _espera();

  /// Os dados fictícios abrem sempre no Login.
  @override
  Future<bool> retomarSessao() async => false;

  // ------------------------------------------------------------ 02 · Início

  @override
  Future<List<Categoria>> categorias() async {
    await _espera();
    return MockCategorias.todas;
  }

  @override
  Future<List<Profissional>> profissionaisPertoDeSi() async {
    await _espera();
    return MockProfissionais.pertoDeSi;
  }

  // ----------------------------------------------------- 03 · Profissional

  @override
  Future<Profissional?> profissional(String id) async {
    await _espera();
    return MockProfissionais.todos.where((p) => p.id == id).firstOrNull;
  }

  @override
  Future<EstatisticasAvaliacoes?> estatisticasAvaliacoes(
    String profissionalId,
  ) async {
    await _espera();
    final json = MockEstatisticas.porProfissional[profissionalId];
    return json == null ? null : EstatisticasAvaliacoes.fromJson(json);
  }

  // ------------------------------------------------- 04 · Pedido e propostas

  @override
  Future<Pedido?> pedido(String id) async {
    await _espera();
    return _detalhes[id] ??
        _historico.where((p) => p.id == id).firstOrNull ??
        _historicoProfissional.where((p) => p.id == id).firstOrNull;
  }

  void _atualizarHistorico(Pedido pedido) {
    final i = _historico.indexWhere((p) => p.id == pedido.id);
    if (i >= 0) {
      _historico[i] = pedido;
    } else {
      _historico.insert(0, pedido);
    }
  }

  @override
  Future<void> cancelarPedido(String id) async {
    await _espera();
    final atual = await pedido(id);
    if (atual == null) throw const NaoEncontradoException();
    if (atual.estado == EstadoPedido.concluido ||
        atual.estado == EstadoPedido.cancelado) {
      throw const ValidacaoException('Já não é possível cancelar este pedido.');
    }
    final cancelado = atual.copyWith(estado: EstadoPedido.cancelado);
    _detalhes[id] = cancelado;
    _atualizarHistorico(cancelado);
    if (_servicoEmCurso?.id == id) _servicoEmCurso = null;
    _alteracoes.avisar();
  }

  @override
  Future<Pedido> aceitarProposta(String pedidoId, String propostaId) async {
    await _espera();
    final atual = _detalhes[pedidoId];
    if (atual == null) throw const NaoEncontradoException();
    final proposta = atual.propostas
        .where((p) => p.id == propostaId)
        .firstOrNull;
    if (proposta == null || atual.estado != EstadoPedido.novo) {
      throw const ValidacaoException(
        'Esta proposta já não está disponível. Veja as outras propostas.',
      );
    }
    final aceite = atual.copyWith(
      estado: EstadoPedido.emCurso,
      profissional: proposta.profissional,
      valor: proposta.valor,
      propostaAceitaId: proposta.id,
      etapa: EtapaServico.aceite,
      aceiteEm: agora(),
    );
    _servicoAntesDeAceitar = _servicoEmCurso;
    _detalhes[pedidoId] = aceite;
    _atualizarHistorico(aceite);
    _servicoEmCurso = aceite;
    _alteracoes.avisar();
    return aceite;
  }

  @override
  Future<void> desfazerAceitacao(String pedidoId) async {
    await _espera();
    final atual = _detalhes[pedidoId];
    if (atual == null || atual.propostaAceitaId == null) {
      throw const ValidacaoException(
        'Já não é possível desfazer. Veja o estado em Pedidos.',
      );
    }
    final desfeito = atual.copyWith(
      estado: EstadoPedido.novo,
      limparAceitacao: true,
    );
    _detalhes[pedidoId] = desfeito;
    _atualizarHistorico(desfeito);
    _servicoEmCurso = _servicoAntesDeAceitar;
    _servicoAntesDeAceitar = null;
    _alteracoes.avisar();
  }

  @override
  Future<void> recusarProposta(String pedidoId, String propostaId) async {
    await _espera();
    final atual = _detalhes[pedidoId];
    if (atual == null) throw const NaoEncontradoException();
    if (atual.estado != EstadoPedido.novo ||
        !atual.propostas.any((p) => p.id == propostaId)) {
      throw const ValidacaoException(
        'Esta proposta já não está disponível. Veja as outras propostas.',
      );
    }
    _detalhes[pedidoId] = atual.copyWith(
      propostas: [...atual.propostas.where((p) => p.id != propostaId)],
    );
    _recusadas.add((pedidoId: pedidoId, propostaId: propostaId));
    _alteracoes.avisar();
  }

  /// O mesmo pedido com os campos que o formulário muda.
  Pedido _comAlteracoes(Pedido p, NovoPedido n) => Pedido(
    id: p.id,
    titulo: n.titulo,
    categoriaId: n.categoriaId,
    estado: p.estado,
    data: p.data,
    descricao: n.descricao,
    zona: n.zona,
    pontoReferencia: n.pontoReferencia,
    quando: n.quando,
    profissional: p.profissional,
    valor: p.valor,
    propostas: p.propostas,
    propostaAceitaId: p.propostaAceitaId,
    numFotos: n.numFotos,
  );

  @override
  Future<Pedido> editarPedido(String pedidoId, NovoPedido alteracoes) async {
    await _espera();
    final atual = await pedido(pedidoId);
    if (atual == null) throw const NaoEncontradoException();
    if (atual.estado != EstadoPedido.novo || atual.propostaAceitaId != null) {
      throw const ValidacaoException('Este pedido já não pode ser editado.');
    }
    final editado = _comAlteracoes(atual, alteracoes);
    _detalhes[pedidoId] = editado;
    _editados[pedidoId] = alteracoes;
    _alteracoes.avisar();
    return editado;
  }

  @override
  Future<NovoPedido> pedirDeNovo(String pedidoId) async {
    await _espera();
    final antigo = await pedido(pedidoId);
    if (antigo == null) throw const NaoEncontradoException();
    return NovoPedido(
      categoriaId: antigo.categoriaId,
      titulo: antigo.titulo,
      descricao: antigo.descricao.isEmpty ? antigo.titulo : antigo.descricao,
      zona: antigo.zona.isEmpty ? MockSessao.rascunhoPedido.zona : antigo.zona,
      pontoReferencia:
          antigo.pontoReferencia ?? MockSessao.rascunhoPedido.pontoReferencia,
    );
  }

  // ----------------------------------------------------- 05 / 09 · QR Code

  @override
  Future<Pedido?> servicoEmCurso() async {
    await _espera();
    return _servicoEmCurso;
  }

  @override
  Future<CodigoConfirmacao> codigoConfirmacao(String pedidoId) async {
    await _espera();
    final emCurso =
        _servicoEmCurso?.id == pedidoId ||
        (await pedido(pedidoId))?.estado == EstadoPedido.emCurso;
    if (!emCurso) throw const NaoEncontradoException();
    return MockSessao.codigoConfirmacao(pedidoId);
  }

  /// Concluído há mais de 7 dias ([Pedido.podeReclamar] false) dá o erro da
  /// garantia, como o 422 da API.
  @override
  Future<ResultadoReporte> reportarProblema(
    String pedidoId,
    String descricao,
  ) async {
    await _espera();
    final alvo = await pedido(pedidoId);
    if (alvo == null) throw const NaoEncontradoException();
    if (alvo.estado == EstadoPedido.concluido && !alvo.podeReclamar) {
      throw const ValidacaoException(
        'Já passaram os 7 dias da garantia. Fale connosco pela Ajuda.',
      );
    }
    _reportes.add((pedidoId: pedidoId, descricao: descricao));
    final emCurso = _servicoEmCurso;
    final pro =
        alvo.profissional ??
        (emCurso?.id == pedidoId ? emCurso?.profissional : null);
    return ResultadoReporte(
      mensagem: ResultadoReporte.mensagemPredefinida,
      contactoNome: pro?.nome,
      contactoTelemovel: pro == null ? null : '+244923111222',
    );
  }

  // ---------------------------------------------------------- 06 · Avaliar

  @override
  Future<Comprovativo?> comprovativo(String pedidoId) async {
    await _espera();
    return MockPedidos.comprovativos[pedidoId];
  }

  @override
  Future<NovaAvaliacao?> rascunhoAvaliacao(String pedidoId) async {
    await _espera();
    return pedidoId == 'ped1' && !_avaliacoes.containsKey(pedidoId)
        ? MockSessao.rascunhoAvaliacao
        : null;
  }

  @override
  Future<void> enviarAvaliacao(String pedidoId, NovaAvaliacao avaliacao) async {
    await _espera();
    if (!MockPedidos.comprovativos.containsKey(pedidoId)) {
      throw const NaoEncontradoException();
    }
    if (_avaliacoes.containsKey(pedidoId)) {
      throw const ValidacaoException('Este serviço já foi avaliado.');
    }
    _avaliacoes[pedidoId] = avaliacao;
    final i = _historico.indexWhere((p) => p.id == pedidoId);
    if (i >= 0) _historico[i] = _historico[i].copyWith(avaliado: true);
    _alteracoes.avisar();
  }

  // ------------------------------------------------------------ 07 · Histórico

  @override
  Future<List<Pedido>> historico() async {
    await _espera();
    return List.unmodifiable(
      _perfilAtivo == PerfilUtilizador.profissional
          ? _historicoProfissional
          : _historico,
    );
  }

  // ------------------------------------------------------- 10 · Novo pedido

  @override
  Future<NovoPedido?> rascunhoPedido() async {
    await _espera();
    return _rascunho;
  }

  @override
  Future<void> guardarRascunhoPedido(NovoPedido rascunho) async {
    await _espera();
    _rascunho = rascunho;
  }

  @override
  Future<void> apagarRascunhoPedido() async {
    await _espera();
    _rascunho = null;
  }

  @override
  Future<void> verificarLigacao() async {
    await _espera();
    if (semRede) throw const SemRedeException();
  }

  /// Devolve sempre o pedido `ped1` (a spec navega para `/pedidos/ped1`).
  @override
  Future<PedidoPublicado> publicarPedido(NovoPedido novoPedido) async {
    await _espera();
    if (semRede) {
      throw const SemRedeException(
        'Sem ligação. Guardámos o seu pedido e tentamos outra vez.',
      );
    }
    final plural = MockCategorias.todas
        .where((c) => c.id == novoPedido.categoriaId)
        .firstOrNull
        ?.plural;
    return PedidoPublicado(
      pedido: _detalhes['ped1']!,
      profissionaisAvisados: MockSessao.profissionaisAvisados,
      categoriaPlural: plural ?? 'profissionais',
    );
  }

  // --------------------------------------------- 12 · 13 · Registo profissional

  @override
  Future<RegistoProfissional?> rascunhoRegistoProfissional() async {
    await _espera();
    return MockPainelProfissional.rascunhoRegisto;
  }

  @override
  Future<void> guardarRegistoProfissional(RegistoProfissional registo) async {
    await _espera();
    if (registo.categoriaIds.isEmpty) {
      throw const ValidacaoException('Escolha pelo menos um serviço.');
    }
    _perfilAtivo = PerfilUtilizador.profissional;
    _alteracoes.avisar();
  }

  @override
  Future<VerificacaoIdentidade> verificacaoIdentidade() async {
    await _espera();
    return _verificacao;
  }

  @override
  Future<void> adicionarDocumento() async {
    await _espera();
    _verificacao = _verificacao.copyWith(documentoEnviado: true);
  }

  @override
  Future<void> adicionarFotoRosto() async {
    await _espera();
    _verificacao = _verificacao.copyWith(rostoEnviado: true);
  }

  @override
  Future<void> enviarParaVerificacao() async {
    await _espera();
    if (!_verificacao.completa) {
      throw const ValidacaoException(
        'Falta a fotografia do rosto. Adicione-a para enviar.',
      );
    }
  }

  // ------------------------------------------------ 14 · Início profissional

  @override
  Future<PainelProfissional> painelProfissional() async {
    await _espera();
    return MockPainelProfissional.painel.copyWith(disponivel: _disponivel);
  }

  @override
  Future<void> definirDisponibilidade(bool disponivel) async {
    await _espera();
    _disponivel = disponivel;
  }

  // ------------------------------------------------------ 15 · Enviar proposta

  @override
  Future<PedidoPerto?> pedidoPerto(String id) async {
    await _espera();
    return MockPainelProfissional.pedidos.where((p) => p.id == id).firstOrNull;
  }

  @override
  Future<NovaProposta?> rascunhoProposta(String pedidoId) async {
    await _espera();
    return pedidoId == MockPainelProfissional.fuga.id
        ? MockPainelProfissional.rascunhoProposta
        : null;
  }

  @override
  Future<void> enviarProposta(NovaProposta proposta) async {
    await _espera();
    if (await pedidoPerto(proposta.pedidoId) == null) {
      throw const NaoEncontradoException();
    }
    if (proposta.valorFechado <= 0) {
      throw const ValidacaoException('Indique o valor da proposta.');
    }
    _propostasEnviadas.add(proposta);
  }

  // ------------------------------------------------------- 16 · 17 · Ler QR

  /// O trabalho `tp1`, enquanto não estiver confirmado.
  @override
  Future<TrabalhoPorConfirmar?> trabalhoPorConfirmar() async {
    await _espera();
    final s = MockPainelProfissional.servicoConfirmado;
    if (_confirmados.containsKey(s.pedidoId)) return null;
    return TrabalhoPorConfirmar(
      pedidoId: s.pedidoId,
      servico: s.servico,
      cliente: s.cliente,
      valor: s.valor,
    );
  }

  @override
  Future<List<TrabalhoPorConfirmar>> trabalhosPorConfirmar() async {
    final t = await trabalhoPorConfirmar();
    return t == null ? const [] : [t];
  }

  @override
  Future<void> mudarEtapaServico(String pedidoId, EtapaServico etapa) async {
    await _espera();
    final i = _historicoProfissional.indexWhere((p) => p.id == pedidoId);
    if (i < 0) throw const NaoEncontradoException();
    final atual = _historicoProfissional[i].etapa;
    final possivel = switch (etapa) {
      EtapaServico.aCaminho => atual == EtapaServico.aceite,
      EtapaServico.emCurso =>
        atual == EtapaServico.aceite || atual == EtapaServico.aCaminho,
      EtapaServico.aceite => false,
    };
    if (!possivel) {
      throw const ValidacaoException(
        'Este trabalho já passou essa etapa. Atualize o ecrã.',
      );
    }
    _historicoProfissional[i] = _historicoProfissional[i].copyWith(
      etapa: etapa,
    );
    _alteracoes.avisar();
  }

  @override
  Future<String?> codigoClientePredefinido() async {
    await _espera();
    return MockSessao.codigoClientePredefinido;
  }

  /// Qualquer código de 6 dígitos confirma o trabalho `tp1`, exceto
  /// "000000" (para simular o erro).
  @override
  Future<ServicoConfirmado> confirmarServicoComCodigo(String codigo) async {
    await _espera();
    final limpo = codigo.replaceAll(RegExp(r'\s+'), '');
    if (!RegExp(r'^\d{6}$').hasMatch(limpo)) {
      throw const ValidacaoException(
        'O código tem 6 dígitos. Confirme com o cliente.',
      );
    }
    if (limpo == '000000') {
      throw const ValidacaoException(
        'O código não está certo. Confirme com o cliente.',
      );
    }
    final confirmado = MockPainelProfissional.servicoConfirmado;
    _confirmados[confirmado.pedidoId] = confirmado;
    final i = _historicoProfissional.indexWhere(
      (p) => p.id == confirmado.pedidoId,
    );
    if (i >= 0) {
      _historicoProfissional[i] = _historicoProfissional[i].copyWith(
        estado: EstadoPedido.concluido,
      );
    }
    _alteracoes.avisar();
    return confirmado;
  }

  /// `tp1` existe sempre, para o ecrã abrir diretamente na galeria.
  @override
  Future<ServicoConfirmado?> servicoConfirmado(String pedidoId) async {
    await _espera();
    return _confirmados[pedidoId] ??
        (pedidoId == MockPainelProfissional.servicoConfirmado.pedidoId
            ? MockPainelProfissional.servicoConfirmado
            : null);
  }

  // -------------------------------------------------------- 18 · 19 · Conversas

  DateTime _ultimaEm(Conversa c) =>
      c.ultima?.enviadaEm ?? DateTime.fromMillisecondsSinceEpoch(0);

  @override
  Future<List<Conversa>> conversas() async {
    await _espera();
    final ordenadas = [..._conversas]
      ..sort((a, b) => _ultimaEm(b).compareTo(_ultimaEm(a)));
    return List.unmodifiable(ordenadas);
  }

  @override
  Future<Conversa?> conversa(String id) async {
    await _espera();
    return _conversas.where((c) => c.id == id).firstOrNull;
  }

  @override
  Future<Mensagem> enviarMensagem(String conversaId, String texto) async {
    await _espera();
    final i = _conversas.indexWhere((c) => c.id == conversaId);
    if (i < 0) throw const NaoEncontradoException();
    final limpo = texto.trim();
    if (limpo.isEmpty) {
      throw const ValidacaoException('Escreva uma mensagem para enviar.');
    }
    if (limpo.length > 1000) {
      throw const ValidacaoException(
        'A mensagem pode ter até 1.000 caracteres.',
      );
    }
    final atual = _conversas[i];
    final mensagem = Mensagem(
      id: 'm${atual.mensagens.length + 1}',
      texto: limpo,
      minha: true,
      enviadaEm: agora(),
    );
    _conversas[i] = atual.copyWith(mensagens: [...atual.mensagens, mensagem]);
    _alteracoes.avisar();
    return mensagem;
  }

  @override
  Future<void> marcarConversaLida(String conversaId) async {
    await _espera();
    final i = _conversas.indexWhere((c) => c.id == conversaId);
    if (i < 0 || _conversas[i].naoLidas == 0) return;
    _conversas[i] = _conversas[i].copyWith(naoLidas: 0);
    _alteracoes.avisar();
  }

  // ------------------------------------------------- Notificações e Ajuda

  @override
  Future<CaixaNotificacoes> notificacoes() async {
    await _espera();
    return CaixaNotificacoes(
      naoLidas: _notificacoes.where((n) => !n.lida).length,
      lista: List.unmodifiable(_notificacoes),
    );
  }

  @override
  Future<int> notificacoesPorLer() async {
    await _espera();
    return _notificacoes.where((n) => !n.lida).length;
  }

  @override
  Future<void> marcarNotificacoesLidas() async {
    await _espera();
    if (_notificacoes.every((n) => n.lida)) return;
    for (var i = 0; i < _notificacoes.length; i++) {
      _notificacoes[i] = _notificacoes[i].lidaAgora();
    }
    _alteracoes.avisar();
  }

  @override
  Future<List<PerguntaAjuda>> perguntasAjuda() async {
    await _espera();
    return MockAvisos.perguntas;
  }

  // ---------------------------------------------------------------- 22 · Mapa

  @override
  Future<List<PinMapa>> pinsMapa() async {
    await _espera();
    return MockMapa.pins;
  }
}
