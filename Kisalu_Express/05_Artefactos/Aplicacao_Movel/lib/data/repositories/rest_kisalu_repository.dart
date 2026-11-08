import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../models/avaliacao.dart';
import '../../models/categoria.dart';
import '../../models/codigo_confirmacao.dart';
import '../../models/comprovativo.dart';
import '../../models/conversa.dart';
import '../../models/estado_pedido.dart';
import '../../models/json_leitura.dart';
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
import '../../services/api_client.dart';
import '../../services/armazenamento_local.dart';
import 'kisalu_repository.dart';

class _Sinal extends ChangeNotifier {
  void avisar() => notifyListeners();
}

/// Implementação do [KisaluRepository] sobre a kisalu-api. Cada método
/// segue a tabela da secção 2 de docs/CONTRATO-API.md.
///
/// Ficam só na app (sem chamar a API): o relógio, o perfil ativo em cache, o
/// pedido de código SMS em curso e os rascunhos. O token e o rascunho do
/// novo pedido ficam no aparelho ([TokenStorage], [RascunhoStorage]); sem
/// eles (testes) ficam só em memória.
class RestKisaluRepository implements KisaluRepository {
  RestKisaluRepository(
    this._api, {
    TokenStorage? tokens,
    RascunhoStorage? rascunhos,
  }) : _tokens = tokens ?? ValorEmMemoria(),
       _rascunhos = rascunhos ?? ValorEmMemoria() {
    _api.aoExpirarSessao = _aoExpirarSessao;
  }

  final ApiClient _api;
  final TokenStorage _tokens;
  final RascunhoStorage _rascunhos;
  final _alteracoes = _Sinal();
  final _sessaoExpirada = _Sinal();

  PerfilUtilizador _perfilAtivo = PerfilUtilizador.cliente;
  PedidoCodigoSms? _smsPendente;
  String? _codigoDev;

  /// Telemóvel e código do QR dos dados de exemplo da API, só em debug.
  static const _telemovelExemplo = '+244 923 000 000';
  static const _codigoQrExemplo = '482173';

  static final _soDigitos = RegExp(r'^\d+$');

  @override
  Listenable get alteracoes => _alteracoes;

  /// Avisa quando a API respondeu 401: a app volta ao Login.
  Listenable get sessaoExpirada => _sessaoExpirada;

  /// true depois de confirmar o código SMS (há token em memória).
  bool get temSessao => _api.temSessao;

  @override
  DateTime agora() => DateTime.now();

  @override
  bool get modoDemonstracao => false;

  /// O armazenamento pode falhar (ex.: navegador sem WebCrypto): a sessão
  /// continua só em memória.
  Future<void> _semFalhar(Future<void> Function() acao) async {
    try {
      await acao();
    } on Exception {
      // Sem armazenamento local: nada a fazer.
    }
  }

  void _aoExpirarSessao() {
    _limparSessao();
    _sessaoExpirada.avisar();
  }

  void _limparSessao() {
    _api.limparToken();
    _semFalhar(_tokens.apagar);
    _perfilAtivo = PerfilUtilizador.cliente;
    _smsPendente = null;
    _codigoDev = null;
  }

  // ------------------------------------------------------------- utilitários

  /// Os ids do servidor são inteiros: outro formato nem chega à API.
  bool _idValido(String id) => _soDigitos.hasMatch(id);

  Map<String, dynamic> _mapa(Object? data) {
    final mapa = JsonLeitura.mapaOuNull(data);
    if (mapa == null) throw const ServidorException();
    return mapa;
  }

  /// GET que devolve null em 404 (métodos `T?`).
  Future<T?> _obterOuNull<T>(
    String caminho,
    T Function(Map<String, dynamic>) ler,
  ) async {
    try {
      final data = await _api.get(caminho);
      final mapa = JsonLeitura.mapaOuNull(data);
      return mapa == null ? null : ler(mapa);
    } on NaoEncontradoException {
      return null;
    }
  }

  Future<List<T>> _lista<T>(
    String caminho,
    T Function(Map<String, dynamic>) ler, {
    Map<String, String>? query,
  }) async {
    final data = await _api.get(caminho, query: query);
    if (data is! List) throw const ServidorException();
    return JsonLeitura.lista(data, ler);
  }

  void _lerPerfil(Object? valor) {
    if (valor == null) return;
    _perfilAtivo = PerfilUtilizador.doServidor(valor);
  }

  // ------------------------------------------------------------------ sessão

  @override
  PerfilUtilizador get perfilAtivo => _perfilAtivo;

