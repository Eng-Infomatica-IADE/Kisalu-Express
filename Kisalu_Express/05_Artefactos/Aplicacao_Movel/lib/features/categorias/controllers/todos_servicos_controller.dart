import 'package:flutter/foundation.dart';

import '../../../core/state/estado_ui.dart';
import '../../../data/repositories/kisalu_repository.dart';
import '../../../models/categoria.dart';

/// Estado do ecrã 21 · Todos os serviços: as 13 categorias e a pesquisa
/// local (filtra no ecrã, sem pedir nada ao repositório).
class TodosServicosController extends ChangeNotifier {
  TodosServicosController(this._repositorio);

  final KisaluRepository _repositorio;
  bool _terminado = false;

  EstadoUi<List<Categoria>> estado = const Carregar();
  String termo = '';

  Future<void> carregar() async {
    _definir(() => estado = const Carregar());
    try {
      final categorias = await _repositorio.categorias();
      _definir(
        () => estado = categorias.isEmpty ? const Vazio() : Sucesso(categorias),
      );
    } on KisaluException catch (e) {
      _definir(() => estado = Erro(e.mensagem, semRede: e is SemRedeException));
    }
  }

  void pesquisar(String novo) {
    if (novo != termo) _definir(() => termo = novo);
  }

  /// Categorias cujo nome contém o termo, sem distinguir maiúsculas nem
  /// acentos ("mecanico" encontra "Mecânico"). Sem termo, todas.
  List<Categoria> get filtradas {
    final dados = switch (estado) {
      Sucesso(:final dados) => dados,
      _ => const <Categoria>[],
    };
    final procura = _normalizar(termo);
    if (procura.isEmpty) return dados;
    return dados.where((c) => _normalizar(c.nome).contains(procura)).toList();
  }

  static const _acentos = {
    'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'é': 'e', 'ê': 'e', 'í': 'i',
    'ó': 'o', 'ô': 'o', 'õ': 'o', 'ú': 'u', 'ç': 'c', //
  };

  static String _normalizar(String texto) {
    final minusculas = texto.trim().toLowerCase();
    final buffer = StringBuffer();
    for (final letra in minusculas.split('')) {
      buffer.write(_acentos[letra] ?? letra);
    }
    return buffer.toString();
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
