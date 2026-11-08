import 'package:flutter/material.dart';

import '../../../core/theme/k_colors.dart';
import '../../../core/theme/k_icons.dart';
import '../../../core/theme/k_tokens.dart';
import '../../../core/validators/k_validators.dart';
import '../../../core/widgets/k_text_field.dart';

/// Barra inferior da conversa (ecrã 19): foto, campo e enviar. Sem texto o
/// enviar fica desativado (areia); o campo limita a 1.000 caracteres.
class BarraEscrita extends StatelessWidget {
  const BarraEscrita({
    super.key,
    required this.controller,
    required this.onEnviar,
    required this.onFoto,
    this.aEnviar = false,
  });

  final TextEditingController controller;
  final VoidCallback onEnviar;
  final VoidCallback onFoto;
  final bool aEnviar;

  @override
  Widget build(BuildContext context) {
    final margem = K.margemPara(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(margem, K.s8, margem, K.s32 - 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Semantics(
            button: true,
            label: 'Enviar fotografia',
            onTap: onFoto,
            excludeSemantics: true,
            child: Material(
              color: KColors.branco,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(K.raioBotao),
                side: const BorderSide(color: KColors.areia400),
              ),
              child: InkWell(
                onTap: onFoto,
                customBorder: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(K.raioBotao),
                ),
                child: const SizedBox.square(
                  dimension: K.alvoMinimo,
                  child: Icon(
                    KIcons.foto,
                    size: K.icone20,
                    color: KColors.ebano,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: K.s8 + 2),
          Expanded(
            child: KTextField(
              rotulo: 'Mensagem',
              rotuloVisivel: false,
              controller: controller,
              dica: 'Escreva uma mensagem',
              maxCaracteres: KValidators.maxMensagem,
              mostrarContador: false,
              acaoTeclado: TextInputAction.send,
              onSubmitted: (_) => onEnviar(),
            ),
          ),
          const SizedBox(width: K.s8 + 2),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (_, valor, _) {
              final ativo = valor.text.trim().isNotEmpty && !aEnviar;
              return Semantics(
                button: true,
                enabled: ativo,
                label: 'Enviar mensagem',
                onTap: ativo ? onEnviar : null,
                excludeSemantics: true,
                child: Material(
                  color: ativo ? KColors.laranja : KColors.areia200,
                  borderRadius: BorderRadius.circular(K.raioBotao),
                  child: InkWell(
                    onTap: ativo ? onEnviar : null,
                    borderRadius: BorderRadius.circular(K.raioBotao),
                    child: SizedBox.square(
                      dimension: K.alvoMinimo,
                      child: Icon(
                        KIcons.enviar,
                        size: K.icone20,
                        color: ativo ? KColors.branco : KColors.neutro500,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
