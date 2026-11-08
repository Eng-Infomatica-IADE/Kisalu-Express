import 'package:flutter/foundation.dart';

import '../../../core/state/estado_ui.dart';
import '../../../core/validators/k_validators.dart';
import '../../../data/repositories/kisalu_repository.dart';
import '../../../models/conversa.dart';

/// Estado do ecrã 19 · Conversa do pedido. As mensagens enviadas ficam só em
/// memória (mock); o limite é o de VALIDACOES.md (1 a 1.000 caracteres).
class ConversaController extends ChangeNotifier {
  ConversaController(this._repositorio, this.conversaId);

  final KisaluRepository _repositorio;
  final String conversaId;
  bool _terminado = false;

  EstadoUi<Conversa> estado = const Carregar();
  bool aEnviar = false;

  /// Falha ao enviar (a mensagem do catálogo, nunca a do servidor em bruto).
  String? erro;

  /// Relógio do repositório (hora das mensagens).
  DateTime get agora => _repositorio.agora();

  Future<void> carregar() async {
    _definir(() => estado = const Carregar());
    try {
      final conversa = await _repositorio.conversa(conversaId);
      if (conversa == null) {
        return _definir(
          () => estado = const Erro(
            'Esta conversa já não está disponível.',
            naoEncontrado: true,
          ),
        );
      }
      _definir(() => estado = Sucesso(conversa));
      if (conversa.naoLidas > 0) {
        await _repositorio.marcarConversaLida(conversaId);
      }
    } on KisaluException catch (e) {
      _definir(
        () => estado = Erro(
          e.mensagem,
          semRede: e is SemRedeException,
          naoEncontrado: e is NaoEncontradoException,
        ),
      );
    }
  }

  /// Envia a mensagem. Texto vazio (ou só espaços) não envia e não é erro.
  /// Devolve true se a mensagem foi acrescentada à conversa.
  Future<bool> enviar(String texto) async {
    final limpo = texto.trim();
    if (limpo.isEmpty || aEnviar || estado is! Sucesso<Conversa>) return false;
    final invalido = KValidators.mensagemChat(limpo);
    if (invalido != null) {
      _definir(() => erro = invalido);
      return false;
    }
    _definir(() {
      aEnviar = true;
      erro = null;
    });
    try {
      await _repositorio.enviarMensagem(conversaId, limpo);
      final atualizada = await _repositorio.conversa(conversaId);
      _definir(() {
        aEnviar = false;
        if (atualizada != null) estado = Sucesso(atualizada);
      });
      return true;
    } on KisaluException catch (e) {
      _definir(() {
        aEnviar = false;
        erro = e.mensagem;
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
