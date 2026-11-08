import 'package:flutter/material.dart';

import '../theme/k_colors.dart';
import '../theme/k_icons.dart';
import '../theme/k_tokens.dart';

/// Barra inferior com 5 separadores, sempre com ícone + rótulo (RNF04).
/// O QR fica ao centro num círculo laranja com rótulo (corrige P03) e passa a
/// areia quando não há serviço em curso (corrige P04).
///
/// Segue o Figma v2: o separador ativo tem ícone e rótulo laranja, sem a
/// pílula de fundo que aparece no Style Guide (p. 14), e os separadores
/// distribuem-se com espaço igual entre si (não em colunas iguais).
class KBottomNavBar extends StatelessWidget {
  const KBottomNavBar({
    super.key,
    required this.indiceAtual,
    required this.onSelecionar,
    this.qrDisponivel = true,
  });

  /// 0 Início · 1 Pedidos · 2 QR · 3 Conversas · 4 Perfil
  final int indiceAtual;
  final ValueChanged<int> onSelecionar;

  /// false → QR desativado (não há serviço para confirmar). Continua tocável
  /// e leva ao estado vazio, que explica porquê.
  final bool qrDisponivel;

  static const indiceQr = 2;
  static const indiceConversas = 3;

  static const _separadores = <(IconData, String)>[
    (KIcons.inicio, 'Início'),
    (KIcons.pedidos, 'Pedidos'),
    (KIcons.codigoQr, 'QR'),
    (KIcons.conversa, 'Conversas'),
    (KIcons.perfil, 'Perfil'),
  ];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: KColors.branco,
        border: Border(top: BorderSide(color: KColors.areia200)),
      ),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          // Cresce com o texto do sistema (200 %) em vez de cortar.
          constraints: const BoxConstraints(minHeight: K.navAltura),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: K.s4 + K.s4 / 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var i = 0; i < _separadores.length; i++)
                  // Largura fixa por separador: o QR não muda de sítio (V30).
                  Expanded(
                    flex: i == indiceQr || i == indiceConversas ? 6 : 5,
                    child: i == indiceQr
                        ? _BotaoQr(
                            ativo: indiceAtual == i,
                            disponivel: qrDisponivel,
                            onTap: () => onSelecionar(i),
                          )
                        : _Separador(
                            icone: _separadores[i].$1,
                            rotulo: _separadores[i].$2,
                            ativo: indiceAtual == i,
                            onTap: () => onSelecionar(i),
                          ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Separador extends StatelessWidget {
  const _Separador({
    required this.icone,
    required this.rotulo,
    required this.ativo,
    required this.onTap,
  });

  final IconData icone;
  final String rotulo;
  final bool ativo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final legenda = Theme.of(context).textTheme.bodySmall!;
    return Semantics(
      button: true,
      selected: ativo,
      label: rotulo,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        containedInkWell: true,
        highlightShape: BoxShape.rectangle,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(K.s8 + 2, K.s8, K.s8 + 2, K.s4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icone,
                size: K.icone24,
                color: ativo ? KColors.laranja : KColors.neutro500,
              ),
              const SizedBox(height: K.s4),
              Text(
                rotulo,
                textAlign: TextAlign.center,
                style: legenda.copyWith(
                  color: ativo ? KColors.laranja : KColors.neutro500,
                  fontWeight: ativo ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BotaoQr extends StatelessWidget {
  const _BotaoQr({
    required this.ativo,
    required this.disponivel,
    required this.onTap,
  });

  final bool ativo;
  final bool disponivel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final legenda = Theme.of(context).textTheme.bodySmall!;
    return Semantics(
      button: true,
      selected: ativo,
      label: disponivel
          ? 'QR, confirmar o serviço em curso'
          : 'QR, sem serviços para confirmar',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            K.s8 + 2,
            K.s8 + 3,
            K.s8 + 2,
            K.s4,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: K.qrBotao,
                height: K.qrBotao,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: disponivel ? KColors.laranja : KColors.areia300,
                  boxShadow: disponivel
                      ? [
                          BoxShadow(
                            color: KColors.laranja.withValues(alpha: .35),
                            offset: const Offset(0, 4),
                            blurRadius: 14,
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  KIcons.codigoQr,
                  size: K.icone24 + K.s4,
                  color: disponivel
                      ? KColors.branco
                      : KColors.branco.withValues(alpha: .7),
                ),
              ),
              const SizedBox(height: K.s4),
              Text(
                'QR',
                style: legenda.copyWith(
                  color: disponivel ? KColors.laranja : KColors.neutro500,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
