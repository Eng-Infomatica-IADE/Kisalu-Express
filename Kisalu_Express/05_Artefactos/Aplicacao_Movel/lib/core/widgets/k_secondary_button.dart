import 'package:flutter/material.dart';

import 'k_botao_base.dart';

/// Alternativa com o mesmo peso de leitura: contorno laranja, fundo branco.
class KSecondaryButton extends StatelessWidget {
  const KSecondaryButton({
    super.key,
    required this.rotulo,
    required this.onPressed,
    this.icone,
    this.aCarregar = false,
    this.larguraTotal = true,
    this.compacto = false,
  });

  final String rotulo;
  final VoidCallback? onPressed;
  final IconData? icone;
  final bool aCarregar;
  final bool larguraTotal;
  final bool compacto;

  @override
  Widget build(BuildContext context) => KBotaoBase(
    variante: KBotaoVariante.secundario,
    rotulo: rotulo,
    onPressed: onPressed,
    icone: icone,
    aCarregar: aCarregar,
    larguraTotal: larguraTotal,
    compacto: compacto,
  );
}
