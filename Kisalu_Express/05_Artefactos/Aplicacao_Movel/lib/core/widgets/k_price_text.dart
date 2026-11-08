import 'package:flutter/material.dart';

import '../theme/k_colors.dart';
import '../theme/k_typography.dart';
import '../utils/k_format.dart';

/// Preço em kwanzas, sempre o elemento mais forte do cartão (Sora 800).
/// Formata com [KFormat.kz] ("12.500 Kz") e nunca corta com reticências.
/// O leitor de ecrã diz "12.500 kwanzas".
class KPriceText extends StatelessWidget {
  const KPriceText(
    this.valor, {
    super.key,
    this.tamanho = KPriceText.cartao,
    this.cor = KColors.ebano,
  });

  final int valor;
  final double tamanho;
  final Color cor;

  static const lista = 14.0; // histórico (07)
  static const cartao = 19.0; // propostas (04)
  static const barra = 22.0; // barra inferior do perfil (03)
  static const destaque = 24.0; // folha de confirmação (08)
  static const display = 32.0; // comprovativo / sucesso

  @override
  Widget build(BuildContext context) {
    final texto = KFormat.kz(valor);
    return Semantics(
      label: texto.replaceAll('Kz', 'kwanzas'),
      excludeSemantics: true,
      child: Text(
        texto,
        softWrap: true,
        style: KTypography.preco(size: tamanho).copyWith(color: cor),
      ),
    );
  }
}
