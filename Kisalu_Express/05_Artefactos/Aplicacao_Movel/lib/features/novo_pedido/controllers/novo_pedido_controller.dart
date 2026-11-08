import 'package:flutter/widgets.dart' show StringCharacters;
import 'package:flutter/foundation.dart';

import '../../../core/state/estado_ui.dart';
import '../../../core/validators/k_validators.dart';
import '../../../data/repositories/kisalu_repository.dart';
import '../../../models/categoria.dart';
import '../../../models/estado_pedido.dart';
import '../../../models/novo_pedido.dart';
import '../../../models/pedido.dart';

/// Passos do fluxo "Novo pedido". Só o [rever] tem desenho no Figma (ecrã
/// 10, "Passo 3 de 4"); a [data] (4) abre a partir do passo de rever.
enum PassoNovoPedido {
  descricao(1),
  morada(2),
  rever(3),
  data(4);

  const PassoNovoPedido(this.numero);

  final int numero;
}

/// De onde vem o formulário.
enum ModoNovoPedido {
  /// Pedido novo (com rascunho local, RM07).
  novo,

  /// 04 · "Editar pedido": grava com PATCH (não cria outro pedido).
  editar,

  /// 07 · "Pedir de novo": pré-preenchido a partir de um pedido antigo.
  pedirDeNovo,
}

/// Estado do fluxo "Novo pedido" (ecrãs 10 e passos 1, 2 e 4).
///
/// Só a UX é validada aqui (VALIDACOES.md); o servidor repete as regras. O
/// ponto de referência e a morada só seguem depois de aceitar (RNF10) e
/// nunca vão para logs.
class NovoPedidoController extends ChangeNotifier {
  NovoPedidoController(
    this._repo, {
    this.pausaTentativa = const Duration(seconds: 1),
  });

  final KisaluRepository _repo;

  /// Duração simulada de "Tentar outra vez" (spec: 1 s).
  final Duration pausaTentativa;

  static const minTitulo = 5;
  static const maxTitulo = 60;
  static const maxFotos = 5;

  EstadoUi<NovoPedido> estado = const Carregar();
  PassoNovoPedido passo = PassoNovoPedido.descricao;
  List<Categoria> categorias = const [];

  // Campos
  String? categoriaId;
  String titulo = '';
  String descricao = '';
  int numFotos = 0;
  String zona = '';
  String pontoReferencia = '';
  DateTime? quando;

  // Erros
  String? erroCategoria;
  String? erroTitulo;
  String? erroDescricao;
  String? erroZona;
  String? erroPonto;
  String? erroData;

  ModoNovoPedido modo = ModoNovoPedido.novo;

  /// Pedido a editar ([ModoNovoPedido.editar]).
  String? pedidoId;

  /// Rascunho do servidor criado por "Pedir de novo".
  String? _rascunhoId;

  /// Pedido gravado por "Guardar alterações".
  Pedido? editado;

  // Rede e publicação
  bool semRede = false;
  bool aTentar = false;
  bool aPublicar = false;
  String? erroPublicacao;
  PedidoPublicado? publicado;

  bool _viaPassos = false;
  bool _descartado = false;

  DateTime get agora => _repo.agora();

  /// Há o passo de rever com rascunho (abre como no Figma) ou o fluxo
  /// percorre-se do início; neste caso a data pode ser alterada.
  bool get dataEditavel => _viaPassos;

  /// Há um passo anterior dentro do fluxo (senão, voltar faz `pop`).
  bool get temPassoAnterior => switch (passo) {
    PassoNovoPedido.descricao => false,
    PassoNovoPedido.rever => _viaPassos,
    _ => true,
  };

  /// "o mais cedo possível" quando não há data escolhida.
  bool get maisCedo => quando == null;

  @override
  void notifyListeners() {
    if (!_descartado) super.notifyListeners();
  }

  @override
  void dispose() {
    _descartado = true;
    super.dispose();
  }

