import 'package:flutter/foundation.dart';

import '../../../core/state/estado_ui.dart';
import '../../../core/validators/k_validators.dart';
import '../../../data/repositories/kisalu_repository.dart';
import '../../../models/utilizador.dart';

/// Estado do ecrã 01. O telemóvel nunca é registado em logs.
class LoginController extends ChangeNotifier {
  LoginController(this._repositorio);

  final KisaluRepository _repositorio;
  bool _terminado = false;

  /// Valor com que o campo arranca; Vazio = campo em branco.
  EstadoUi<String> estado = const Carregar();
  PerfilUtilizador perfil = PerfilUtilizador.cliente;
  String? erroTelefone;
  bool aEnviar = false;

  Future<void> carregar() async {
    _definir(() => estado = const Carregar());
    try {
      final tel = (await _repositorio.telemovelPredefinido())?.trim() ?? '';
      _definir(() => estado = tel.isEmpty ? const Vazio() : Sucesso(tel));
    } on KisaluException catch (e) {
      _definir(() => estado = Erro(e.mensagem, semRede: e is SemRedeException));
    }
  }

  void mudarPerfil(PerfilUtilizador novo) {
    if (novo == perfil) return;
    _definir(() => perfil = novo);
  }

  /// Ao escrever, o erro desaparece (só se revalida ao sair do campo).
  void aoEscrever() {
    if (erroTelefone != null) _definir(() => erroTelefone = null);
  }

  /// Ao sair do campo: campo vazio não é erro.
  void validarAoSair(String valor) {
    if (valor.trim().isEmpty) return;
    _definir(() => erroTelefone = KValidators.telemovel(valor));
  }

  /// "Receber código SMS" e "Criar conta" seguem o mesmo fluxo (a resposta
  /// não revela se o número já tem conta); [criarConta] só muda o destino
  /// depois do código. Valida antes de avançar. Devolve true se pode navegar.
  Future<bool> submeter(String valor, {bool criarConta = false}) async {
    if (aEnviar) return false;
    final erro = KValidators.telemovel(valor);
    if (erro != null) {
      _definir(() => erroTelefone = erro);
      return false;
    }
    _definir(() {
      erroTelefone = null;
      aEnviar = true;
    });
    try {
      await _repositorio.pedirCodigoSms(
        KValidators.normalizarTelemovel(valor)!,
        perfil,
        criarConta: criarConta,
      );
      _definir(() => aEnviar = false);
      return true;
    } on KisaluException catch (e) {
      _definir(() {
        aEnviar = false;
        erroTelefone = e.mensagem;
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
