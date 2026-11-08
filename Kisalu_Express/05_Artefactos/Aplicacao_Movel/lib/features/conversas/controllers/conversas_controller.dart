import 'package:flutter/foundation.dart';

import '../../../core/state/estado_ui.dart';
import '../../../data/repositories/kisalu_repository.dart';
import '../../../models/conversa.dart';

/// Dados do ecrã 18 já prontos a desenhar.
class ConversasDados {
  const ConversasDados({required this.conversas, required this.agora});

  /// Mais recentes primeiro.
  final List<Conversa> conversas;

  /// Relógio do repositório: "15:02" se for hoje, senão "24 set".
  final DateTime agora;
}

/// Estado do separador Conversas (ecrã 18). Volta a ler sempre que o
/// repositório avisa de uma mudança (mensagem enviada ou lida).
class ConversasController extends ChangeNotifier {
  ConversasController(this._repositorio) {
    _repositorio.alteracoes.addListener(_aoMudar);
  }

  final KisaluRepository _repositorio;
  bool _terminado = false;

  EstadoUi<ConversasDados> estado = const Carregar();

  Future<void> carregar() async {
    _definir(const Carregar());
    await _ler();
  }

  /// Releitura silenciosa: não volta a mostrar esqueletos.
  void _aoMudar() => _ler();

  /// Pull-to-refresh e voltar ao separador.
  Future<void> recarregar() => _ler();

  Future<void> _ler() async {
    try {
      final conversas = await _repositorio.conversas();
      _definir(
        conversas.isEmpty
            ? const Vazio()
            : Sucesso(
                ConversasDados(
                  conversas: conversas,
                  agora: _repositorio.agora(),
                ),
              ),
      );
    } on KisaluException catch (e) {
      _definir(Erro(e.mensagem, semRede: e is SemRedeException));
    }
  }

  void _definir(EstadoUi<ConversasDados> novo) {
    if (_terminado) return;
    estado = novo;
    notifyListeners();
  }

  @override
  void dispose() {
    _repositorio.alteracoes.removeListener(_aoMudar);
    _terminado = true;
    super.dispose();
  }
}
