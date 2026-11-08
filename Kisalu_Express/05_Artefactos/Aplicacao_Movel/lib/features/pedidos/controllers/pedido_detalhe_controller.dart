import 'package:flutter/foundation.dart';

import '../../../core/state/estado_ui.dart';
import '../../../data/repositories/kisalu_repository.dart';
import '../../../models/estado_pedido.dart';
import '../../../models/ordenacao_propostas.dart';
import '../../../models/pedido.dart';
import '../../../models/proposta.dart';

/// Estado do ecrã 04 · Pedido e propostas: carregamento, ordenação local das
/// propostas, cancelar e desfazer a aceitação. Nunca guarda valores de preço
/// escolhidos pelo cliente: o preço vem sempre da proposta (RNF08).
class PedidoDetalheController extends ChangeNotifier {
  PedidoDetalheController(this._repo, this.pedidoId);

  final KisaluRepository _repo;
  final String pedidoId;

  EstadoUi<Pedido> estado = const Carregar();
  OrdenacaoPropostas ordenacao = OrdenacaoPropostas.preco;
  bool aCancelar = false;
  bool _descartado = false;

  /// Relógio do repositório, para "Hoje, 16:00" e "chega em 40 min".
  DateTime get agora => _repo.agora();

  /// Propostas pela ordenação escolhida.
  List<Proposta> get propostas => switch (estado) {
    Sucesso<Pedido>(:final dados) => ordenacao.ordenar(dados.propostas),
    _ => const [],
  };

  @override
  void notifyListeners() {
    if (!_descartado) super.notifyListeners();
  }

  @override
  void dispose() {
    _descartado = true;
    super.dispose();
  }

  /// Janela da API para desfazer a aceitação (DESFAZER_ACEITACAO_MIN).
  static const janelaDesfazer = Duration(minutes: 5);

  Future<void> carregar() async {
    estado = const Carregar();
    notifyListeners();
    await recarregar();
  }

  /// Releitura sem esqueletos: voltar ao separador ou ao ecrã (o pedido pode
  /// ter mudado noutro aparelho).
  Future<void> recarregar() async {
    try {
      final pedido = await _repo.pedido(pedidoId);
      estado = pedido == null
          ? const Erro(
              'Não encontrámos este pedido. Veja os seus pedidos.',
              naoEncontrado: true,
            )
          : Sucesso(pedido);
    } on KisaluException catch (e) {
      estado = Erro(e.mensagem, semRede: e is SemRedeException);
    }
    notifyListeners();
  }

  void ordenar(OrdenacaoPropostas nova) {
    if (nova == ordenacao) return;
    ordenacao = nova;
    notifyListeners();
  }

  /// Cancela o pedido. Devolve null se correu bem, ou a mensagem de erro.
  Future<String?> cancelar() async {
    aCancelar = true;
    notifyListeners();
    try {
      await _repo.cancelarPedido(pedidoId);
      return null;
    } on KisaluException catch (e) {
      return e.mensagem;
    } finally {
      aCancelar = false;
      notifyListeners();
    }
  }

  /// Chamado depois de a folha 08 aceitar a proposta: atualiza o pedido.
  void aoAceitar(Pedido aceite) {
    estado = Sucesso(aceite);
    notifyListeners();
  }

  /// "Desfazer" do SnackBar. Devolve null se correu bem, ou a mensagem.
  Future<String?> desfazerAceitacao() async {
    try {
      await _repo.desfazerAceitacao(pedidoId);
      final pedido = await _repo.pedido(pedidoId);
      if (pedido != null) estado = Sucesso(pedido);
      notifyListeners();
      return null;
    } on KisaluException catch (e) {
      return e.mensagem;
    }
  }

  /// Recusa uma proposta (RF05) e tira-a da lista. Devolve null se correu
  /// bem, ou a mensagem de erro. A API não permite desfazer.
  Future<String?> recusar(String propostaId) async {
    try {
      await _repo.recusarProposta(pedidoId, propostaId);
      final atual = estado;
      if (atual is Sucesso<Pedido>) {
        estado = Sucesso(
          atual.dados.copyWith(
            propostas: [
              ...atual.dados.propostas.where((p) => p.id != propostaId),
            ],
          ),
        );
        notifyListeners();
      }
      return null;
    } on KisaluException catch (e) {
      return e.mensagem;
    }
  }

  Pedido? get _pedido => switch (estado) {
    Sucesso<Pedido>(:final dados) => dados,
    _ => null,
  };

  /// Já há proposta aceite: mostra-se o acordo, não as propostas.
  bool get temAceite => _pedido?.propostaAceitaId != null;

  /// "Editar pedido" só antes de aceitar (a API recusa depois).
  bool get podeEditar => _pedido?.estado == EstadoPedido.novo && !temAceite;

  /// "Ver código QR": o serviço ainda não foi confirmado.
  bool get podeVerQr => _pedido?.estado == EstadoPedido.emCurso && temAceite;

  /// "Desfazer" no acordo: até 5 min depois de aceitar e antes de o
  /// profissional sair.
  bool get podeDesfazer {
    final p = _pedido;
    final aceite = p?.aceiteEm;
    if (p == null || aceite == null || p.estado != EstadoPedido.emCurso) {
      return false;
    }
    final etapaInicial = p.etapa == null || p.etapa == EtapaServico.aceite;
    return etapaInicial && agora.difference(aceite) < janelaDesfazer;
  }

  /// Só pedidos ainda sem aceitação mostram propostas aceitáveis.
  bool get podeAceitar => switch (estado) {
    Sucesso<Pedido>(:final dados) => dados.estado == EstadoPedido.novo,
    _ => false,
  };
}
