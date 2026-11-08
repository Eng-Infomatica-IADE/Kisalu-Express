import 'package:flutter/widgets.dart';

/// Chama [aoVoltar] sempre que o ecrã volta a ficar visível: ao escolher
/// outra vez o seu separador (os separadores ficam vivos num IndexedStack
/// com `TickerMode` desligado) ou ao fechar uma rota que estava por cima no
/// mesmo navigator. Não chama na primeira construção (o controller já
/// carregou). Serve para não mostrar dados antigos (ex.: "EM CURSO" de um
/// pedido já concluído).
class KAoVoltar extends StatefulWidget {
  const KAoVoltar({super.key, required this.aoVoltar, required this.child});

  final VoidCallback aoVoltar;
  final Widget child;

  @override
  State<KAoVoltar> createState() => _KAoVoltarState();
}

class _KAoVoltarState extends State<KAoVoltar> {
  bool? _visivel;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final visivel =
        TickerMode.valuesOf(context).enabled &&
        (ModalRoute.of(context)?.isCurrent ?? true);
    final antes = _visivel;
    _visivel = visivel;
    if (antes == false && visivel) {
      // Depois do frame: o callback pode notificar listeners.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.aoVoltar();
      });
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
