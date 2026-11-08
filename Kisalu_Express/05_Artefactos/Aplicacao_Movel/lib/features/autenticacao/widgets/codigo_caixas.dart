import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/k_colors.dart';
import '../../../core/theme/k_tokens.dart';
import '../../../core/theme/k_typography.dart';
import '../../../core/validators/k_validators.dart';
import '../../../core/widgets/k_mensagem_erro.dart';

/// Campo do código SMS desenhado como 6 caixas (ecrã 11). Um campo de texto
/// invisível recebe os dígitos (teclado numérico, só números, máximo 6); a
/// caixa seguinte à última escrita aparece com contorno laranja.
class CodigoCaixas extends StatefulWidget {
  const CodigoCaixas({
    super.key,
    required this.controller,
    this.erro,
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String? erro;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  static const _alturaCaixa = K.botaoAltura + K.s8;

  @override
  State<CodigoCaixas> createState() => _CodigoCaixasState();
}

class _CodigoCaixasState extends State<CodigoCaixas> {
  final _foco = FocusNode();

  @override
  void initState() {
    super.initState();
    _foco.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _foco.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final temErro = widget.erro != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          textField: true,
          label: 'Código de ${KValidators.digitosCodigo} dígitos',
          child: Stack(
            children: [
              ExcludeSemantics(
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: widget.controller,
                  builder: (_, valor, _) => Row(
                    children: [
                      for (var i = 0; i < KValidators.digitosCodigo; i++) ...[
                        if (i > 0) const SizedBox(width: K.s8 + 2),
                        Expanded(
                          child: _Caixa(
                            digito: i < valor.text.length ? valor.text[i] : '',
                            ativa:
                                _foco.hasFocus &&
                                i ==
                                    valor.text.length.clamp(
                                      0,
                                      KValidators.digitosCodigo - 1,
                                    ),
                            erro: temErro,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              // Campo real, invisível, por cima das caixas.
              Positioned.fill(
                child: Opacity(
                  opacity: 0,
                  child: TextField(
                    controller: widget.controller,
                    focusNode: _foco,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    maxLength: KValidators.digitosCodigo,
                    showCursor: false,
                    enableInteractiveSelection: false,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: widget.onChanged,
                    onSubmitted: widget.onSubmitted,
                    decoration: const InputDecoration(
                      counterText: '',
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (temErro)
          Padding(
            padding: const EdgeInsets.only(top: K.s8),
            child: KMensagemErro(widget.erro!),
          ),
      ],
    );
  }
}

class _Caixa extends StatelessWidget {
  const _Caixa({required this.digito, required this.ativa, required this.erro});

  final String digito;
  final bool ativa;
  final bool erro;

  @override
  Widget build(BuildContext context) {
    final cor = erro
        ? KColors.erro
        : ativa
        ? KColors.laranja
        : KColors.areia400;
    return Container(
      height: CodigoCaixas._alturaCaixa,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: KColors.branco,
        borderRadius: BorderRadius.circular(K.raioBotao),
        border: Border.all(color: cor, width: ativa || erro ? 2 : 1),
      ),
      child: Text(digito, style: KTypography.titulo24),
    );
  }
}
