import 'package:flutter/foundation.dart';

import '../../../core/state/estado_ui.dart';
import '../../../data/repositories/kisalu_repository.dart';
import '../../../models/notificacao.dart';

/// Estado da lista de notificações (sino dos ecrãs 02 e 14, Perfil). Ao
/// abrir, as que estavam por ler continuam marcadas como "Nova" no ecrã,
/// mas passam a lidas na API (o ponto do sino desaparece).
class NotificacoesController extends ChangeNotifier {
  NotificacoesController(this._repositorio);

  final KisaluRepository _repositorio;
  bool _terminado = false;

  EstadoUi<List<Notificacao>> estado = const Carregar();

  /// Relógio do repositório ("Hoje", "24 set").
  DateTime get agora => _repositorio.agora();

  Future<void> carregar() async {
    _definir(const Carregar());
    await recarregar();
  }

  Future<void> recarregar() async {
    try {
      final caixa = await _repositorio.notificacoes();
      _definir(caixa.lista.isEmpty ? const Vazio() : Sucesso(caixa.lista));
      if (caixa.naoLidas > 0) await _repositorio.marcarNotificacoesLidas();
    } on KisaluException catch (e) {
      _definir(Erro(e.mensagem, semRede: e is SemRedeException));
    }
  }

  void _definir(EstadoUi<List<Notificacao>> novo) {
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
