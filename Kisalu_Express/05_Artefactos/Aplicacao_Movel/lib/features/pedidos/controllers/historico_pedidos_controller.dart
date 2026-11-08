import 'package:flutter/foundation.dart';

import '../../../core/state/estado_ui.dart';
import '../../../data/repositories/kisalu_repository.dart';
import '../../../models/comprovativo.dart';
import '../../../models/estado_pedido.dart';
import '../../../models/filtro_pedidos.dart';
import '../../../models/pedido.dart';
import '../../../models/utilizador.dart';

/// Estado do ecrã 07 · Histórico de pedidos.
class HistoricoPedidosController extends ChangeNotifier {
  HistoricoPedidosController(this._repositorio) {
    _repositorio.alteracoes.addListener(recarregar);
  }

  final KisaluRepository _repositorio;
  bool _terminado = false;

  EstadoUi<List<Pedido>> estado = const Carregar();
  FiltroPedidos filtro = FiltroPedidos.todos;

  /// No modo profissional a lista são os trabalhos do profissional: não
  /// abre o detalhe do cliente nem oferece "Pedir de novo".
  bool get modoProfissional =>
      _repositorio.perfilAtivo == PerfilUtilizador.profissional;

  /// Relógio do repositório, para "Hoje" / "24 set".
  DateTime get agora => _repositorio.agora();

  Future<void> carregar() async {
    _definir(const Carregar());
    await recarregar();
  }

  /// Releitura sem esqueletos (pull-to-refresh, voltar ao separador).
  Future<void> recarregar() async {
    try {
      final pedidos = await _repositorio.historico();
      _definir(pedidos.isEmpty ? const Vazio() : Sucesso(pedidos));
    } on KisaluException catch (e) {
      _definir(Erro(e.mensagem, semRede: e is SemRedeException));
    }
  }

  void escolherFiltro(FiltroPedidos novo) {
    if (novo == filtro) return;
    filtro = novo;
    notifyListeners();
  }

  /// Pedidos que passam o filtro atual (aplicado localmente).
  List<Pedido> get filtrados => switch (estado) {
    Sucesso(:final dados) => filtro.aplicar(dados),
    _ => const [],
  };

  /// Como no Figma, as ações "Pedir de novo" / "Ver comprovativo" aparecem
  /// só no primeiro pedido concluído da lista.
  bool mostraAcoes(Pedido pedido) {
    if (modoProfissional) return false;
    if (pedido.estado != EstadoPedido.concluido) return false;
    final primeiro = filtrados
        .where((p) => p.estado == EstadoPedido.concluido)
        .firstOrNull;
    return primeiro?.id == pedido.id;
  }

  /// "Avaliar": concluído e ainda sem avaliação (RF12). Depois de avaliar o
  /// repositório avisa, a lista relê e a ação desaparece.
  bool podeAvaliar(Pedido pedido) =>
      !modoProfissional &&
      pedido.estado == EstadoPedido.concluido &&
      !pedido.avaliado;

  /// Comprovativo do pedido; null se não existir ou se a leitura falhar.
  Future<Comprovativo?> comprovativo(String pedidoId) async {
    try {
      return await _repositorio.comprovativo(pedidoId);
    } on KisaluException {
      return null;
    }
  }

  void _definir(EstadoUi<List<Pedido>> novo) {
    if (_terminado) return;
    estado = novo;
    notifyListeners();
  }

  @override
  void dispose() {
    _repositorio.alteracoes.removeListener(recarregar);
    _terminado = true;
    super.dispose();
  }
}
