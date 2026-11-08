import 'package:flutter/material.dart';

import '../../../core/theme/k_tokens.dart';
import 'passos_confirmacao.dart';

// A folha "O trabalho tem um problema?" passou para core/widgets
// (`mostrarKFolhaProblema`): também a usa o histórico (07).

/// Folha "Como funciona?" com os 3 passos (P20).
class ComoFuncionaFolha extends StatelessWidget {
  const ComoFuncionaFolha({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            'Como funciona?',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const SizedBox(height: K.s16),
        const PassosConfirmacao(),
      ],
    );
  }
}
