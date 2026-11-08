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
import '../../../models/pedido_codigo_sms.dart';
import '../controllers/codigo_sms_controller.dart';
import '../widgets/codigo_caixas.dart';

/// Ecrã 11 · Confirmar número — ver docs/design/SCREENS.md#ecra-11.
class CodigoSmsView extends StatelessWidget {
  const CodigoSmsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (c) =>
          CodigoSmsController(c.read<KisaluRepository>())..carregar(),
      child: const _Conteudo(),
    );
  }
}

class _Conteudo extends StatelessWidget {
  const _Conteudo();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<CodigoSmsController>();
    final margem = K.margemPara(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            KTopBar(
              titulo: 'Confirmar número',
              onVoltar: () => _alterarNumero(context),
            ),
            Expanded(
              child: KEstadoBuilder<PedidoCodigoSms>(
                estado: c.estado,
                onTentar: c.carregar,
                carregar: (_) => Padding(
                  padding: EdgeInsets.all(margem),
                  child: const KSkeletonLista(),
                ),
                vazio: (_) => const SizedBox(),
                sucesso: (context, pedido) =>
                    _Formulario(pedido: pedido, margem: margem),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Alterar número" e o voltar levam ao Login.
void _alterarNumero(BuildContext context) =>
    context.canPop() ? context.pop() : context.go(AppRoutes.login);

class _Formulario extends StatefulWidget {
  const _Formulario({required this.pedido, required this.margem});

  final PedidoCodigoSms pedido;
  final double margem;

  @override
  State<_Formulario> createState() => _FormularioState();
}

class _FormularioState extends State<_Formulario> {
  late final TextEditingController _codigo = TextEditingController(
    text: context.read<CodigoSmsController>().codigoInicial,
  );

  @override
  void dispose() {
    _codigo.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    final c = context.read<CodigoSmsController>();
    final destino = await c.confirmar(_codigo.text);
    if (destino == null || !mounted) return;
    context.go(switch (destino) {
      DestinoCodigoSms.inicio => AppRoutes.inicio,
      DestinoCodigoSms.registoProfissional => AppRoutes.registoProfissional,
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<CodigoSmsController>();
    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              widget.margem,
              K.s4,
              widget.margem,
              K.s16 + 3,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    'Introduza o código',
                    style: KTypography.titulo24,
                  ),
                ),
                const SizedBox(height: K.s12),
                Text(
                  // O número fica sempre numa linha própria, sem se partir.
                  'Enviámos um código de 6 dígitos para\n'
                  '${KFormat.telemovel(widget.pedido.telemovel)}.',
                  style: Theme.of(context).textTheme.bodyLarge!
                      .copyWith(color: KColors.neutro700),
                ),
                const SizedBox(height: K.s16),
                CodigoCaixas(
                  controller: _codigo,
                  erro: c.erro,
                  onChanged: (_) => c.aoEscrever(),
                  onSubmitted: (_) => _confirmar(),
                ),
                if (c.erro == null) ...[
                  const SizedBox(height: K.s8),
                  Text(
                    'O código preenche-se sozinho quando o SMS chegar.',
                    style: KTypography.corpo13.copyWith(
                      color: KColors.neutro500,
                    ),
                  ),
                ],
                const SizedBox(height: K.s12),
                _Reenvio(controller: c),
                const Spacer(),
                const SizedBox(height: K.s24),
                // Desativado até haver 6 dígitos.
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _codigo,
                  builder: (_, valor, _) => KPrimaryButton(
                    rotulo: 'Confirmar',
                    aCarregar: c.aConfirmar,
                    onPressed: valor.text.length == KValidators.digitosCodigo
                        ? _confirmar
                        : null,
                  ),
                ),
                const SizedBox(height: K.s4 + 1),
                Center(
                  child: KTextLink(
                    grande: true,
                    rotulo: 'Alterar número',
                    onPressed: () => _alterarNumero(context),
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

class _Reenvio extends StatelessWidget {
  const _Reenvio({required this.controller});

  final CodigoSmsController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.segundosRestantes == 0) {
      return Align(
        alignment: Alignment.centerLeft,
        child: KTextLink(
          rotulo: 'Reenviar código',
          icone: KIcons.relogio,
          onPressed: controller.podeReenviar ? controller.reenviar : null,
        ),
      );
    }
    final texto =
        'Reenviar código em ${KFormat.contagem(controller.segundosRestantes)}';
    return Row(
      children: [
        const ExcludeSemantics(
          child: Icon(
            KIcons.relogio,
            size: K.icone16,
            color: KColors.neutro500,
          ),
        ),
        const SizedBox(width: K.s8),
        Expanded(
          child: Text(
            texto,
            style: KTypography.corpo15.copyWith(color: KColors.neutro500),
          ),
        ),
      ],
    );
  }
}
