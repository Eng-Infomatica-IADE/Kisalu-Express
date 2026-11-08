import 'package:flutter/material.dart';

import '../theme/k_colors.dart';
import '../theme/k_tokens.dart';
import '../theme/k_typography.dart';

enum KBotaoVariante { primario, secundario, texto }

class KBotaoBase extends StatefulWidget {
  const KBotaoBase({
    super.key,
    required this.variante,
    required this.rotulo,
    required this.onPressed,
    this.icone,
    this.aCarregar = false,
    this.larguraTotal = true,
    this.compacto = false,
    this.destrutivo = false,
    this.pequeno = false,
    this.grande = false,
  });

  final KBotaoVariante variante;
  final String rotulo;
  final VoidCallback? onPressed;
  final IconData? icone;
  final bool aCarregar;
  final bool larguraTotal;
  final bool compacto;
  final bool destrutivo;
  final bool pequeno;

  /// Texto de 15 sp (ligações maiores, como no Figma v3).
  final bool grande;

  @override
  State<KBotaoBase> createState() => _KBotaoState();
}

class _KBotaoState extends State<KBotaoBase> {
  bool _premido = false;
  bool _foco = false;

  bool get _ativo => widget.onPressed != null;
  bool get _interativo => _ativo && !widget.aCarregar;

  void _premir(bool valor) {
    if (_interativo && _premido != valor) setState(() => _premido = valor);
  }

  ({Color fundo, Color texto, Color? borda}) _cores() {
    final destrutivo = widget.destrutivo;
    switch (widget.variante) {
      case KBotaoVariante.primario:
        if (!_ativo) {
          return (
            fundo: KColors.areia200,
            texto: KColors.neutro500,
            borda: null,
          );
        }
        final normal = destrutivo ? KColors.erro : KColors.laranja;
        final premido = destrutivo ? KColors.erroPremido : KColors.brasa;
        return (
          fundo: _premido ? premido : normal,
          texto: KColors.branco,
          borda: null,
        );
      case KBotaoVariante.secundario:
        if (!_ativo) {
          return (
            fundo: KColors.areia200,
            texto: KColors.neutro500,
            borda: null,
          );
        }
        return (
          fundo: _premido ? KColors.tomClaro : KColors.branco,
          texto: KColors.laranja,
          borda: KColors.laranja,
        );
      case KBotaoVariante.texto:
        final cor = destrutivo ? KColors.erro : KColors.laranja;
        return (
          fundo: _premido ? KColors.tomClaro : Colors.transparent,
          texto: _ativo ? cor : KColors.neutro500,
          borda: null,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final cores = _cores();
    final ehTexto = widget.variante == KBotaoVariante.texto;

    final estiloTexto =
        (widget.pequeno
                ? KTypography.corpo13.copyWith(fontWeight: FontWeight.w700)
                : ehTexto && widget.grande
                ? KTypography.corpo15.copyWith(fontWeight: FontWeight.w700)
                : ehTexto
                ? textTheme.labelMedium!
                : textTheme.labelLarge!)
            .copyWith(color: cores.texto);

    final secundarioGrande =
        widget.variante == KBotaoVariante.secundario &&
        widget.larguraTotal &&
        !widget.compacto;
    final alturaMinima = ehTexto
        ? K.alvoMinimo
        : widget.compacto
        ? K.alvoMinimo
        : secundarioGrande
        ? K.botaoAltura + K.s4 - 1
        : widget.larguraTotal
        ? K.botaoAltura
        : K.botaoAltura - K.s4 / 2;
    final paddingH = ehTexto ? 0.0 : (widget.compacto ? K.s16 : K.s24);

    final conteudo = widget.aCarregar
        ? SizedBox.square(
            dimension: K.icone20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: widget.variante == KBotaoVariante.primario
                  ? KColors.branco
                  : KColors.laranja,
              backgroundColor: cores.texto.withValues(alpha: .3),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icone != null) ...[
                Icon(
                  widget.icone,
                  size: ehTexto ? K.icone16 : K.icone20,
                  color: cores.texto,
                ),
                SizedBox(width: ehTexto ? K.s4 : K.s8),
              ],
              Flexible(
                child: Text(
                  widget.rotulo,
                  textAlign: TextAlign.center,
                  style: estiloTexto,
                ),
              ),
            ],
          );

    final botao = AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      constraints: BoxConstraints(minHeight: alturaMinima),
      width: widget.larguraTotal ? double.infinity : null,
      padding: EdgeInsets.symmetric(
        horizontal: paddingH,
        // Sem largura total não há centragem: o padding centra o texto.
        vertical: widget.larguraTotal
            ? K.s8
            : (widget.compacto ? K.s12 : K.s12 + K.s4 / 2),
      ),
      alignment: widget.larguraTotal ? Alignment.center : null,
      decoration: BoxDecoration(
        color: cores.fundo,
        borderRadius: BorderRadius.circular(K.raioBotao),
        border: cores.borda == null
            ? null
            : Border.all(color: cores.borda!, width: 1.5),
      ),
      // Sem largura total, o conteúdo (Row mínimo com texto Flexible) define
      // a largura e o texto quebra linha se faltar espaço.
      child: conteudo,
    );

    return Semantics(
      button: true,
      enabled: _ativo,
      label: widget.aCarregar ? '${widget.rotulo}, a carregar' : widget.rotulo,
      onTap: _interativo ? widget.onPressed : null,
      excludeSemantics: true,
      child: FocusableActionDetector(
        enabled: _interativo,
        mouseCursor: _interativo
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onShowFocusHighlight: (v) => setState(() => _foco = v),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) => widget.onPressed?.call(),
          ),
        },
        child: GestureDetector(
          excludeFromSemantics: true,
          onTapDown: (_) => _premir(true),
          onTapUp: (_) => _premir(false),
          onTapCancel: () => _premir(false),
          onTap: _interativo ? widget.onPressed : null,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              botao,
              if (_foco && _interativo)
                Positioned(
                  left: -5,
                  top: -5,
                  right: -5,
                  bottom: -5,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(color: KColors.ebano, width: 2),
                        borderRadius: BorderRadius.circular(K.raioBotao + 5),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