  @override
  Future<void> mudarPerfil(PerfilUtilizador perfil) async {
    if (perfil == _perfilAtivo) return;
    final data = _mapa(
      await _api.put('/eu/perfil-ativo', {'perfil': perfil.name}),
    );
    _lerPerfil(data['perfil_ativo'] ?? perfil.name);
    _alteracoes.avisar();
  }

  @override
  Future<Utilizador> utilizador() async {
    final data = _mapa(await _api.get('/eu'));
    _lerPerfil(data['perfil_ativo']);
    return Utilizador.fromJson(data);
  }

  @override
  Future<String?> telemovelPredefinido() async =>
      kDebugMode ? _telemovelExemplo : null;

  @override
  Future<void> pedirCodigoSms(
    String telemovel,
    PerfilUtilizador perfil, {
    bool criarConta = false,
  }) async {
    final data = JsonLeitura.mapa(
      await _api.post('/auth/sms/pedir', {
        'telemovel': telemovel,
        'perfil': perfil.name,
        'criar_conta': criarConta,
      }),
    );
    _smsPendente = PedidoCodigoSms(
      telemovel: telemovel,
      perfil: perfil,
      criarConta: criarConta,
    );
    _codigoDev = JsonLeitura.textoOuNull(data['codigo_dev']);
  }

  @override
  Future<PedidoCodigoSms> codigoSmsPendente() async {
    final pendente = _smsPendente;
    if (pendente == null) {
      throw const ValidacaoException(
        'Peça primeiro o código com o seu número de telemóvel.',
      );
    }
    return pendente;
  }

  /// Em debug a API devolve o código (`codigo_dev`): o ecrã 11 já abre
  /// preenchido.
  @override
  Future<String?> codigoSmsPredefinido() async =>
      kDebugMode ? _codigoDev : null;

  @override
  Future<bool> validarCodigoSms(String telemovel, String codigo) async {
    final pendente = _smsPendente;
    final perfil = pendente?.perfil ?? PerfilUtilizador.cliente;
    final data = _mapa(
      await _api.post('/auth/sms/verificar', {
        'telemovel': telemovel,
        'codigo': codigo,
        'perfil': perfil.name,
        // O ecrã 01 diz "Ao continuar aceita os Termos e a Política de
        // Privacidade".
        'aceita_privacidade': true,
      }),
    );
    final token = JsonLeitura.textoOuNull(data['token']);
    if (token == null || token.isEmpty) throw const ServidorException();
    _api.definirToken(token);
    await _semFalhar(() => _tokens.guardar(token));
    _lerPerfil(data['perfil_ativo'] ?? perfil.name);
    _codigoDev = null;
    _alteracoes.avisar();

    if (perfil != PerfilUtilizador.profissional) return false;
    final eu = JsonLeitura.mapa(data['utilizador']);
    final profissional = JsonLeitura.mapaOuNull(eu['profissional']);
    final registoCompleto = JsonLeitura.booleano(
      profissional?['registo_completo'],
    );
    return JsonLeitura.booleano(data['novo']) ||
        (pendente?.criarConta ?? false) ||
        !registoCompleto;
  }

  @override
  Future<void> terminarSessao() async {
    try {
      if (_api.temSessao) await _api.post('/auth/sair');
    } on KisaluException {
      // A sessão termina na app mesmo que a API não responda.
    } finally {
      _limparSessao();
      // Quem sai não deixa o rascunho do pedido para a pessoa seguinte.
      await _semFalhar(_rascunhos.apagar);
      _alteracoes.avisar();
    }
  }

  @override
  Future<bool> retomarSessao() async {
    String? token;
    try {
      token = await _tokens.ler();
    } on Exception {
      return false;
    }
    if (token == null || token.isEmpty) return false;
    _api.definirToken(token);
    try {
      await utilizador();
      _alteracoes.avisar();
      return true;
    } on SessaoExpiradaException {
      return false; // o 401 já apagou o token
    } on KisaluException {
      // Sem rede ou erro do servidor: o token fica guardado, abre no Login.
      _api.limparToken();
      return false;
    }
  }

  // ------------------------------------------------------------ 02 · Início

  @override
  Future<List<Categoria>> categorias() =>
      _lista('/categorias', Categoria.fromJson);

  @override
  Future<List<Profissional>> profissionaisPertoDeSi() => _lista(
    '/profissionais/perto',
    Profissional.fromJson,
    query: {'limit': '20'},
  );

  // ----------------------------------------------------- 03 · Profissional

  @override
  Future<Profissional?> profissional(String id) async => _idValido(id)
      ? _obterOuNull('/profissionais/$id', Profissional.fromJson)
      : null;

  // ------------------------------------------------- 04 · Pedido e propostas

