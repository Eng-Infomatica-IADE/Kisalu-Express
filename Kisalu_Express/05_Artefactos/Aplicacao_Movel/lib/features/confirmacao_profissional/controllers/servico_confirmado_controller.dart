import 'package:flutter/foundation.dart';

import '../../../core/state/estado_ui.dart';
import '../../../data/repositories/kisalu_repository.dart';
import '../../../models/servico_confirmado.dart';

/// Dados do ecrã 17 já prontos a desenhar.
class ServicoConfirmadoDados {
  const ServicoConfirmadoDados({required this.servico, required this.agora});

  final ServicoConfirmado servico;

  /// Relógio do repositório, para "Hoje, 15:52".
  final DateTime agora;
}

/// Estado do ecrã 17 · Serviço confirmado (profissional).
class ServicoConfirmadoController extends ChangeNotifier {
  ServicoConfirmadoController(this._repositorio, this.pedidoId);

  final KisaluRepository _repositorio;
  final String pedidoId;
  bool _terminado = false;

  EstadoUi<ServicoConfirmadoDados> estado = const Carregar();

  Future<void> carregar() async {
    _definir(const Carregar());
    try {
      final servico = await _repositorio.servicoConfirmado(pedidoId);
      _definir(
        servico == null
            ? const Erro(
                'Este serviço já não está disponível.',
                naoEncontrado: true,
              )
            : Sucesso(
                ServicoConfirmadoDados(
                  servico: servico,
                  agora: _repositorio.agora(),
                ),
              ),
      );
    } on KisaluException catch (e) {
      _definir(
        Erro(
          e.mensagem,
          semRede: e is SemRedeException,
          naoEncontrado: e is NaoEncontradoException,
        ),
      );
    }
  }

  void _definir(EstadoUi<ServicoConfirmadoDados> novo) {
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
