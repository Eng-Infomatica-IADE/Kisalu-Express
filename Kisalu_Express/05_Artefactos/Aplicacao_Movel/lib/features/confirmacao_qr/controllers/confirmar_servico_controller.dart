import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/state/estado_ui.dart';
import '../../../data/repositories/kisalu_repository.dart';
import '../../../models/codigo_confirmacao.dart';
import '../../../models/estado_pedido.dart';
import '../../../models/pedido.dart';

/// Dados do ecrã 05 (só em memória: nunca vão para disco nem para logs).
class ServicoParaConfirmar {
  const ServicoParaConfirmar({
    required this.pedidoId,
    required this.profissional,
    required this.categoria,
    required this.valor,
    required this.codigo,
  });

  final String pedidoId;
  final String profissional;
  final String categoria;
  final int valor;
  final CodigoConfirmacao codigo;
}

/// Estado do ecrã 05 (há serviço em curso) e 09 (não há: [Vazio]).
///
/// Com [pedidoId] mostra o QR desse pedido (vem do detalhe 04); sem ele, o
/// serviço em curso mais recente. Enquanto o QR está no ecrã pergunta à API
/// de [intervaloVerificacao] em [intervaloVerificacao] se o profissional já
/// confirmou: quando o pedido fica concluído, [concluidoId] é preenchido e a
/// view abre a avaliação (06).
class ConfirmarServicoController extends ChangeNotifier {
  ConfirmarServicoController(
    this._repositorio, {
    this.forcarVazio = false,
    this.pedidoId,
    this.intervaloVerificacao = const Duration(seconds: 5),
  }) {
    _repositorio.alteracoes.addListener(_aoMudar);
  }

  final KisaluRepository _repositorio;

  /// Galeria dev (`/qr?vazio=1`): mostra o ecrã 09 mesmo com serviço.
  final bool forcarVazio;

  /// Pedido escolhido no detalhe 04 (`/qr?pedido=:id`); null = o mais recente.
  final String? pedidoId;

  /// Intervalo da verificação "já foi confirmado?"; zero desliga.
  final Duration intervaloVerificacao;

  bool _terminado = false;
  Timer? _verificacao;
  bool _aVerificar = false;

  EstadoUi<ServicoParaConfirmar> estado = const Carregar();

  /// Pedido que o profissional acabou de confirmar (a view abre o 06).
  String? concluidoId;

  /// Atalho de demonstração (tocar no QR abre o 06): só nos dados fictícios.
  bool get atalhoDemonstracao => _repositorio.modoDemonstracao;

  Future<void> carregar() async {
    _definir(const Carregar());
    await _ler();
  }

  /// Releitura silenciosa (separador escolhido outra vez, pull-to-refresh).
  Future<void> recarregar() => _ler();

  void _aoMudar() => _ler();

  Future<Pedido?> _pedido() async {
    final id = pedidoId;
    return id == null ? _repositorio.servicoEmCurso() : _repositorio.pedido(id);
  }

  Future<void> _ler() async {
    if (forcarVazio) return _definir(const Vazio());
    try {
      final pedido = await _pedido();
      final profissional = pedido?.profissional;
      final valor = pedido?.valor;
      if (pedido == null ||
          pedido.estado != EstadoPedido.emCurso ||
          profissional == null ||
          valor == null) {
        _pararVerificacao();
        return _definir(const Vazio());
      }
      final codigo = await _repositorio.codigoConfirmacao(pedido.id);
      _definir(
        Sucesso(
          ServicoParaConfirmar(
            pedidoId: pedido.id,
            profissional: profissional.nome,
            categoria: profissional.categoria,
            valor: valor,
            codigo: codigo,
          ),
        ),
      );
      _comecarVerificacao();
    } on NaoEncontradoException {
      _pararVerificacao();
      _definir(const Vazio());
    } on KisaluException catch (e) {
      _definir(Erro(e.mensagem, semRede: e is SemRedeException));
    }
  }

  void _comecarVerificacao() {
    if (_verificacao != null || intervaloVerificacao <= Duration.zero) return;
    _verificacao = Timer.periodic(intervaloVerificacao, (_) => verificar());
  }

  void _pararVerificacao() {
    _verificacao?.cancel();
    _verificacao = null;
  }

  /// Pergunta se o pedido do QR já foi confirmado pelo profissional.
  Future<void> verificar() async {
    final atual = estado;
    if (_terminado || _aVerificar || atual is! Sucesso<ServicoParaConfirmar>) {
      return;
    }
    _aVerificar = true;
    try {
      final pedido = await _repositorio.pedido(atual.dados.pedidoId);
      if (pedido?.estado == EstadoPedido.concluido && !_terminado) {
        _pararVerificacao();
        concluidoId = pedido!.id;
        notifyListeners();
      }
    } on KisaluException {
      // Tenta outra vez na próxima volta.
    } finally {
      _aVerificar = false;
    }
  }

  /// A view já abriu a avaliação.
  void avaliacaoAberta() => concluidoId = null;

  void _definir(EstadoUi<ServicoParaConfirmar> novo) {
    if (_terminado) return;
    estado = novo;
    notifyListeners();
  }

  @override
  void dispose() {
    _repositorio.alteracoes.removeListener(_aoMudar);
    _pararVerificacao();
    _terminado = true;
    super.dispose();
  }
}