  @override
  Future<Pedido?> pedido(String id) async =>
      _idValido(id) ? _obterOuNull('/pedidos/$id', Pedido.fromJson) : null;

  @override
  Future<void> cancelarPedido(String id) async {
    if (!_idValido(id)) throw const NaoEncontradoException();
    await _api.post('/pedidos/$id/cancelar');
    _alteracoes.avisar();
  }

  @override
  Future<Pedido> aceitarProposta(String pedidoId, String propostaId) async {
    if (!_idValido(pedidoId) || !_idValido(propostaId)) {
      throw const NaoEncontradoException();
    }
    await _api.post('/propostas/$propostaId/aceitar');
    _alteracoes.avisar();
    final aceite = await pedido(pedidoId);
    if (aceite == null) throw const NaoEncontradoException();
    return aceite;
  }

  @override
  Future<void> desfazerAceitacao(String pedidoId) async {
    if (!_idValido(pedidoId)) throw const NaoEncontradoException();
    await _api.post('/pedidos/$pedidoId/desfazer-aceitacao');
    _alteracoes.avisar();
  }

  @override
  Future<void> recusarProposta(String pedidoId, String propostaId) async {
    if (!_idValido(pedidoId) || !_idValido(propostaId)) {
      throw const NaoEncontradoException();
    }
    await _api.post('/propostas/$propostaId/recusar');
    _alteracoes.avisar();
  }

  @override
  Future<Pedido> editarPedido(String pedidoId, NovoPedido alteracoes) async {
    if (!_idValido(pedidoId)) throw const NaoEncontradoException();
    final data = await _api.patch(
      '/pedidos/$pedidoId',
      alteracoes.paraEditar(),
    );
    _alteracoes.avisar();
    // A API devolve o PedidoJSON; se não vier, lê-se outra vez.
    final mapa = JsonLeitura.mapaOuNull(data);
    final atualizado = mapa != null && mapa.containsKey('titulo')
        ? Pedido.fromJson(mapa)
        : await pedido(pedidoId);
    if (atualizado == null) throw const NaoEncontradoException();
    return atualizado;
  }

  /// A API cria um rascunho igual ao antigo (mesma morada); publicar grava
  /// as alterações e publica-o (ver [publicarPedido]): não fica um pedido
  /// duplicado.
  @override
  Future<NovoPedido> pedirDeNovo(String pedidoId) async {
    if (!_idValido(pedidoId)) throw const NaoEncontradoException();
    final criado = _mapa(await _api.post('/pedidos/$pedidoId/pedir-de-novo'));
    final rascunhoId = JsonLeitura.id(criado['id']);
    final junto = JsonLeitura.mapaOuNull(criado['pedido']);
    // O 201 traz o PedidoJSON do rascunho; o ponto de referência vem do
    // detalhe (morada).
    final base =
        (_idValido(rascunhoId) ? await pedido(rascunhoId) : null) ??
        (junto == null ? null : Pedido.fromJson(junto)) ??
        await pedido(pedidoId);
    if (base == null) throw const NaoEncontradoException();
    return NovoPedido(
      categoriaId: base.categoriaId,
      titulo: base.titulo,
      descricao: base.descricao,
      zona: base.zona,
      pontoReferencia: base.pontoReferencia ?? '',
      rascunhoId: _idValido(rascunhoId) ? rascunhoId : null,
    );
  }

  // ----------------------------------------------------- 05 / 09 · QR Code

  @override
  Future<Pedido?> servicoEmCurso() =>
      _obterOuNull('/pedidos/em-curso', Pedido.fromJson);

  @override
  Future<CodigoConfirmacao> codigoConfirmacao(String pedidoId) async {
    if (!_idValido(pedidoId)) throw const NaoEncontradoException();
    return CodigoConfirmacao.fromJson(
      _mapa(await _api.get('/pedidos/$pedidoId/qr')),
    );
  }

  @override
  Future<ResultadoReporte> reportarProblema(
    String pedidoId,
    String descricao,
  ) async {
    if (!_idValido(pedidoId)) throw const NaoEncontradoException();
    final data = await _api.post('/pedidos/$pedidoId/reclamacoes', {
      'tipo': 'outro',
      'descricao': descricao,
    });
    _alteracoes.avisar();
    return ResultadoReporte.fromJson(JsonLeitura.mapa(data));
  }

  // ---------------------------------------------------------- 06 · Avaliar

  @override
  Future<Comprovativo?> comprovativo(String pedidoId) async =>
      _idValido(pedidoId)
      ? _obterOuNull('/pedidos/$pedidoId/comprovativo', Comprovativo.fromJson)
      : null;

