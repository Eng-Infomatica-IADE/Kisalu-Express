import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/k_colors.dart';
import '../../../core/theme/k_icons.dart';
import '../../../core/theme/k_tokens.dart';
import '../../../core/theme/k_typography.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/repositories/kisalu_repository.dart';
import '../../../models/verificacao_identidade.dart';
import '../controllers/verificar_identidade_controller.dart';
import '../widgets/linha_documento.dart';

/// Ecrã 13 · Verificar identidade (passo 2 de 2) — ver
/// docs/design/SCREENS.md#ecra-13.
class VerificarIdentidadeView extends StatelessWidget {
  const VerificarIdentidadeView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (c) =>
          VerificarIdentidadeController(c.read<KisaluRepository>())..carregar(),
      child: const _Conteudo(),
    );
  }
}

class _Conteudo extends StatelessWidget {
  const _Conteudo();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<VerificarIdentidadeController>();
    final margem = K.margemPara(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const KTopBar(titulo: 'Verificar identidade'),
            Expanded(
              child: KEstadoBuilder<VerificacaoIdentidade>(
                estado: c.estado,
                onTentar: c.carregar,
                carregar: (_) => Padding(
                  padding: EdgeInsets.all(margem),
                  child: const KSkeletonLista(),
                ),
                vazio: (_) => const SizedBox(),
                sucesso: (context, verificacao) =>
                    _Passo(verificacao: verificacao, margem: margem),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Passo extends StatelessWidget {
  const _Passo({required this.verificacao, required this.margem});

  final VerificacaoIdentidade verificacao;
  final double margem;

  Future<void> _enviar(BuildContext context) async {
    final c = context.read<VerificarIdentidadeController>();
    final enviado = await c.enviar();
    if (!enviado || !context.mounted) return;
    mostrarKSnack(context, 'Enviado para verificação.');
    context.go(AppRoutes.inicio);
  }

  Future<void> _adicionarDocumento(BuildContext context) async {
    final c = context.read<VerificarIdentidadeController>();
    final guardado = await c.adicionarDocumento();
    if (!guardado || !context.mounted) return;
    mostrarKSnack(context, 'Documento guardado.');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<VerificarIdentidadeController>();
    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(margem, K.s4, margem, K.s16 + 3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const KStepProgress(
                  total: 2,
                  atual: 2,
                  legenda: 'Selo Verificado',
                ),
                const SizedBox(height: K.s16),
                const _BannerSelo(),
                const SizedBox(height: K.s16),
                KCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: K.s16 - 1,
                    vertical: K.s8,
                  ),
                  child: Column(
                    children: [
                      LinhaDocumento(
                        icone: KIcons.documento,
                        titulo: 'Documento de identidade',
                        descricao: verificacao.documentoEnviado
                            ? 'Frente e verso'
                            : 'Toque para fotografar frente e verso',
                        acao: verificacao.documentoEnviado ? 'Alterar' : null,
                        descricaoAcao: !verificacao.documentoEnviado,
                        enviado: verificacao.documentoEnviado,
                        onTap: () => _adicionarDocumento(context),
                      ),
                      const SizedBox(height: K.s8),
                      LinhaDocumento(
                        icone: KIcons.foto,
                        titulo: 'Fotografia do rosto',
                        descricao: verificacao.rostoEnviado
                            ? 'Para comparar com o documento'
                            : 'Toque para tirar a fotografia',
                        descricaoAcao: !verificacao.rostoEnviado,
                        enviado: verificacao.rostoEnviado,
                        onTap: verificacao.rostoEnviado
                            ? null
                            : c.adicionarFotoRosto,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: K.s12),
                const _NotaPrivacidade(),
                const Spacer(),
                const SizedBox(height: K.s24),
                if (!verificacao.rostoEnviado) ...[
                  Text(
                    'Falta a fotografia do rosto para poder enviar.',
                    textAlign: TextAlign.center,
                    style: KTypography.corpo13.copyWith(
                      color: KColors.neutro700,
                    ),
                  ),
                  const SizedBox(height: K.s12),
                ],
                if (c.erro != null) ...[
                  KInlineAlert(
                    tipo: KAlertaTipo.aviso,
                    titulo: 'Falta um passo.',
                    mensagem: c.erro!,
                  ),
                  const SizedBox(height: K.s12),
                ],
                KPrimaryButton(
                  rotulo: 'Enviar para verificação',
                  aCarregar: c.aEnviar,
                  // Só fica ativo quando os dois documentos estão enviados.
                  onPressed:
                      verificacao.documentoEnviado && verificacao.rostoEnviado
                      ? () => _enviar(context)
                      : null,
                ),
                const SizedBox(height: K.s4 + 1),
                Center(
                  child: KTextLink(
                    grande: true,
                    rotulo: 'Fazer mais tarde',
                    onPressed: () => context.go(AppRoutes.inicio),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// "Com o selo Verificado, os clientes sabem quem entra em casa deles."
class _BannerSelo extends StatelessWidget {
  const _BannerSelo();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: K.s16,
        vertical: K.s12 + K.s4 / 2,
      ),
      decoration: BoxDecoration(
        color: KColors.sucessoFundo,
        borderRadius: BorderRadius.circular(K.raioCartao - K.s4),
      ),
      child: Row(
        children: [
          const ExcludeSemantics(
            child: Icon(
              KIcons.verificado,
              size: K.icone24,
              color: KColors.sucesso,
            ),
          ),
          const SizedBox(width: K.s12),
          Expanded(
            child: Text(
              'Com o selo Verificado, os clientes sabem quem entra em casa '
              'deles.',
              style: Theme.of(context).textTheme.bodyLarge!
                  .copyWith(height: 20 / 16),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotaPrivacidade extends StatelessWidget {
  const _NotaPrivacidade();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: ExcludeSemantics(
            child: Icon(
              KIcons.cadeado,
              size: K.icone16,
              color: KColors.neutro500,
            ),
          ),
        ),
        const SizedBox(width: K.s12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Usamos estes dados só para verificar a identidade. O '
                'documento não é mostrado a clientes.',
                style: Theme.of(context).textTheme.bodyMedium!
                    .copyWith(color: KColors.neutro700, height: 18 / 14),
              ),
              const SizedBox(height: K.s8),
              Text(
                'Depois de enviar, avisamos por SMS com o resultado.',
                style: KTypography.corpo13.copyWith(color: KColors.neutro500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
