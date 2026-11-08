import 'package:flutter/material.dart';

import 'k_botao_base.dart';

/// Ação de menor peso (terciário): só texto laranja. `destrutivo` usa a cor
/// de erro ("O trabalho tem um problema?"); `pequeno` para ligações em
/// legendas ("Ver todos"). O alvo de toque mantém sempre ≥ 48 dp.
class KTextLink extends StatelessWidget {
  const KTextLink({
    super.key,
    required this.rotulo,
    required this.onPressed,
    this.icone,
    this.destrutivo = false,
    this.pequeno = false,
    this.grande = false,
  });

  final String rotulo;
  final VoidCallback? onPressed;
  final IconData? icone;
  final bool destrutivo;
  final bool pequeno;

  /// 15 sp em vez de 14 (ecrãs 11, 13, 17 e 20).
  final bool grande;

  @override
  Widget build(BuildContext context) => KBotaoBase(
    variante: KBotaoVariante.texto,
    rotulo: rotulo,
    onPressed: onPressed,
    icone: icone,
    destrutivo: destrutivo,
    pequeno: pequeno,
    grande: grande,
    larguraTotal: false,
  );
}
