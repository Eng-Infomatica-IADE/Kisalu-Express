import 'package:flutter/foundation.dart';

import '../../../core/state/estado_ui.dart';
import '../../../core/validators/k_validators.dart';
import '../../../data/repositories/kisalu_repository.dart';
import '../../../models/avaliacao.dart';
import '../../../models/comprovativo.dart';

/// Estado do ecrã 06 · Avaliação do serviço.
class AvaliarServicoController extends ChangeNotifier {
  AvaliarServicoController(this._repositorio, this.pedidoId);

  final KisaluRepository _repositorio;
  final String pedidoId;
  bool _terminado = false;

  EstadoUi<Comprovativo> estado = const Carregar();

  int estrelas = 0;
  final Set<EtiquetaAvaliacao> etiquetas = {};
  String comentario = '';

  String? erroEstrelas;
  String? erroComentario;
  String? erroEnvio;
  bool aEnviar = false;

  /// "Muito bom" para 4; vazio sem escolha.
  String get rotuloEstrelas => EscalaAvaliacao.rotulo(estrelas);

  Future<void> carregar() async {
    _definir(const Carregar());
    try {
      final comprovativo = await _repositorio.comprovativo(pedidoId);
      if (comprovativo == null) {
        return _definir(
          const Erro(
            'Não encontrámos este pedido. Veja os seus pedidos.',
            naoEncontrado: true,
          ),
        );
      }
      final rascunho = await _repositorio.rascunhoAvaliacao(pedidoId);
      if (rascunho != null) {
        estrelas = rascunho.estrelas;
        etiquetas
          ..clear()
          ..addAll(rascunho.etiquetas);
        comentario = rascunho.comentario;
      }
      _definir(Sucesso(comprovativo));
    } on KisaluException catch (e) {
      _definir(Erro(e.mensagem, semRede: e is SemRedeException));
    }
  }

  void definirEstrelas(int valor) {
    estrelas = valor;
    erroEstrelas = null;
    erroEnvio = null;
    notifyListeners();
  }

  void alternarEtiqueta(EtiquetaAvaliacao etiqueta) {
    if (!etiquetas.remove(etiqueta)) etiquetas.add(etiqueta);
    notifyListeners();
  }

  void alterarComentario(String valor) {
    comentario = valor;
    if (erroComentario != null || erroEnvio != null) {
      erroComentario = null;
      erroEnvio = null;
    }
    notifyListeners();
  }

  /// "Enviar avaliação": true se foi enviada.
  Future<bool> enviar() async {
    if (aEnviar || estado is! Sucesso<Comprovativo>) return false;
    erroEstrelas = KValidators.estrelas(estrelas == 0 ? null : estrelas);
    erroComentario = KValidators.comentario(comentario);
    erroEnvio = null;
    if (erroEstrelas != null || erroComentario != null) {
      notifyListeners();
      return false;
    }
    aEnviar = true;
    notifyListeners();
    try {
      await _repositorio.enviarAvaliacao(
        pedidoId,
        NovaAvaliacao(
          estrelas: estrelas,
          etiquetas: etiquetas.toList(),
          comentario: comentario.trim(),
        ),
      );
      return true;
    } on KisaluException catch (e) {
      erroEnvio = e.mensagem;
      return false;
    } finally {
      aEnviar = false;
      if (!_terminado) notifyListeners();
    }
  }

  void _definir(EstadoUi<Comprovativo> novo) {
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
