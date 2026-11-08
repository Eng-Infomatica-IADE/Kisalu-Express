import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/k_colors.dart';
import '../theme/k_icons.dart';
import '../theme/k_tokens.dart';
import '../theme/k_typography.dart';

/// Campo de formulário do Style Guide (cap. 06, p. 11).
///
/// - Rótulo visível por cima (o placeholder não é rótulo). Com
///   `rotuloVisivel: false` (comentário do 06) é só o nome acessível.
/// - 52 dp, texto 16 sp (o iOS não faz zoom), raio 14.
/// - Borda `areia400` (3,5:1, RNF01) · foco laranja 2 dp com halo tom claro
///   · erro e sucesso com ícone + texto · desativado em `areia100`.
/// - Validar depois de sair do campo ([onSaiu]), nunca enquanto se escreve:
///   quem usa o campo decide e passa [erro] ou [sucesso].
class KTextField extends StatefulWidget {
  const KTextField({
    super.key,
    required this.rotulo,
    this.rotuloVisivel = true,
    this.controller,
    this.focusNode,
    this.dica,
    this.ajuda,
    this.erro,
    this.sucesso,
    this.icone,
    this.ativo = true,
    this.linhas = 1,
    this.maxCaracteres,
    this.mostrarContador = true,
    this.estilo,
    this.teclado,
    this.acaoTeclado,
    this.formatadores,
    this.onChanged,
    this.onSaiu,
    this.onSubmitted,
  });

  final String rotulo;
  final bool rotuloVisivel;
  final TextEditingController? controller;
  final FocusNode? focusNode;

  /// Placeholder (ex. "+244 9__ ___ ___").
  final String? dica;

  /// Texto de ajuda por baixo (ex. "Enviamos um código por SMS.").
  final String? ajuda;

  /// Mensagem de erro que ensina ("Faltam 3 números. …"). Tem prioridade.
  final String? erro;

  /// Mensagem de sucesso ("Número confirmado.").
  final String? sucesso;
  final IconData? icone;
  final bool ativo;

  /// > 1 → área de texto.
  final int linhas;

  /// Limita o texto; com [mostrarContador] mostra "36 / 300".
  final int? maxCaracteres;
  final bool mostrarContador;

  /// Estilo do texto; por omissão `bodyLarge`.
  final TextStyle? estilo;
  final TextInputType? teclado;
  final TextInputAction? acaoTeclado;
  final List<TextInputFormatter>? formatadores;
  final ValueChanged<String>? onChanged;

  /// Chamado quando o campo perde o foco — momento de validar.
  final VoidCallback? onSaiu;
  final ValueChanged<String>? onSubmitted;

  @override
  State<KTextField> createState() => _KTextFieldState();
}

class _KTextFieldState extends State<KTextField> {
  TextEditingController? _controllerProprio;
  FocusNode? _focusProprio;

  TextEditingController get _controller =>
      widget.controller ?? (_controllerProprio ??= TextEditingController());
  FocusNode get _focus => widget.focusNode ?? (_focusProprio ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _focus.addListener(_aoMudarFoco);
  }

  void _aoMudarFoco() {
    setState(() {});
    if (!_focus.hasFocus) widget.onSaiu?.call();
  }

  @override
  void dispose() {
    _focus.removeListener(_aoMudarFoco);
    _controllerProprio?.dispose();
    _focusProprio?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final temErro = widget.erro != null;
    final temSucesso = !temErro && widget.sucesso != null;
    final focado = _focus.hasFocus && widget.ativo;

    final Color corBorda = temErro
        ? KColors.erro
        : temSucesso
        ? KColors.sucesso
        : focado
        ? KColors.laranja
        : KColors.areia400;
    final larguraBorda = (temErro || temSucesso || focado) ? 2.0 : 1.0;

    OutlineInputBorder borda(Color cor, double largura) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(K.raioBotao),
      borderSide: BorderSide(color: cor, width: largura),
    );

