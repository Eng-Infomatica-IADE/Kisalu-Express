import 'package:flutter/foundation.dart';

import '../../../core/state/estado_ui.dart';
import '../../../data/repositories/kisalu_repository.dart';
import '../../../models/pergunta_ajuda.dart';

/// Estado da Ajuda (RF16): perguntas frequentes, também sem sessão.
class AjudaController extends ChangeNotifier {
  AjudaController(this._repositorio);

  final KisaluRepository _repositorio;
  bool _terminado = false;

  EstadoUi<List<PerguntaAjuda>> estado = const Carregar();

  Future<void> carregar() async {
    _definir(const Carregar());
    try {
      final perguntas = await _repositorio.perguntasAjuda();
      _definir(perguntas.isEmpty ? const Vazio() : Sucesso(perguntas));
    } on KisaluException catch (e) {
      _definir(Erro(e.mensagem, semRede: e is SemRedeException));
    }
  }

  void _definir(EstadoUi<List<PerguntaAjuda>> novo) {
    if (_terminado) return;
    estado = novo;
    notifyListeners();
  }

  @override
  void dispose() {
    _terminado = true;
    super.dispose();
  }
}
