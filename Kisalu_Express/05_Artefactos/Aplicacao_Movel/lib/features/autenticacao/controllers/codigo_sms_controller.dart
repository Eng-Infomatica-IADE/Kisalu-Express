import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/state/estado_ui.dart';
import '../../../core/validators/k_validators.dart';
import '../../../data/repositories/kisalu_repository.dart';
import '../../../models/pedido_codigo_sms.dart';

/// Para onde vai a pessoa depois de confirmar o código.
enum DestinoCodigoSms {
  inicio,

  /// Quem entrou como profissional sem registo feito continua no registo.
  registoProfissional,
}

/// Estado do ecrã 11 · Código SMS. O telemóvel e o código nunca vão para
/// logs, rotas nem `extra`: o pedido em curso vive no repositório.
class CodigoSmsController extends ChangeNotifier {
  CodigoSmsController(this._repositorio, {this.segundosReenvio = 42});

  final KisaluRepository _repositorio;

  /// Espera simulada antes de se poder pedir outro código.
  final int segundosReenvio;
  bool _terminado = false;
  Timer? _contagem;

  EstadoUi<PedidoCodigoSms> estado = const Carregar();

  /// Código com que o campo arranca (demonstração); vazio se não houver.
  String codigoInicial = '';
  String? erro;
  bool aConfirmar = false;
  bool aReenviar = false;
  late int segundosRestantes = segundosReenvio;

  bool get podeReenviar => segundosRestantes == 0 && !aReenviar;

  Future<void> carregar() async {
    _definir(() => estado = const Carregar());
    try {
      final pendente = await _repositorio.codigoSmsPendente();
      codigoInicial = await _repositorio.codigoSmsPredefinido() ?? '';
      _definir(() => estado = Sucesso(pendente));
      _iniciarContagem();
    } on KisaluException catch (e) {
      _definir(() => estado = Erro(e.mensagem, semRede: e is SemRedeException));
    }
  }

  void _iniciarContagem() {
    _contagem?.cancel();
    segundosRestantes = segundosReenvio;
    if (segundosRestantes == 0) return;
    _contagem = Timer.periodic(const Duration(seconds: 1), (t) {
      if (segundosRestantes > 0) {
        _definir(() => segundosRestantes--);
      }
      if (segundosRestantes == 0) t.cancel();
    });
  }

  /// Ao escrever, o erro desaparece (só se revalida ao confirmar).
  void aoEscrever() {
    if (erro != null) _definir(() => erro = null);
  }

  /// "Reenviar código": pede outro código e recomeça a contagem.
  Future<void> reenviar() async {
    final atual = estado;
    if (atual is! Sucesso<PedidoCodigoSms> || !podeReenviar) return;
    _definir(() => aReenviar = true);
    try {
      await _repositorio.pedirCodigoSms(
        atual.dados.telemovel,
        atual.dados.perfil,
        criarConta: atual.dados.criarConta,
      );
      _definir(() => aReenviar = false);
      _iniciarContagem();
      _definir(() => erro = null);
    } on KisaluException catch (e) {
      _definir(() {
        aReenviar = false;
        erro = e.mensagem;
      });
    }
  }

  /// "Confirmar": valida o formato, pede ao repositório e passa a sessão ao
  /// perfil escolhido. Devolve o destino, ou null se ficou no ecrã.
  Future<DestinoCodigoSms?> confirmar(String codigo) async {
    final atual = estado;
    if (atual is! Sucesso<PedidoCodigoSms> || aConfirmar) return null;
    final invalido = KValidators.codigoSms(codigo);
    if (invalido != null) {
      _definir(() => erro = invalido);
      return null;
    }
    final pedido = atual.dados;
    _definir(() {
      erro = null;
      aConfirmar = true;
    });
    try {
      final precisaRegisto = await _repositorio.validarCodigoSms(
        pedido.telemovel,
        KValidators.normalizarCodigo(codigo)!,
      );
      await _repositorio.mudarPerfil(pedido.perfil);
      _definir(() => aConfirmar = false);
      return precisaRegisto
          ? DestinoCodigoSms.registoProfissional
          : DestinoCodigoSms.inicio;
    } on KisaluException catch (e) {
      _definir(() {
        aConfirmar = false;
        erro = e.mensagem;
      });
      return null;
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
    _contagem?.cancel();
    super.dispose();
  }
}