  @override
  Future<NovaAvaliacao?> rascunhoAvaliacao(String pedidoId) async => null;

  @override
  Future<void> enviarAvaliacao(String pedidoId, NovaAvaliacao avaliacao) async {
    if (!_idValido(pedidoId)) throw const NaoEncontradoException();
    await _api.post('/pedidos/$pedidoId/avaliacao', avaliacao.toJson());
    _alteracoes.avisar();
  }

  // ------------------------------------------------------------ 07 · Histórico

  @override
  Future<List<Pedido>> historico() async {
    final pedidos = await _lista(
      '/pedidos',
      Pedido.fromJson,
      query: {'limit': '100'},
    );
    // Mais recentes primeiro, mesmo que a API mude a ordem.
    return pedidos..sort((a, b) => b.data.compareTo(a.data));
  }

  // ------------------------------------------------------- 10 · Novo pedido

  @override
  Future<NovoPedido?> rascunhoPedido() async {
    try {
      final texto = await _rascunhos.ler();
      if (texto == null || texto.isEmpty) return null;
      final mapa = JsonLeitura.mapaOuNull(jsonDecode(texto));
      return mapa == null ? null : NovoPedido.doArmazenado(mapa);
    } on Exception {
      return null; // rascunho ilegível: começa do zero
    }
  }

  @override
  Future<void> guardarRascunhoPedido(NovoPedido rascunho) => _semFalhar(
    () => _rascunhos.guardar(jsonEncode(rascunho.paraArmazenar())),
  );

  @override
  Future<void> apagarRascunhoPedido() => _semFalhar(_rascunhos.apagar);

  @override
  Future<void> verificarLigacao() => _api.get('/saude');

  @override
  Future<PedidoPublicado> publicarPedido(NovoPedido novoPedido) async {
    final rascunhoId = novoPedido.rascunhoId;
    if (rascunhoId != null && _idValido(rascunhoId)) {
      return _publicarRascunho(rascunhoId, novoPedido);
    }
    final data = _mapa(await _api.post('/pedidos', novoPedido.toJson()));
    _alteracoes.avisar();
    return PedidoPublicado.fromJson(data);
  }

  /// "Pedir de novo": grava as alterações no rascunho (PATCH, que também
  /// muda a zona) e publica-o.
  Future<PedidoPublicado> _publicarRascunho(
    String id,
    NovoPedido novoPedido,
  ) async {
    await _api.patch('/pedidos/$id', novoPedido.paraEditar());
    final data = _mapa(await _api.post('/pedidos/$id/publicar'));
    _alteracoes.avisar();
    final publicado = await pedido(id);
    if (publicado == null) throw const NaoEncontradoException();
    return PedidoPublicado(
      pedido: publicado,
      profissionaisAvisados: JsonLeitura.inteiro(
        data['profissionais_avisados'],
      ),
      categoriaPlural: 'profissionais',
    );
  }

  // --------------------------------------------- 12 · 13 · Registo profissional

  @override
  Future<RegistoProfissional?> rascunhoRegistoProfissional() async =>
      RegistoProfissional.doUtilizadorJson(_mapa(await _api.get('/eu')));

  @override
  Future<void> guardarRegistoProfissional(RegistoProfissional registo) async {
    final data = JsonLeitura.mapa(
      await _api.put('/profissionais/eu', registo.toJson()),
    );
    _lerPerfil(data['perfil_ativo'] ?? PerfilUtilizador.profissional.name);
    _alteracoes.avisar();
  }

  @override
  Future<VerificacaoIdentidade> verificacaoIdentidade() async =>
      VerificacaoIdentidade.fromJson(
        _mapa(await _api.get('/profissionais/eu/verificacao')),
      );

  @override
  Future<void> adicionarDocumento() =>
      _api.put('/profissionais/eu/verificacao/documento', const {});

  @override
  Future<void> adicionarFotoRosto() =>
      _api.put('/profissionais/eu/verificacao/rosto', const {});

  @override
  Future<void> enviarParaVerificacao() =>
      _api.post('/profissionais/eu/verificacao/enviar');

  // ------------------------------------------------ 14 · Início profissional

  @override
  Future<PainelProfissional> painelProfissional() async =>
      PainelProfissional.fromJson(
        _mapa(await _api.get('/profissionais/eu/painel')),
      );

  @override
  Future<void> definirDisponibilidade(bool disponivel) =>
      _api.put('/profissionais/eu', {'disponivel': disponivel});

  // ------------------------------------------------------ 15 · Enviar proposta

