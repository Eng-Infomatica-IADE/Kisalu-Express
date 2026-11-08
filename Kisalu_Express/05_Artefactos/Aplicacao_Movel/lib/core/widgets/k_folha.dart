import 'package:flutter/material.dart';

import '../theme/k_colors.dart';
import '../theme/k_tokens.dart';

/// Abre uma folha inferior (bottom sheet) do design system: fundo branco,
/// cantos superiores com raio 24, pega no topo e barreira Ébano a ~40 %.
/// Usada em 05 (problema, "Como funciona?"), 07 (comprovativo) e 08.
/// Fecha-se com `Navigator.pop` / `context.pop`.
Future<T?> mostrarKFolha<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) => showModalBottomSheet<T>(
  context: context,
  useRootNavigator: true, // cobre a barra inferior, como no Figma
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: KColors.branco,
  barrierColor: KColors.ebano.withValues(alpha: .5),
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(K.raioFolha)),
  ),
  builder: (context) => KFolha(child: builder(context)),
);

/// Conteúdo de uma folha: pega + margens + scroll se não couber (texto a
/// 200 %). Normalmente só se usa através de [mostrarKFolha].
class KFolha extends StatelessWidget {
  const KFolha({super.key, required this.child});

  final Widget child;

  /// Largura e altura da pega no topo.
  static const pegaLargura = 40.0;
  static const pegaAltura = 4.0;

  @override
  Widget build(BuildContext context) {
    const margem = K.s24 - K.s4 / 2;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        margem,
        K.s12,
        margem,
        K.s32 + K.s4 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: ExcludeSemantics(
              child: Container(
                width: pegaLargura,
                height: pegaAltura,
                decoration: BoxDecoration(
                  color: KColors.areia300,
                  borderRadius: BorderRadius.circular(K.raioPilula),
                ),
              ),
            ),
          ),
          const SizedBox(height: K.s12),
          child,
        ],
      ),
    );
  }
}
