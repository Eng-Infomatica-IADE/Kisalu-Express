import 'package:flutter/material.dart';

import '../theme/k_colors.dart';
import '../theme/k_tokens.dart';

/// Botão só com ícone: quadrado branco de 44 dp, contorno areia, raio 14,
/// dentro de um alvo de toque de 48 dp. Usado no voltar, no "⋯" e no sino.
/// O [rotulo] é obrigatório: é o nome lido pelo leitor de ecrã (RNF09).
class KIconButton extends StatelessWidget {
  const KIconButton({
    super.key,
    required this.icone,
    required this.rotulo,
    required this.onPressed,
    this.mostrarPonto = false,
    this.contorno = true,
    this.escuro = false,
  });

  final IconData icone;
  final String rotulo;
  final VoidCallback? onPressed;

  /// Ponto vermelho de novidades (sino do Início, corrige P05).
  final bool mostrarPonto;

  /// false sobre fundos de cor (cabeçalho laranja do perfil).
  final bool contorno;

  /// Sobre fundo Ébano (ecrã 16): quadrado escuro, contorno discreto e ícone
  /// branco.
  final bool escuro;

  @override
  Widget build(BuildContext context) {
    final ativo = onPressed != null;
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(K.raioBotao),
      side: escuro
          ? const BorderSide(color: KColors.neutro700)
          : contorno
          ? const BorderSide(color: KColors.areia200)
          : BorderSide.none,
    );
    return SizedBox.square(
      dimension: K.alvoMinimo,
      child: Semantics(
        button: true,
        enabled: ativo,
        label: mostrarPonto ? '$rotulo, há novidades' : rotulo,
        onTap: onPressed,
        excludeSemantics: true,
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(K.raioBotao),
              highlightColor: KColors.tomClaro,
              splashColor: KColors.tomClaro,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Center(
                    child: Material(
                      color: escuro ? KColors.ebano : KColors.branco,
                      shape: forma,
                      child: SizedBox.square(
                        dimension: K.botaoIcone,
                        child: Icon(
                          icone,
                          size: K.icone24,
                          color: escuro
                              ? KColors.branco
                              : ativo
                              ? KColors.ebano
                              : KColors.neutro500,
                        ),
                      ),
                    ),
                  ),
                  if (mostrarPonto)
                    Positioned(
                      top: K.s12 + K.s4 / 2,
                      right: K.s12 + K.s4 / 2,
                      child: IgnorePointer(
                        child: Container(
                          width: K.s4 + K.s4 / 2,
                          height: K.s4 + K.s4 / 2,
                          decoration: const BoxDecoration(
                            color: KColors.erro,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