    final campo = AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(K.raioBotao),
        boxShadow: focado && !temErro && !temSucesso
            ? const [BoxShadow(color: KColors.tomClaro, spreadRadius: 4)]
            : null,
      ),
      child: TextField(
        controller: _controller,
        focusNode: _focus,
        enabled: widget.ativo,
        minLines: widget.linhas,
        maxLines: widget.linhas == 1 ? 1 : widget.linhas + 2,
        maxLength: widget.maxCaracteres,
        keyboardType: widget.linhas > 1
            ? TextInputType.multiline
            : widget.teclado,
        textInputAction: widget.acaoTeclado,
        inputFormatters: widget.formatadores,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        style: (widget.estilo ?? text.bodyLarge!).copyWith(
          color: widget.ativo ? KColors.ebano : KColors.neutro500,
        ),
        cursorColor: KColors.laranja,
        decoration: InputDecoration(
          hintText: widget.dica,
          hintStyle: text.bodyLarge!.copyWith(color: KColors.neutro500),
          filled: true,
          fillColor: widget.ativo ? KColors.branco : KColors.areia100,
          counterText: '', // contador próprio, por baixo à direita
          contentPadding: widget.linhas > 1
              ? const EdgeInsets.fromLTRB(K.s16, K.s16, K.s16, K.s24 + K.s4 / 2)
              : const EdgeInsets.symmetric(
                  horizontal: K.s16,
                  vertical: K.s16 + K.s4 / 2,
                ),
          prefixIcon: widget.icone == null
              ? null
              : Icon(
                  widget.icone,
                  size: K.icone20,
                  color: widget.ativo ? KColors.neutro700 : KColors.neutro500,
                ),
          enabledBorder: borda(corBorda, larguraBorda),
          focusedBorder: borda(corBorda, larguraBorda),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(K.raioBotao),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );

    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.rotuloVisivel) ...[
            Text(
              widget.rotulo,
              style: KTypography.corpo13.copyWith(
                color: widget.ativo ? KColors.neutro700 : KColors.neutro500,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: K.s4),
          ],
          if (widget.rotuloVisivel)
            campo
          else
            Semantics(label: widget.rotulo, textField: true, child: campo),
          _Rodape(
            erro: widget.erro,
            sucesso: temSucesso ? widget.sucesso : null,
            ajuda: widget.ajuda,
            controller: _controller,
            maxCaracteres: widget.mostrarContador ? widget.maxCaracteres : null,
          ),
        ],
      ),
    );
  }
}

/// Mensagem (erro > sucesso > ajuda) à esquerda e contador à direita.
class _Rodape extends StatelessWidget {
  const _Rodape({
    required this.erro,
    required this.sucesso,
    required this.ajuda,
    required this.controller,
    required this.maxCaracteres,
  });

  final String? erro;
  final String? sucesso;
  final String? ajuda;
  final TextEditingController controller;
  final int? maxCaracteres;

  @override
  Widget build(BuildContext context) {
    final estilo = KTypography.corpo13;
    final (IconData? icone, String? mensagem, Color cor) = erro != null
        ? (KIcons.aviso, erro, KColors.erro)
        : sucesso != null
        ? (KIcons.concluido, sucesso, KColors.sucesso)
        : (null, ajuda, KColors.neutro700);

    if (mensagem == null && maxCaracteres == null) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.only(top: K.s4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icone != null) ...[
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(icone, size: K.icone16, color: cor),
            ),
            const SizedBox(width: K.s4),
          ],
          Expanded(
            child: mensagem == null
                ? const SizedBox()
                : Text(
                    mensagem,
                    style: estilo.copyWith(
                      color: cor,
                      fontWeight: erro != null ? FontWeight.w500 : null,
                    ),
                  ),
          ),
          if (maxCaracteres != null)
            ValueListenableBuilder(
              valueListenable: controller,
              builder: (_, valor, _) => Padding(
                padding: const EdgeInsets.only(left: K.s8),
                child: Text(
                  '${valor.text.characters.length} / $maxCaracteres',
                  style: estilo.copyWith(color: KColors.neutro500),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
