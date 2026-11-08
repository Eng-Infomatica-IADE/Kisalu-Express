import 'package:flutter/material.dart';
import 'package:kisalu_express/core/theme/k_theme.dart';

/// Envolve um widget num ecrã de 360x740 com o tema Kisalu, para os testes
/// de componentes. [rolavel] mete o conteúdo num scroll; [comMargem] aplica
/// 16 dp à volta.
Widget montarWidget(
  Widget filho, {
  double escalaTexto = 1,
  bool rolavel = false,
  bool comMargem = true,
}) {
  final conteudo = Align(
    alignment: Alignment.topLeft,
    child: SizedBox(
      width: 360,
      child: comMargem
          ? Padding(padding: const EdgeInsets.all(16), child: filho)
          : filho,
    ),
  );
  return MaterialApp(
    theme: KTheme.light(),
    home: MediaQuery(
      data: MediaQueryData(
        size: const Size(360, 740),
        textScaler: TextScaler.linear(escalaTexto),
      ),
      child: Scaffold(
        body: rolavel ? SingleChildScrollView(child: conteudo) : conteudo,
      ),
    ),
  );
}