  @override
  Future<PedidoPerto?> pedidoPerto(String id) async =>
      _idValido(id) ? _obterOuNull('/pedidos/$id', PedidoPerto.fromJson) : null;

  @override
  Future<NovaProposta?> rascunhoProposta(String pedidoId) async => null;

  @override
  Future<void> enviarProposta(NovaProposta proposta) async {
    if (!_idValido(proposta.pedidoId)) throw const NaoEncontradoException();
    await _api.post(
      '/pedidos/${proposta.pedidoId}/propostas',
      proposta.toJson(),
    );
    _alteracoes.avisar();
  }

  // ------------------------------------------------------- 16 · 17 · Ler QR

  @override
  Future<TrabalhoPorConfirmar?> trabalhoPorConfirmar() =>
      _obterOuNull('/pedidos/por-confirmar', TrabalhoPorConfirmar.fromJson);

  @override
  Future<List<TrabalhoPorConfirmar>> trabalhosPorConfirmar() =>
      _lista('/pedidos/por-confirmar/lista', TrabalhoPorConfirmar.fromJson);

  @override
  Future<void> mudarEtapaServico(String pedidoId, EtapaServico etapa) async {
    if (!_idValido(pedidoId)) throw const NaoEncontradoException();
    if (etapa == EtapaServico.aceite) {
      throw const ValidacaoException('Esta etapa não se escolhe à mão.');
    }
    await _api.patch('/pedidos/$pedidoId/estado', {'estado': etapa.chave});
    _alteracoes.avisar();
  }

  /// Em debug, o código fixo dos dados de exemplo (`CODIGO_QR_FIXO_DEV`).
  @override
  Future<String?> codigoClientePredefinido() async =>
      kDebugMode ? _codigoQrExemplo : null;

  /// `POST /pedidos/confirmar`: a API descobre, pelo código, qual dos
  /// trabalhos ativos do profissional se confirma (QA-03).
  @override
  Future<ServicoConfirmado> confirmarServicoComCodigo(String codigo) async {
    final data = _mapa(
      await _api.post('/pedidos/confirmar', {
        'codigo': codigo.replaceAll(RegExp(r'\s+'), ''),
        // O ecrã 16 não pergunta o meio de pagamento (RF14).
        'metodo_pagamento': MeioPagamento.dinheiro.chave,
      }),
    );
    _alteracoes.avisar();
    return ServicoConfirmado.fromJson(data);
  }

  @override
  Future<ServicoConfirmado?> servicoConfirmado(String pedidoId) async =>
      _idValido(pedidoId)
      ? _obterOuNull(
          '/pedidos/$pedidoId/comprovativo',
          ServicoConfirmado.fromJson,
        )
      : null;

  // -------------------------------------------------------- 18 · 19 · Conversas

  @override
  Future<List<Conversa>> conversas() => _lista('/conversas', Conversa.fromJson);

  @override
  Future<Conversa?> conversa(String id) async =>
      _idValido(id) ? _obterOuNull('/conversas/$id', Conversa.fromJson) : null;

  @override
  Future<Mensagem> enviarMensagem(String conversaId, String texto) async {
    if (!_idValido(conversaId)) throw const NaoEncontradoException();
    final data = _mapa(
      await _api.post('/conversas/$conversaId/mensagens', {
        'texto': texto.trim(),
      }),
    );
    _alteracoes.avisar();
    return Mensagem.fromJson(data);
  }

  @override
  Future<void> marcarConversaLida(String conversaId) async {
    if (!_idValido(conversaId)) return;
    await _api.post('/conversas/$conversaId/lida');
    _alteracoes.avisar();
  }

  // ------------------------------------------------- Notificações e Ajuda

  @override
  Future<CaixaNotificacoes> notificacoes() async => CaixaNotificacoes.fromJson(
    _mapa(await _api.get('/notificacoes', query: {'limit': '50'})),
  );

  @override
  Future<int> notificacoesPorLer() async {
    final data = _mapa(
      await _api.get(
        '/notificacoes',
        query: {'so_nao_lidas': 'true', 'limit': '1'},
      ),
    );
    return JsonLeitura.inteiro(data['nao_lidas']);
  }

  @override
  Future<void> marcarNotificacoesLidas() async {
    await _api.post('/notificacoes/lidas');
    _alteracoes.avisar();
  }

  @override
  Future<List<PerguntaAjuda>> perguntasAjuda() =>
      _lista('/ajuda/perguntas', PerguntaAjuda.fromJson);

  // ---------------------------------------------------------------- 22 · Mapa

  @override
  Future<List<PinMapa>> pinsMapa() =>
      _lista('/profissionais/mapa', PinMapa.fromJson, query: {'raio_km': '5'});
}
