import 'estado_pedido.dart';
import 'pedido.dart';

/// Filtros do histórico (ecrã 07). Aplicam-se localmente.
enum FiltroPedidos {
  todos('Todos'),
  emCurso('Em curso'),
  concluidos('Concluídos'),
  cancelados('Cancelados');

  const FiltroPedidos(this.rotulo);

  final String rotulo;

  bool aceita(EstadoPedido estado) => switch (this) {
    FiltroPedidos.todos => true,
    FiltroPedidos.emCurso => estado == EstadoPedido.emCurso,
    FiltroPedidos.concluidos => estado == EstadoPedido.concluido,
    FiltroPedidos.cancelados => estado == EstadoPedido.cancelado,
  };

  List<Pedido> aplicar(List<Pedido> pedidos) => [
    for (final p in pedidos)
      if (aceita(p.estado)) p,
  ];
}
