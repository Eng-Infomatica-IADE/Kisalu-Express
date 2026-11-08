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
import '../../../models/utilizador.dart';
import '../controllers/login_controller.dart';
import '../widgets/cabecalho_login.dart';

/// Ecrã 01 · Entrar ou criar conta — ver docs/design/SCREENS.md#ecra-01.
class LoginView extends StatelessWidget {
  const LoginView({super.key});

  /// Fração do ecrã ocupada pelo cabeçalho laranja (≈ 37,5 % no Figma).
  static const _fracaoCabecalho = .375;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (c) => LoginController(c.read<KisaluRepository>())..carregar(),
      child: Scaffold(
        backgroundColor: KColors.laranja,
        body: LayoutBuilder(
          builder: (context, caixa) => CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: CabecalhoLogin(
                  alturaMinima: caixa.maxHeight * _fracaoCabecalho,
                ),
              ),
              SliverFillRemaining(
                hasScrollBody: false,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    color: KColors.areia50,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(K.raioFolha),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        K.s24,
                        K.s24 + K.s4,
                        K.s24,
                        K.s32,
                      ),
                      child: Consumer<LoginController>(
                        builder: (context, c, _) => KEstadoBuilder<String>(
                          estado: c.estado,
                          onTentar: c.carregar,
                          carregar: (_) => const KSkeletonLista(),
                          vazio: (_) => _Formulario(inicial: ''),
                          sucesso: (_, tel) => _Formulario(inicial: tel),
                        ),
                      ),
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

class _Formulario extends StatefulWidget {
  const _Formulario({required this.inicial});

  final String inicial;

  @override
  State<_Formulario> createState() => _FormularioState();
}

class _FormularioState extends State<_Formulario> {
  late final TextEditingController _telemovel = TextEditingController(
    text: widget.inicial,
  );

  @override
  void dispose() {
    _telemovel.dispose();
    super.dispose();
  }

  Future<void> _enviar({bool criarConta = false}) async {
    final c = context.read<LoginController>();
    final podeAvancar = await c.submeter(
      _telemovel.text,
      criarConta: criarConta,
    );
    if (podeAvancar && mounted) context.push(AppRoutes.codigoSms);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<LoginController>();
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text('Entrar ou criar conta', style: KTypography.titulo22),
        ),
        const SizedBox(height: K.s16),
        KSegmentedControl<PerfilUtilizador>(
          opcoes: [for (final p in PerfilUtilizador.values) (p, p.rotulo)],
          valor: c.perfil,
          onMudar: c.mudarPerfil,
        ),
        const SizedBox(height: K.s16),
        KTextField(
          rotulo: 'Telemóvel',
          controller: _telemovel,
          icone: KIcons.telefone,
          dica: '+244 9__ ___ ___',
          ajuda: 'Enviamos um código por SMS: sem palavra-passe.',
          erro: c.erroTelefone,
          teclado: TextInputType.phone,
          acaoTeclado: TextInputAction.done,
          onChanged: (_) => c.aoEscrever(),
          onSaiu: () => c.validarAoSair(_telemovel.text),
          onSubmitted: (_) => _enviar(),
        ),
        const SizedBox(height: K.s16),
        KPrimaryButton(
          rotulo: 'Receber código SMS',
          aCarregar: c.aEnviar,
          onPressed: _enviar,
        ),
        const SizedBox(height: K.s16),
        KSecondaryButton(
          rotulo: 'Criar conta',
          onPressed: () => _enviar(criarConta: true),
        ),
        const SizedBox(height: K.s16),
        Text(
          'Ao continuar aceita os Termos e a Política de Privacidade (RGPD).',
          textAlign: TextAlign.center,
          style: text.bodySmall!.copyWith(
            color: KColors.neutro500,
            fontWeight: FontWeight.w400,
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: KTextLink(
            rotulo: 'Precisa de ajuda? Fale connosco',
            // As perguntas frequentes são públicas (GET /ajuda/perguntas).
            onPressed: () => context.push(AppRoutes.ajuda),
          ),
        ),
      ],
    );
  }
}
