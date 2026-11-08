import 'package:flutter/material.dart';

import '../../../core/theme/k_colors.dart';
import '../../../core/theme/k_tokens.dart';
import '../../../core/theme/k_typography.dart';
import '../../../core/utils/k_format.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/profissional.dart';

/// Cabeçalho laranja (gradiente) com voltar e VERIFICADO, e o cartão do
/// profissional sobreposto (ecrã 03).
class CabecalhoPerfil extends StatelessWidget {
  const CabecalhoPerfil({super.key, required this.profissional});

  final Profissional profissional;

  /// Folga do alvo de 48 dp à volta do quadrado do voltar.
  static const _folga = (K.alvoMinimo - K.botaoIcone) / 2;

  /// Altura do laranja abaixo da barra de estado, e quanto o cartão o cobre.
  static const _alturaLaranja = 140.0;
  static const _sobreposicao = 68.0;

  @override
  Widget build(BuildContext context) {
    final topo = MediaQuery.paddingOf(context).top;
    final margem = K.margemPara(context);
    final p = profissional;
    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: topo + _alturaLaranja,
          child: const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [KColors.laranja, KColors.laranjaVivo],
              ),
            ),
          ),
        ),
        Positioned(
          top: topo + K.s8,
          left: margem - _folga,
          right: margem,
          child: Row(
            children: [
              const KBackButton(),
              const Spacer(),
              if (p.verificado) KStatusBadge.verificado(sobreCor: true),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            margem,
            topo + _alturaLaranja - _sobreposicao,
            margem,
            0,
          ),
          child: _CartaoPerfil(profissional: p),
        ),
      ],
    );
  }
}

class _CartaoPerfil extends StatelessWidget {
  const _CartaoPerfil({required this.profissional});

  final Profissional profissional;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = profissional;
    return SizedBox(
      width: double.infinity,
      child: KCard(
        padding: const EdgeInsets.fromLTRB(
          K.s16 + K.s4,
          K.s16 + K.s4,
          K.s16 + K.s4,
          K.s16 + K.s4,
        ),
        child: Column(
          children: [
            KAvatar(nome: p.nome, tamanho: K.avatarGrande),
            const SizedBox(height: K.s12 + K.s4 - 1),
            Semantics(
              header: true,
              child: Text(
                p.nome,
                textAlign: TextAlign.center,
                style: KTypography.titulo22,
              ),
            ),
            const SizedBox(height: K.s12 + 1),
            Text(
              '${p.categoria} · ${p.zona}',
              textAlign: TextAlign.center,
              style: text.bodyMedium!.copyWith(color: KColors.neutro500),
            ),
            const SizedBox(height: K.s12 + 1),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Metrica(valor: KFormat.decimal(p.rating), rotulo: 'Avaliação'),
                _Metrica(valor: '${p.servicosConfirmados}', rotulo: 'Serviços'),
                _Metrica(
                  valor: KFormat.anos(p.anosExperiencia),
                  rotulo: 'Experiência',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Metrica extends StatelessWidget {
  const _Metrica({required this.valor, required this.rotulo});

  final String valor;
  final String rotulo;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Flexible(
      child: Semantics(
        label: '$rotulo: $valor',
        excludeSemantics: true,
        child: Column(
          children: [
            Text(
              valor,
              textAlign: TextAlign.center,
              style: KTypography.preco().copyWith(color: KColors.laranja),
            ),
            const SizedBox(height: K.s4 / 2),
            Text(
              rotulo,
              textAlign: TextAlign.center,
              style: text.bodySmall!.copyWith(
                color: KColors.neutro500,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
