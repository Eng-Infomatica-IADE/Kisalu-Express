import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/state/estado_ui.dart';
import '../../../core/theme/k_icons.dart';
import '../../../core/theme/k_tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/repositories/kisalu_repository.dart';
import '../../../models/pin_mapa.dart';
import '../controllers/mapa_controller.dart';
import '../widgets/mapa_estatico.dart';
import '../widgets/pin_profissional.dart';

/// Ecrã 22 · Mapa "Perto de si" — ver docs/design/SCREENS.md#ecra-22.
/// Mapa desenhado à mão (sem pacote de mapas, RM03): os pins são o
/// logótipo Kisalu e o cartão de baixo abre o perfil do profissional.
class MapaView extends StatelessWidget {
  const MapaView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (c) => MapaController(c.read<KisaluRepository>())..carregar(),
      child: const _Conteudo(),
    );
  }
}

class _Conteudo extends StatelessWidget {
  const _Conteudo();

  void _lista(BuildContext context) =>
      context.canPop() ? context.pop() : context.go(AppRoutes.inicio);

  @override
  Widget build(BuildContext context) {
    final c = context.watch<MapaController>();
    final margem = K.margemPara(context);
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: MapaEstatico()),
          if (c.estado case Sucesso(:final dados))
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, caixa) => Stack(
                  children: [
                    for (final pin in dados)
                      _PinPosicionado(pin: pin, caixa: caixa.biggest),
                  ],
                ),
              ),
            ),
          SafeArea(
            child: Column(
              children: [
                KTopBar(
                  // Título junto ao voltar, como nos outros ecrãs (v3.1).
                  titulo: 'Perto de si',
                  acao: KChipAcao(
                    rotulo: 'Lista',
                    icone: KIcons.pedidos,
                    onTap: () => _lista(context),
                  ),
                ),
                Expanded(
                  child: KEstadoBuilder<List<PinMapa>>(
                    estado: c.estado,
                    onTentar: c.carregar,
                    carregar: (_) => const SizedBox(),
                    vazio: (_) => Padding(
                      padding: EdgeInsets.all(margem),
                      child: const Center(
                        child: KEmptyState(
                          icone: KIcons.localizacao,
                          titulo: 'Sem profissionais no mapa',
                          mensagem:
                              'Ainda não há profissionais perto de si. '
                              'Tente alargar a zona de pesquisa.',
                        ),
                      ),
                    ),
                    sucesso: (context, _) {
                      final pin = c.selecionado;
                      return Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            margem,
                            0,
                            margem,
                            K.s32 + K.s4,
                          ),
                          // Rola se, com letra grande, não couber.
                          child: SingleChildScrollView(
                            reverse: true,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                KIconButton(
                                  icone: KIcons.recentrar,
                                  rotulo: 'Centrar no meu local',
                                  onPressed: () =>
                                      mostrarKSnack(context, 'Em breve'),
                                ),
                                const SizedBox(height: K.s12),
                                if (pin != null)
                                  KCartaoProfissional(
                                    profissional: pin.profissional,
                                    rotuloAcao: 'Ver perfil',
                                    seloEmTexto: true,
                                    onAbrir: () => context.push(
                                      AppRoutes.profissional(
                                        pin.profissional.id,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Coloca o pin com a ponta em (x, y) do mapa.
class _PinPosicionado extends StatelessWidget {
  const _PinPosicionado({required this.pin, required this.caixa});

  final PinMapa pin;
  final Size caixa;

  @override
  Widget build(BuildContext context) {
    final c = context.watch<MapaController>();
    const alvo = K.alvoMinimo;
    return Positioned(
      left: caixa.width * pin.x - alvo / 2,
      top: caixa.height * pin.y - (alvo + K.s4),
      child: PinProfissional(
        nome: pin.profissional.nome,
        selecionado: pin.profissional.id == c.selecionadoId,
        onTap: () => c.selecionar(pin.profissional.id),
      ),
    );
  }
}