  /// Carrega categorias, rascunho e estado da rede. Com rascunho abre no
  /// passo de rever (ecrã 10); sem rascunho, no passo 1. [passoInicial] força
  /// o passo e ignora o rascunho (fluxo novo).
  ///
  /// Com [editarId] abre o pedido para editar; com [deId] começa um pedido
  /// novo igual a esse ("Pedir de novo"). Nos dois casos percorre-se o fluxo
  /// desde o passo 1, já preenchido.
  Future<void> carregar({
    PassoNovoPedido? passoInicial,
    String? editarId,
    String? deId,
  }) async {
    estado = const Carregar();
    notifyListeners();
    try {
      categorias = await _repo.categorias();
      if (editarId != null) {
        final p = await _repo.pedido(editarId);
        if (p == null) {
          estado = const Erro(
            'Não encontrámos este pedido. Veja os seus pedidos.',
            naoEncontrado: true,
          );
          notifyListeners();
          return;
        }
        if (p.estado != EstadoPedido.novo || p.propostaAceitaId != null) {
          estado = const Erro(
            'Este pedido já tem uma proposta aceite e não pode ser editado.',
          );
          notifyListeners();
          return;
        }
        modo = ModoNovoPedido.editar;
        pedidoId = p.id;
        _preencher(
          NovoPedido(
            categoriaId: p.categoriaId,
            titulo: p.titulo,
            descricao: p.descricao,
            zona: p.zona,
            pontoReferencia: p.pontoReferencia ?? '',
            quando: p.quando,
            numFotos: p.numFotos,
          ),
        );
      } else if (deId != null) {
        final base = await _repo.pedirDeNovo(deId);
        modo = ModoNovoPedido.pedirDeNovo;
        _rascunhoId = base.rascunhoId;
        _preencher(base);
      }
      final rascunho = passoInicial == null && modo == ModoNovoPedido.novo
          ? await _repo.rascunhoPedido()
          : null;
      if (rascunho != null) _preencher(rascunho);
      passo =
          passoInicial ??
          (rascunho == null
              ? PassoNovoPedido.descricao
              : PassoNovoPedido.rever);
      _viaPassos = rascunho == null;
      try {
        await _repo.verificarLigacao();
        semRede = false;
      } on SemRedeException {
        semRede = true;
      }
      estado = Sucesso(_montar());
    } on KisaluException catch (e) {
      estado = Erro(e.mensagem, semRede: e is SemRedeException);
    }
    notifyListeners();
  }

  void _preencher(NovoPedido n) {
    categoriaId = n.categoriaId.isEmpty ? null : n.categoriaId;
    titulo = n.titulo;
    descricao = n.descricao;
    zona = n.zona;
    pontoReferencia = n.pontoReferencia;
    quando = n.quando;
    numFotos = n.numFotos;
  }

  /// Guarda o que já foi escrito (só pedidos novos). Uma falha aqui não
  /// impede de continuar.
  Future<void> _guardarRascunho() async {
    if (modo != ModoNovoPedido.novo) return;
    try {
      await _repo.guardarRascunhoPedido(_montar());
    } on KisaluException {
      // O rascunho é uma ajuda; o fluxo continua.
    }
  }

  NovoPedido _montar() => NovoPedido(
    categoriaId: categoriaId ?? '',
    titulo: titulo.trim(),
    descricao: descricao.trim(),
    zona: zona.trim(),
    pontoReferencia: pontoReferencia.trim(),
    quando: quando,
    numFotos: numFotos,
    rascunhoId: _rascunhoId,
  );

  // ------------------------------------------------------------ passo 1

  void escolherCategoria(String id) {
    categoriaId = id;
    erroCategoria = null;
    notifyListeners();
  }

  void aoEscreverTitulo(String v) {
    titulo = v;
    if (erroTitulo != null) {
      erroTitulo = null;
      notifyListeners();
    }
  }

  void aoSairTitulo() {
    if (titulo.trim().isEmpty) return;
    erroTitulo = _validarTitulo();
    notifyListeners();
  }

  void aoEscreverDescricao(String v) {
    descricao = v;
    if (erroDescricao != null) {
      erroDescricao = null;
      notifyListeners();
    }
  }

  void aoSairDescricao() {
    if (descricao.trim().isEmpty) return;
    erroDescricao = KValidators.descricaoPedido(descricao);
    notifyListeners();
  }

  /// Foto opcional (RM04). Sem seletor de imagens nesta fase: conta-se.
  void adicionarFoto() {
    if (numFotos >= maxFotos) return;
    numFotos++;
    notifyListeners();
  }

  void removerFoto() {
    if (numFotos == 0) return;
    numFotos--;
    notifyListeners();
  }

  String? _validarTitulo() {
    final n = titulo.trim().characters.length;
    return n < minTitulo || n > maxTitulo
        ? 'Dê um título curto ao pedido. Exemplo: Fuga de água na cozinha.'
        : null;
  }

  bool _validarPasso1() {
    erroCategoria = categoriaId == null ? 'Escolha o tipo de serviço.' : null;
    erroTitulo = _validarTitulo();
    erroDescricao = KValidators.descricaoPedido(descricao);
    return erroCategoria == null && erroTitulo == null && erroDescricao == null;
  }

  // ------------------------------------------------------------ passo 2

