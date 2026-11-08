import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/k_colors.dart';
import '../../../core/theme/k_tokens.dart';
import '../../../core/utils/k_format.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/repositories/kisalu_repository.dart';
import '../controllers/ler_qr_controller.dart';
import '../widgets/visor_qr.dart';

/// Ecrã 16 · Confirmar serviço (profissional) — ver
/// docs/design/SCREENS.md#ecra-16. Vive dentro do `AppShell` (separador QR em
/// modo profissional).
class LerQrView extends StatelessWidget {
  const LerQrView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (c) => LerQrController(c.read<KisaluRepository>())..carregar(),
      child: const _Conteudo(),
    );
  }
}

class _Conteudo extends StatelessWidget {
  const _Conteudo();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<LerQrController>();
    final margem = K.margemPara(context);
    return KAoVoltar(aoVoltar: c.recarregar, child: _corpo(context, c, margem));
  }

  Widget _corpo(BuildContext context, LerQrController c, double margem) {
    return ColoredBox(
      color: KColors.ebano,
      child: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, caixa) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: caixa.maxHeight),
              child: Column(
                children: [
                  KTopBar(
                    titulo: 'Confirmar serviço',
                    escuro: true,
                    onVoltar: () => context.go(AppRoutes.inicio),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(margem, K.s4 + 1, margem, 0),
                    child: Text(
                      // Ainda não há leitor de QR (sem pacote de câmara,
                      // RM03): não se promete a câmara (QA-17).
                      'Peça ao cliente o código de 6 dígitos que aparece '
                      'no ecrã dele.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                        color: KColors.branco.withValues(alpha: .85),
                      ),
                    ),
                  ),
                  if (c.trabalho != null)
                    Padding(
                      padding: EdgeInsets.fromLTRB(margem, K.s8, margem, 0),
                      child: Text(
                        '${c.trabalho!.servico} · ${c.trabalho!.cliente} · '
                        '${KFormat.kz(c.trabalho!.valor)}',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: KColors.branco,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  if (c.trabalhos.length > 1)
                    Padding(
                      padding: EdgeInsets.fromLTRB(margem, K.s12, margem, 0),
                      child: _ListaTrabalhos(c: c),
                    ),
                  SizedBox(height: c.trabalho == null ? K.s32 + K.s8 : K.s32),
                  const VisorQr(),
                  const SizedBox(height: K.s32 + K.s8 + 2),
                  Padding(
                    padding: EdgeInsets.fromLTRB(margem, 0, margem, K.s32 * 2),
                    child: KEstadoBuilder<String>(
                      estado: c.estado,
                      onTentar: c.carregar,
                      carregar: (_) => const KSkeletonLista(),
                      vazio: (_) => const _CartaoCodigo(inicial: ''),
                      sucesso: (_, codigo) => _CartaoCodigo(inicial: codigo),
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

/// Vários trabalhos à espera de código (QA-03): só para saber quais são; o
/// código de cada cliente confirma o trabalho certo.
class _ListaTrabalhos extends StatelessWidget {
  const _ListaTrabalhos({required this.c});

  final LerQrController c;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(K.s12),
      decoration: BoxDecoration(
        color: KColors.areia50,
        borderRadius: BorderRadius.circular(K.raioCartao),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Tem ${c.trabalhos.length} trabalhos por confirmar. O código do '
            'cliente diz qual é.',
            style: text.bodyMedium!.copyWith(fontWeight: FontWeight.w700),
          ),
          for (final t in c.trabalhos) ...[
            const SizedBox(height: K.s8),
            Text(
              '${t.servico} · ${t.cliente} · ${KFormat.kz(t.valor)}',
              style: text.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}

/// "Código de confirmação" + campo do código + "Confirmar serviço".
class _CartaoCodigo extends StatefulWidget {
  const _CartaoCodigo({required this.inicial});

  final String inicial;

  @override
  State<_CartaoCodigo> createState() => _CartaoCodigoState();
}

class _CartaoCodigoState extends State<_CartaoCodigo> {
  late final _codigo = TextEditingController(text: widget.inicial);

  @override
  void dispose() {
    _codigo.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    final c = context.read<LerQrController>();
    final pedidoId = await c.confirmar(_codigo.text);
    if (pedidoId != null && mounted) {
      context.push(AppRoutes.servicoConfirmado(pedidoId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<LerQrController>();
    return Container(
      padding: const EdgeInsets.all(K.s16),
      decoration: BoxDecoration(
        color: KColors.areia50,
        borderRadius: BorderRadius.circular(K.raioCartao),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              'Código de confirmação',
              style: Theme.of(context).textTheme.titleMedium!
                  .copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: K.s8),
          KTextField(
            rotulo: 'Código do cliente',
            controller: _codigo,
            erro: c.erro,
            teclado: TextInputType.number,
            acaoTeclado: TextInputAction.done,
            formatadores: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')),
            ],
            onChanged: (_) => c.aoEscrever(),
            onSubmitted: (_) => _confirmar(),
          ),
          const SizedBox(height: K.s8 + 2),
          KPrimaryButton(
            rotulo: 'Confirmar serviço',
            aCarregar: c.aConfirmar,
            onPressed: _confirmar,
          ),
        ],
      ),
    );
  }
}
