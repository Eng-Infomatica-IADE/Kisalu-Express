import 'package:flutter/foundation.dart';

import '../../../data/repositories/kisalu_repository.dart';
import '../../../models/pedido.dart';
import '../../../models/proposta.dart';

/// Estado da folha 08 "Confirmar a proposta?". Só envia ids ao repositório:
/// o valor fechado é o do servidor, nunca um valor do cliente (RNF08).
class ConfirmarPropostaController extends ChangeNotifier {
  ConfirmarPropostaController(this._repo, this.pedidoId, this.proposta);

  final KisaluRepository _repo;
  final String pedidoId;
  final Proposta proposta;

  bool aConfirmar = false;
  String? erro;

  DateTime get agora => _repo.agora();

  /// Devolve o pedido já em curso, ou null se falhou (ver [erro]).
  Future<Pedido?> confirmar() async {
    if (aConfirmar) return null;
    aConfirmar = true;
    erro = null;
    notifyListeners();
    try {
      final pedido = await _repo.aceitarProposta(pedidoId, proposta.id);
      aConfirmar = false;
      notifyListeners();
      return pedido;
    } on KisaluException catch (e) {
      erro = e.mensagem;
      aConfirmar = false;
      notifyListeners();
      return null;
    }
  }
}