  void aoEscreverZona(String v) {
    zona = v;
    if (erroZona != null) {
      erroZona = null;
      notifyListeners();
    }
  }

  void aoEscreverPonto(String v) {
    pontoReferencia = v;
    if (erroPonto != null) {
      erroPonto = null;
      notifyListeners();
    }
  }

  void aoSairPonto() {
    if (pontoReferencia.trim().isEmpty) return;
    erroPonto = KValidators.pontoReferencia(pontoReferencia);
    notifyListeners();
  }

  bool _validarPasso2() {
    erroZona = zona.trim().isEmpty
        ? 'Diga-nos a zona onde precisa do serviço.'
        : null;
    erroPonto = KValidators.pontoReferencia(pontoReferencia);
    return erroZona == null && erroPonto == null;
  }

  // ------------------------------------------------------------ passo 4

  void escolherMaisCedo() {
    quando = null;
    erroData = null;
    notifyListeners();
  }

  void escolherData(DateTime data) {
    quando = data;
    erroData = KValidators.dataPedido(data, agora: agora);
    notifyListeners();
  }

  bool _validarData() {
    erroData = KValidators.dataPedido(quando, agora: agora, semData: true);
    return erroData == null;
  }

  // ---------------------------------------------------------- navegação

  /// Valida o passo atual e avança. Devolve true se avançou.
  bool avancar() {
    final ok = switch (passo) {
      PassoNovoPedido.descricao => _validarPasso1(),
      PassoNovoPedido.morada => _validarPasso2(),
      PassoNovoPedido.data => _validarData(),
      PassoNovoPedido.rever => false,
    };
    if (ok) {
      passo = switch (passo) {
        PassoNovoPedido.descricao => PassoNovoPedido.morada,
        PassoNovoPedido.morada => PassoNovoPedido.rever,
        _ => PassoNovoPedido.rever, // data → rever
      };
      _guardarRascunho();
    }
    notifyListeners();
    return ok;
  }

  void alterarData() {
    passo = PassoNovoPedido.data;
    notifyListeners();
  }

  /// Volta um passo. Devolve false se não há passo anterior (a view faz `pop`).
  bool voltar() {
    switch (passo) {
      case PassoNovoPedido.descricao:
        return false;
      case PassoNovoPedido.morada:
        passo = PassoNovoPedido.descricao;
      case PassoNovoPedido.rever:
        if (!_viaPassos) return false;
        passo = PassoNovoPedido.morada;
      case PassoNovoPedido.data:
        passo = PassoNovoPedido.rever;
    }
    notifyListeners();
    return true;
  }

  // --------------------------------------------------------- publicação

  /// "Tentar outra vez": simula uma verificação de ligação (1 s).
  Future<void> tentarOutraVez() async {
    if (aTentar) return;
    aTentar = true;
    notifyListeners();
    try {
      if (pausaTentativa > Duration.zero) {
        await Future<void>.delayed(pausaTentativa);
      }
      await _repo.verificarLigacao();
      semRede = false;
    } on SemRedeException {
      semRede = true;
    } on KisaluException catch (e) {
      erroPublicacao = e.mensagem;
    } finally {
      aTentar = false;
      notifyListeners();
    }
  }

  /// "Publicar pedido" (ou "Guardar alterações" a editar). Devolve true se
  /// correu bem ([publicado] ou [editado] preenchido).
  Future<bool> publicar() async {
    if (aPublicar || semRede) return false;
    // Revalida tudo: um rascunho pode ser reaberto dias depois.
    if (!_validarPasso2()) {
      passo = PassoNovoPedido.morada;
      notifyListeners();
      return false;
    }
    if (!_validarPasso1()) {
      passo = PassoNovoPedido.descricao;
      notifyListeners();
      return false;
    }
    if (!_validarData()) {
      passo = PassoNovoPedido.data;
      notifyListeners();
      return false;
    }
    aPublicar = true;
    erroPublicacao = null;
    notifyListeners();
    try {
      final id = pedidoId;
      if (modo == ModoNovoPedido.editar && id != null) {
        editado = await _repo.editarPedido(id, _montar());
        return true;
      }
      publicado = await _repo.publicarPedido(_montar());
      if (modo == ModoNovoPedido.novo) {
        try {
          await _repo.apagarRascunhoPedido();
        } on KisaluException {
          // Fica um rascunho antigo; não impede a publicação.
        }
      }
      return true;
    } on SemRedeException {
      semRede = true;
      await _guardarRascunho();
      return false;
    } on KisaluException catch (e) {
      erroPublicacao = e.mensagem;
      return false;
    } finally {
      aPublicar = false;
      notifyListeners();
    }
  }
}
