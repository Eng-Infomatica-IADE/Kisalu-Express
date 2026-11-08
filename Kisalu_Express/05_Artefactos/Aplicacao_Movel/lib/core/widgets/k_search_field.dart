import 'package:flutter/material.dart';

import '../theme/k_colors.dart';
import '../theme/k_icons.dart';
import '../theme/k_tokens.dart';

/// Pesquisa do Início ("Que serviço precisa hoje?"): lupa laranja, sem
/// rótulo visível (a dica é a pergunta), nome acessível "Pesquisar serviço".
/// Com [onTap] e `soLeitura: true` funciona como atalho para outro ecrã.
class KSearchField extends StatelessWidget {
  const KSearchField({
    super.key,
    this.dica = 'Que serviço precisa hoje?',
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.soLeitura = false,
  });

  final String dica;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final bool soLeitura;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final borda = OutlineInputBorder(
      borderRadius: BorderRadius.circular(K.raioCategoria),
      borderSide: const BorderSide(color: KColors.areia400),
    );
    return Semantics(
      label: 'Pesquisar serviço',
      textField: true,
      child: TextField(
        controller: controller,
        readOnly: soLeitura,
        onTap: onTap,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        textInputAction: TextInputAction.search,
        style: text.bodyLarge,
        cursorColor: KColors.laranja,
        decoration: InputDecoration(
          hintText: dica,
          hintStyle: text.bodyLarge!.copyWith(color: KColors.neutro500),
          filled: true,
          fillColor: KColors.branco,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: K.s16,
            vertical: K.s16 + K.s4 - 1,
          ),
          prefixIcon: const Icon(
            KIcons.pesquisa,
            size: K.icone24,
            color: KColors.laranja,
          ),
          enabledBorder: borda,
          border: borda,
          focusedBorder: borda.copyWith(
            borderSide: const BorderSide(color: KColors.laranja, width: 2),
          ),
        ),
      ),
    );
  }
}
