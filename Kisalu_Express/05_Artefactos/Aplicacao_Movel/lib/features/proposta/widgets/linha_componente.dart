import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/k_colors.dart';
import '../../../core/theme/k_icons.dart';
import '../../../core/theme/k_tokens.dart';
import '../../../core/utils/k_format.dart';
import '../../../core/validators/k_validators.dart';
import '../../../core/widgets/k_mensagem_erro.dart';

/// Linha "Mão de obra … 8.000 Kz" do ecrã 15. O valor é um campo com
/// contorno e lápis, para se ver que se pode alterar (v3.1); ao sair do
/// campo fica formatado ("8.000 Kz"). Alvo de toque de 48 dp.
class LinhaComponente extends StatefulWidget {
  const LinhaComponente({
    super.key,
    required this.rotulo,
    required this.valorInicial,
    required this.onChanged,
    required this.onSaiu,
    this.erro,
  });

  final String rotulo;
  final int valorInicial;
  final ValueChanged<String> onChanged;

  /// Chamado ao perder o foco, já com o texto atual.
  final ValueChanged<String> onSaiu;
  final String? erro;

  @override
  State<LinhaComponente> createState() => _LinhaComponenteState();
}

class _LinhaComponenteState extends State<LinhaComponente> {
  late final _texto = TextEditingController(
    text: KFormat.milhares(widget.valorInicial),
  );
  final _foco = FocusNode();

  @override
  void initState() {
    super.initState();
    _foco.addListener(_aoMudarFoco);
  }

  void _aoMudarFoco() {
    if (_foco.hasFocus) {
      _texto.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _texto.text.length,
      );
      return;
    }
    final inteiro = KValidators.kzParaInteiro(_texto.text);
    if (inteiro != null) _texto.text = KFormat.milhares(inteiro);
    widget.onSaiu(_texto.text);
  }

  @override
  void dispose() {
    _foco.removeListener(_aoMudarFoco);
    _foco.dispose();
    _texto.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final corpo = Theme.of(context).textTheme.bodyLarge!;
    final negrito = corpo.copyWith(fontWeight: FontWeight.w700);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: K.alvoMinimo),
          child: Row(
            children: [
              Expanded(child: Text(widget.rotulo, style: corpo)),
              const SizedBox(width: K.s8),
              SizedBox(
                width: K.alvoMinimo * 2 + K.s16 + K.s12,
                child: Semantics(
                  textField: true,
                  label: '${widget.rotulo}, valor em kwanzas',
                  child: TextField(
                    controller: _texto,
                    focusNode: _foco,
                    textAlign: TextAlign.right,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9. ]')),
                    ],
                    style: negrito,
                    cursorColor: KColors.laranja,
                    onChanged: widget.onChanged,
                    decoration: InputDecoration(
                      isDense: true,
                      filled: false,
                      border: _contorno(KColors.areia400),
                      enabledBorder: _contorno(KColors.areia400),
                      focusedBorder: _contorno(KColors.laranja, largura: 2),
                      prefixIcon: const ExcludeSemantics(
                        child: Icon(
                          KIcons.editar,
                          size: K.icone16,
                          color: KColors.neutro500,
                        ),
                      ),
                      prefixIconConstraints: const BoxConstraints(
                        minWidth: K.s32,
                      ),
                      contentPadding: const EdgeInsets.fromLTRB(
                        0,
                        K.s8,
                        K.s12,
                        K.s8,
                      ),
                      suffixText: ' Kz',
                      suffixStyle: negrito,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (widget.erro != null)
          Padding(
            padding: const EdgeInsets.only(bottom: K.s4),
            child: KMensagemErro(widget.erro!),
          ),
      ],
    );
  }
}

OutlineInputBorder _contorno(Color cor, {double largura = 1}) =>
    OutlineInputBorder(
      borderRadius: BorderRadius.circular(K.raioInclui),
      borderSide: BorderSide(color: cor, width: largura),
    );
