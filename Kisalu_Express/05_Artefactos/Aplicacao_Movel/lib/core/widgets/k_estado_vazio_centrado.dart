import 'package:flutter/material.dart';

import '../theme/k_tokens.dart';

/// Centra um estado vazio na área visível e deixa-o rolar se não couber
/// (texto a 200 %). Usado nos separadores Conversas e Perfil.
class KEstadoVazioCentrado extends StatelessWidget {
  const KEstadoVazioCentrado({super.key, required this.filho});

  final Widget filho;

  @override
  Widget build(BuildContext context) {
    final margem = K.margemPara(context);
    return SafeArea(
      bottom: false,
      child: LayoutBuilder(
        builder: (context, caixa) => SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: margem, vertical: K.s24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: caixa.maxHeight - 2 * K.s24),
            child: Center(child: filho),
          ),
        ),
      ),
    );
  }
}
