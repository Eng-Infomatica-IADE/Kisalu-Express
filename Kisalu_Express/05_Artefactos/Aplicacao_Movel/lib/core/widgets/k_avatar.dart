import 'package:flutter/material.dart';

import '../theme/k_colors.dart';
import '../theme/k_tokens.dart';
import '../theme/k_typography.dart';

/// Avatar com iniciais (Sora 800, Brasa) sobre círculo tom claro
/// (Style Guide, p. 9). Decorativo: o nome aparece sempre ao lado, por isso
/// o leitor de ecrã ignora-o. O selo Verificado fica junto ao nome, nunca
/// por cima do avatar.
class KAvatar extends StatelessWidget {
  const KAvatar({super.key, required this.nome, this.tamanho = K.avatarMedio});

  final String nome;

  /// [K.avatarPequeno] · [K.avatarMedio] · [K.avatarGrande]
  final double tamanho;

  /// Altura das iniciais em fração do círculo.
  static const _fracaoLetra = .34;

  /// "Joaquim Manuel" → "JM"; "Maria S." → "MS".
  static String iniciais(String nome) => nome
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .take(2)
      .map((p) => p.characters.first.toUpperCase())
      .join();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: tamanho,
        height: tamanho,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: KColors.tomClaro,
          shape: BoxShape.circle,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: EdgeInsets.all(tamanho * .1),
            child: Text(
              iniciais(nome),
              style: KTypography.preco(size: tamanho * _fracaoLetra)
                  .copyWith(color: KColors.brasa),
            ),
          ),
        ),
      ),
    );
  }
}
