import 'package:flutter/material.dart';

import 'k_botao_base.dart';

/// Botões do Style Guide (cap. 06, p. 10). Um só primário por ecrã; o texto
/// começa por um verbo ("Pedir serviço", nunca "OK").
///
/// Estados: normal · premido · foco (anel Ébano afastado, só com teclado ou
/// leitor de ecrã) · a carregar · desativado (`onPressed: null`).

/// Ação principal do ecrã. 52 dp, laranja, largura total por defeito.
/// `destrutivo: true` só dentro de confirmações (ex. "Cancelar pedido").
class KPrimaryButton extends StatelessWidget {
  const KPrimaryButton({
    super.key,
    required this.rotulo,
    required this.onPressed,
    this.icone,
    this.aCarregar = false,
    this.larguraTotal = true,
    this.compacto = false,
    this.destrutivo = false,
  });

  final String rotulo;
  final VoidCallback? onPressed;
  final IconData? icone;
  final bool aCarregar;
  final bool larguraTotal;

  /// 48 dp em vez de 52 (botões dentro de cartões).
  final bool compacto;
  final bool destrutivo;

  @override
  Widget build(BuildContext context) => KBotaoBase(
    variante: KBotaoVariante.primario,
    rotulo: rotulo,
    onPressed: onPressed,
    icone: icone,
    aCarregar: aCarregar,
    larguraTotal: larguraTotal,
    compacto: compacto,
    destrutivo: destrutivo,
  );
}
