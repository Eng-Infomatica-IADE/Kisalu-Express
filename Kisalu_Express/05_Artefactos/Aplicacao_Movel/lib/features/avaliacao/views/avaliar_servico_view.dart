import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/k_colors.dart';
import '../../../core/theme/k_icons.dart';
import '../../../core/theme/k_tokens.dart';
import '../../../core/theme/k_typography.dart';
import '../../../core/utils/k_format.dart';
import '../../../core/validators/k_validators.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/repositories/kisalu_repository.dart';
import '../../../models/avaliacao.dart';
import '../../../models/comprovativo.dart';
import '../controllers/avaliar_servico_controller.dart';

/// Ecrã 06 · Avaliar serviço — ver docs/design/SCREENS.md#ecra-06.
class AvaliarServicoView extends StatelessWidget {
  const AvaliarServicoView({super.key, required this.pedidoId});
  final String pedidoId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) =>
          AvaliarServicoController(context.read<KisaluRepository>(), pedidoId)
            ..carregar(),
      child: const _Conteudo(),
    );
  }
}

class _Conteudo extends StatelessWidget {
  const _Conteudo();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AvaliarServicoController>();
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const KTopBar(titulo: 'Avaliar serviço'),
            Expanded(
              child: KEstadoBuilder<Comprovativo>(
                estado: controller.estado,
                onTentar: controller.carregar,
                rotuloNaoEncontrado: 'Ver os meus pedidos',
                onNaoEncontrado: () => context.go(AppRoutes.pedidos),
                vazio: (_) => const SizedBox.shrink(),
                sucesso: (context, comprovativo) =>
                    _Formulario(comprovativo: comprovativo),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Formulario extends StatefulWidget {
  const _Formulario({required this.comprovativo});

  final Comprovativo comprovativo;

  @override
  State<_Formulario> createState() => _FormularioState();
}

class _FormularioState extends State<_Formulario> {
  late final TextEditingController _comentario = TextEditingController(
    text: context.read<AvaliarServicoController>().comentario,
  );

  @override
  void dispose() {
    _comentario.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final controller = context.read<AvaliarServicoController>();
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (!await controller.enviar()) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Avaliação enviada. Obrigado!')),
      );
    router.go(AppRoutes.pedidos);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AvaliarServicoController>();
    final text = Theme.of(context).textTheme;
    final margem = K.margemPara(context);
    final c = widget.comprovativo;
    final primeiroNome = c.profissional.primeiroNome;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(margem, K.s12, margem, K.s24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: K.sucessoCirculo,
              height: K.sucessoCirculo,
              decoration: const BoxDecoration(
                color: KColors.sucessoFundo,
                shape: BoxShape.circle,
              ),
              child: const ExcludeSemantics(
                child: Icon(
                  KIcons.concluido,
                  size: K.icone40,
                  color: KColors.sucesso,
                ),
              ),
            ),
          ),
          const SizedBox(height: K.s8 + K.s4 / 2),
          Semantics(
            header: true,
            child: Text(
              'Serviço confirmado',
              textAlign: TextAlign.center,
              style: KTypography.titulo22,
            ),
          ),
          const SizedBox(height: K.s8),
          // O alvo de 48 dp da ligação entra na folga do texto de cima.
          Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: K.s32 + K.s8 + 2),
                child: Center(
                  child: Text(
                    '${c.servico} · ${KFormat.kz(c.valor)}',
                    textAlign: TextAlign.center,
                    style: text.bodyMedium!.copyWith(color: KColors.neutro500),
                  ),
                ),
              ),
              KTextLink(
                rotulo: 'Comprovativo guardado em Pedidos · Ver',
                pequeno: true,
                onPressed: () => context.go(AppRoutes.pedidos),
              ),
            ],
          ),
          KCard(
            padding: const EdgeInsets.all(K.s16 + K.s4),
            child: Column(
              children: [
                Row(
                  children: [
                    KAvatar(
                      nome: c.profissional.nome,
                      tamanho: K.avatarAvaliar,
                    ),
                    const SizedBox(width: K.s12),
                    Expanded(
                      child: Text(
                        'Como correu com o $primeiroNome?',
                        style: text.titleMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: K.s16),
                KEstrelas(
                  valor: controller.estrelas,
                  onAlterar: controller.definirEstrelas,
                ),
                const SizedBox(height: K.s12 + K.s4),
                if (controller.erroEstrelas != null)
                  Text(
                    controller.erroEstrelas!,
                    textAlign: TextAlign.center,
                    style: text.bodyMedium!.copyWith(color: KColors.erro),
                  )
                else
                  Text(
                    controller.rotuloEstrelas,
                    textAlign: TextAlign.center,
                    style: text.bodyMedium!.copyWith(
                      color: KColors.laranja,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: K.s12 + K.s4 / 2),
          Semantics(
            header: true,
            child: Text(
              'O que correu bem?',
              style: text.titleMedium!.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: K.s4 + K.s4 / 2),
          Wrap(
            spacing: K.s8,
            runSpacing: K.chipEntreLinhas,
            children: [
              for (final e in EtiquetaAvaliacao.values)
                KChip(
                  rotulo: e.rotulo,
                  variante: KChipVariante.etiqueta,
                  selecionado: controller.etiquetas.contains(e),
                  onSelecionar: (_) => controller.alternarEtiqueta(e),
                ),
            ],
          ),
          const SizedBox(height: K.s8),
          KTextField(
            rotulo: 'Comentário (opcional)',
            rotuloVisivel: false,
            controller: _comentario,
            linhas: 3,
            maxCaracteres: KValidators.maxComentario,
            mostrarContador: false,
            estilo: KTypography.corpo15,
            erro: controller.erroComentario,
            onChanged: controller.alterarComentario,
          ),
          if (controller.erroEnvio != null) ...[
            const SizedBox(height: K.s8),
            KInlineAlert(
              tipo: KAlertaTipo.erro,
              titulo: 'Não foi possível enviar.',
              mensagem: controller.erroEnvio!,
            ),
          ],
          const SizedBox(height: K.s12 + K.s4 / 2),
          KPrimaryButton(
            rotulo: 'Enviar avaliação',
            aCarregar: controller.aEnviar,
            onPressed: _enviar,
          ),
          Center(
            child: KTextLink(
              rotulo: 'Avaliar mais tarde',
              onPressed: () => context.go(AppRoutes.pedidos),
            ),
          ),
        ],
      ),
    );
  }
}
