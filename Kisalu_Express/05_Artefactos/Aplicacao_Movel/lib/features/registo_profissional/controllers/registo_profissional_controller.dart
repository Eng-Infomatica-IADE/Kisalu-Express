import 'package:flutter/foundation.dart';

import '../../../core/state/estado_ui.dart';
import '../../../core/validators/k_validators.dart';
import '../../../data/repositories/kisalu_repository.dart';
import '../../../models/categoria.dart';
import '../../../models/registo_profissional.dart';

/// Dados do ecrã 12 prontos a desenhar.
class RegistoDados {
  const RegistoDados({required this.categorias, required this.rascunho});

  final List<Categoria> categorias;

  /// Valores com que o formulário arranca; null → vazio.
  final RegistoProfissional? rascunho;
}

/// Estado do ecrã 12 · Criar perfil (passo 1 de 3).
class RegistoProfissionalController extends ChangeNotifier {
  RegistoProfissionalController(this._repositorio);

  /// Raio de deslocação permitido, em km.
  static const raioMinimo = 1;
  static const raioMaximo = 30;

  /// Serviços mostrados antes de "Mais…" (os restantes abrem com ele).
  static const _iniciais = [
    CategoriaId.canalizador,
    CategoriaId.pedreiro,
    CategoriaId.eletricista,
    CategoriaId.pintor,
  ];

  final KisaluRepository _repositorio;
  bool _terminado = false;

  EstadoUi<RegistoDados> estado = const Carregar();
  final Set<String> escolhidos = {};
  int raioKm = 10;
  bool mostrarTodos = false;
  bool aGuardar = false;

  String? erroNome;
  String? erroServicos;
  String? erroAnos;
  String? erroZona;
  String? erroGeral;

  Future<void> carregar() async {
    _definir(() => estado = const Carregar());
    try {
      final categorias = await _repositorio.categorias();
      final rascunho = await _repositorio.rascunhoRegistoProfissional();
      _definir(() {
        escolhidos
          ..clear()
          ..addAll(rascunho?.categoriaIds ?? const []);
        raioKm = rascunho?.raioKm ?? raioKm;
        estado = categorias.isEmpty
            ? const Vazio()
            : Sucesso(RegistoDados(categorias: categorias, rascunho: rascunho));
      });
    } on KisaluException catch (e) {
      _definir(() => estado = Erro(e.mensagem, semRede: e is SemRedeException));
    }
  }

  /// Serviços visíveis: os iniciais ou, depois de "Mais…", todos (por ordem
  /// do catálogo).
  List<Categoria> visiveis(List<Categoria> todas) {
    if (mostrarTodos) return todas;
    return [for (final id in _iniciais) ...todas.where((c) => c.id == id)];
  }

  void alternarServico(String id) {
    _definir(() {
      if (!escolhidos.remove(id)) escolhidos.add(id);
      erroServicos = null;
    });
  }

  void mostrarMais() => _definir(() => mostrarTodos = true);

  void mudarRaio(double valor) {
    final novo = valor.round().clamp(raioMinimo, raioMaximo);
    if (novo != raioKm) _definir(() => raioKm = novo);
  }

  void aoEscrever() {
    if (erroNome != null ||
        erroAnos != null ||
        erroZona != null ||
        erroGeral != null) {
      _definir(() {
        erroNome = null;
        erroAnos = null;
        erroZona = null;
        erroGeral = null;
      });
    }
  }

  /// Ao sair do campo: vazio não é erro até "Continuar".
  void validarNomeAoSair(String valor) {
    if (valor.trim().isEmpty) return;
    _definir(() => erroNome = KValidators.nomeCompleto(valor));
  }

  void validarAnosAoSair(String valor) {
    if (valor.trim().isEmpty) return;
    _definir(() => erroAnos = KValidators.anosExperiencia(valor));
  }

  void validarZonaAoSair(String valor) {
    if (valor.trim().isEmpty) return;
    _definir(() => erroZona = KValidators.zonaAtuacao(valor));
  }

  /// "Continuar": valida tudo e guarda. Devolve true se pode avançar.
  Future<bool> continuar({
    required String nome,
    required String anos,
    required String zona,
  }) async {
    if (aGuardar) return false;
    final nomeErro = KValidators.nomeCompleto(nome);
    final servicosErro = KValidators.servicosPrestados(escolhidos.toList());
    final anosErro = KValidators.anosExperiencia(anos);
    final zonaErro = KValidators.zonaAtuacao(zona);
    if (nomeErro != null ||
        servicosErro != null ||
        anosErro != null ||
        zonaErro != null) {
      _definir(() {
        erroNome = nomeErro;
        erroServicos = servicosErro;
        erroAnos = anosErro;
        erroZona = zonaErro;
      });
      return false;
    }
    _definir(() {
      aGuardar = true;
      erroGeral = null;
    });
    try {
      await _repositorio.guardarRegistoProfissional(
        RegistoProfissional(
          nomeCompleto: nome.trim(),
          categoriaIds: escolhidos.toList(),
          anosExperiencia: int.parse(anos.trim()),
          zona: zona.trim(),
          raioKm: raioKm,
        ),
      );
      _definir(() => aGuardar = false);
      return true;
    } on KisaluException catch (e) {
      _definir(() {
        aGuardar = false;
        erroGeral = e.mensagem;
      });
      return false;
    }
  }

  void _definir(VoidCallback alterar) {
    if (_terminado) return;
    alterar();
    notifyListeners();
  }

  @override
  void dispose() {
    _terminado = true;
    super.dispose();
  }
}
