import 'package:flutter/material.dart';

import '../../models/estado_pedido.dart';
import '../theme/k_colors.dart';
import '../theme/k_icons.dart';
import '../theme/k_tokens.dart';
import '../theme/k_typography.dart';

/// Etiqueta de estado em pílula, como no Figma v2: Sora 700 em MAIÚSCULAS.
/// Com [compacta] (cartões do histórico) fica mais pequena.
/// O estado lê-se sempre pelo texto, nunca só pela cor (RNF05).
class KStatusBadge extends StatelessWidget {
  const KStatusBadge._(
    this.texto,
    this.fundo,
    this.cor, {
    this.icone,
    this.compacta = false,
    this.borda,
  });

  /// NOVO · EM CURSO · CONCLUÍDO · CANCELADO
  factory KStatusBadge.estado(EstadoPedido estado, {bool compacta = false}) =>
      switch (estado) {
        EstadoPedido.novo => KStatusBadge._(
          'Novo',
          KColors.tomClaro,
          KColors.brasa,
          compacta: compacta,
        ),
        EstadoPedido.emCurso => KStatusBadge._(
          'Em curso',
          KColors.tomClaro,
          KColors.brasa,
          compacta: compacta,
        ),
        EstadoPedido.concluido => KStatusBadge._(
          'Concluído',
          KColors.sucessoFundo,
          KColors.sucesso,
          compacta: compacta,
        ),
        EstadoPedido.cancelado => KStatusBadge._(
          'Cancelado',
          KColors.erroFundo,
          KColors.erro,
          compacta: compacta,
        ),
      };

  /// "3 PROPOSTAS" (Ébano) — ecrã 04.
  factory KStatusBadge.propostas(int n) => KStatusBadge._(
    n == 1 ? '1 proposta' : '$n propostas',
    KColors.ebano,
    KColors.branco,
  );

  /// "ACEITE" com visto: a proposta escolhida no detalhe 04.
  factory KStatusBadge.aceite() => KStatusBadge._(
    'Aceite',
    KColors.sucessoFundo,
    KColors.sucesso,
    icone: KIcons.concluido,
  );

  /// Etiqueta de destaque em tom claro: "NOVA" nas notificações, a etapa do
  /// serviço ("A CAMINHO") no detalhe do trabalho.
  factory KStatusBadge.destaque(String texto, {bool compacta = false}) =>
      KStatusBadge._(
        texto,
        KColors.tomClaro,
        KColors.brasa,
        compacta: compacta,
      );

  /// "VERIFICADO" com escudo — perfil e cartões de profissional.
  /// [sobreCor]: fundo branco, para o cabeçalho laranja do perfil (03).
  factory KStatusBadge.verificado({bool sobreCor = false}) => KStatusBadge._(
    'Verificado',
    sobreCor ? KColors.branco : KColors.sucessoFundo,
    KColors.sucesso,
    icone: KIcons.verificado,
  );

  /// "ENVIADO" (verde sobre branco, com contorno, para passar AA) ou
  /// "FALTA" (tom claro): documentos do selo Verificado (ecrã 13).
  factory KStatusBadge.envio({required bool enviado, bool compacta = false}) =>
      enviado
      ? KStatusBadge._(
          'Enviado',
          KColors.branco,
          KColors.sucesso,
          compacta: compacta,
          borda: KColors.sucesso,
        )
      : KStatusBadge._(
          'Falta',
          KColors.tomClaro,
          KColors.brasa,
          compacta: compacta,
        );

  final String texto;
  final Color fundo;
  final Color cor;
  final IconData? icone;
  final bool compacta;

  /// Contorno opcional da pílula.
  final Color? borda;

  @override
  Widget build(BuildContext context) {
    final estilo = compacta
        ? KTypography.etiquetaCompacta
        : Theme.of(context).textTheme.labelSmall!;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compacta ? K.s8 : K.s12,
        vertical: compacta ? K.s4 - 1 : K.s4 + K.s4 / 2 - 1,
      ),
      decoration: BoxDecoration(
        color: fundo,
        border: borda == null ? null : Border.all(color: borda!),
        borderRadius: BorderRadius.circular(K.raioPilula),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icone != null) ...[
            Icon(icone, size: K.icone16, color: cor),
            const SizedBox(width: K.s4),
          ],
          Flexible(
            child: Text(
              texto.toUpperCase(),
              style: estilo.copyWith(color: cor),
            ),
          ),
        ],
      ),
    );
  }
}
