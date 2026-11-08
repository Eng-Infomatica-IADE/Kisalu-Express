import 'package:flutter/foundation.dart';

import '../../data/repositories/kisalu_repository.dart';
import '../../models/resultado_reporte.dart';
import '../validators/k_validators.dart';

/// Estado da folha "Reportar problema" (RF11), usada no QR (05) e no
/// histórico (07). Um por abertura da folha.
class ReportarProblemaController extends ChangeNotifier {
  ReportarProblemaController(this._repositorio, this.pedidoId);

  final KisaluRepository _repositorio;
  final String pedidoId;
  bool _terminado = false;

  String? erro;
  bool aEnviar = false;

  /// Limpa o erro ao voltar a escrever (VALIDACOES.md).
  void aoEscrever() {
    if (erro == null) return;
    erro = null;
    notifyListeners();
  }

  /// Valida ao sair do campo; vazio não é erro até submeter.
  void aoSair(String descricao) {
    if (descricao.trim().isEmpty) return;
    erro = KValidators.reporteProblema(descricao);
    notifyListeners();
  }

  /// "Enviar": devolve a resposta da equipa, ou null se ficou na folha (o
  /// erro, incluindo o fim da garantia de 7 dias, fica em [erro]).
  Future<ResultadoReporte?> enviar(String descricao) async {
    if (aEnviar) return null;
    erro = KValidators.reporteProblema(descricao);
    if (erro != null) {
      notifyListeners();
      return null;
    }
    aEnviar = true;
    notifyListeners();
    try {
      return await _repositorio.reportarProblema(pedidoId, descricao.trim());
    } on KisaluException catch (e) {
      erro = e.mensagem;
      return null;
    } finally {
      aEnviar = false;
      if (!_terminado) notifyListeners();
    }
  }

  @override
  void dispose() {
    _terminado = true;
    super.dispose();
  }
}
