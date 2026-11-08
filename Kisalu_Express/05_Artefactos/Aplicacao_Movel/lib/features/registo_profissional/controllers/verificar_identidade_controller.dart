import 'package:flutter/foundation.dart';

import '../../../core/state/estado_ui.dart';
import '../../../data/repositories/kisalu_repository.dart';
import '../../../models/verificacao_identidade.dart';

/// Estado do ecrã 13 · Verificar identidade (passo 2 de 2). As fotografias
/// são simuladas: nada é lido da câmara nem enviado.
class VerificarIdentidadeController extends ChangeNotifier {
  VerificarIdentidadeController(this._repositorio);

  final KisaluRepository _repositorio;
  bool _terminado = false;

  EstadoUi<VerificacaoIdentidade> estado = const Carregar();
  bool aEnviar = false;
  bool aAdicionar = false;

  /// Mensagem da última falha de "Enviar para verificação".
  String? erro;

  Future<void> carregar() async {
    _definir(() => estado = const Carregar());
    try {
      final verificacao = await _repositorio.verificacaoIdentidade();
      _definir(() => estado = Sucesso(verificacao));
    } on KisaluException catch (e) {
      _definir(() => estado = Erro(e.mensagem, semRede: e is SemRedeException));
    }
  }

  /// "Alterar" (ou adicionar) o documento de identidade: simula a captura.
  /// true se ficou guardado.
  Future<bool> adicionarDocumento() async {
    if (estado is! Sucesso<VerificacaoIdentidade> || aAdicionar) return false;
    _definir(() => aAdicionar = true);
    try {
      await _repositorio.adicionarDocumento();
      final nova = await _repositorio.verificacaoIdentidade();
      _definir(() {
        aAdicionar = false;
        erro = null;
        estado = Sucesso(nova);
      });
      return true;
    } on KisaluException catch (e) {
      _definir(() {
        aAdicionar = false;
        erro = e.mensagem;
      });
      return false;
    }
  }

  /// Toque na linha "Fotografia do rosto": simula a captura.
  Future<void> adicionarFotoRosto() async {
    final atual = estado;
    if (atual is! Sucesso<VerificacaoIdentidade> ||
        atual.dados.rostoEnviado ||
        aAdicionar) {
      return;
    }
    _definir(() => aAdicionar = true);
    try {
      await _repositorio.adicionarFotoRosto();
      final nova = await _repositorio.verificacaoIdentidade();
      _definir(() {
        aAdicionar = false;
        erro = null;
        estado = Sucesso(nova);
      });
    } on KisaluException catch (e) {
      _definir(() {
        aAdicionar = false;
        erro = e.mensagem;
      });
    }
  }

  /// "Enviar para verificação": true se foi aceite e se pode ir para o Início.
  Future<bool> enviar() async {
    if (aEnviar) return false;
    _definir(() {
      aEnviar = true;
      erro = null;
    });
    try {
      await _repositorio.enviarParaVerificacao();
      _definir(() => aEnviar = false);
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
