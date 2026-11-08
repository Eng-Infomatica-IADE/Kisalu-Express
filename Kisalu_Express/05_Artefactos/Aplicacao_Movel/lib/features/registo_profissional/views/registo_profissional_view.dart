import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/k_icons.dart';
import '../../../core/theme/k_tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/repositories/kisalu_repository.dart';
import '../controllers/registo_profissional_controller.dart';
import '../widgets/escolha_servicos.dart';
import '../widgets/raio_deslocacao.dart';

/// Ecrã 12 · Criar perfil (profissional, passo 1 de 2) — ver
/// docs/design/SCREENS.md#ecra-12.
class RegistoProfissionalView extends StatelessWidget {
  const RegistoProfissionalView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (c) =>
          RegistoProfissionalController(c.read<KisaluRepository>())..carregar(),
      child: const _Conteudo(),
    );
  }
}

class _Conteudo extends StatelessWidget {
  const _Conteudo();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<RegistoProfissionalController>();
    final margem = K.margemPara(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const KTopBar(titulo: 'Criar perfil'),
            Expanded(
              child: KEstadoBuilder<RegistoDados>(
                estado: c.estado,
                onTentar: c.carregar,
                carregar: (_) => Padding(
                  padding: EdgeInsets.all(margem),
                  child: const KSkeletonLista(),
                ),
                vazio: (_) => const SizedBox(),
                sucesso: (context, dados) =>
                    _Formulario(dados: dados, margem: margem),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Formulario extends StatefulWidget {
  const _Formulario({required this.dados, required this.margem});

  final RegistoDados dados;
  final double margem;

  @override
  State<_Formulario> createState() => _FormularioState();
}

class _FormularioState extends State<_Formulario> {
  late final _nome = TextEditingController(
    text: widget.dados.rascunho?.nomeCompleto ?? '',
  );
  late final _anos = TextEditingController(
    text: widget.dados.rascunho?.anosExperiencia.toString() ?? '',
  );
  late final _zona = TextEditingController(
    text: widget.dados.rascunho?.zona ?? '',
  );

  @override
  void dispose() {
    _nome.dispose();
    _anos.dispose();
    _zona.dispose();
    super.dispose();
  }

  Future<void> _continuar() async {
    final c = context.read<RegistoProfissionalController>();
    final avancar = await c.continuar(
      nome: _nome.text,
      anos: _anos.text,
      zona: _zona.text,
    );
    if (avancar && mounted) context.push(AppRoutes.verificarIdentidade);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<RegistoProfissionalController>();
    final text = Theme.of(context).textTheme;
    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              widget.margem,
              K.s4,
              widget.margem,
              K.s32 - 2,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const KStepProgress(
                  total: 2,
                  atual: 1,
                  legenda: 'O seu perfil',
                ),
                const SizedBox(height: K.s4),
                Row(
                  children: [
                    ListenableBuilder(
                      listenable: _nome,
                      builder: (_, _) => KAvatar(
                        nome: _nome.text.trim().isEmpty ? '?' : _nome.text,
                        tamanho: K.avatarPerfil,
                      ),
                    ),
                    const SizedBox(width: K.s16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fotografia de perfil (opcional)',
                            style: text.bodyLarge!.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          // O alvo de 48 dp sobe 12 dp para ficar junto ao
                          // título, como no Figma.
                          Transform.translate(
                            offset: const Offset(0, -K.s12),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: KTextLink(
                                rotulo: 'Adicionar fotografia',
                                grande: true,
                                onPressed: () =>
                                    mostrarKSnack(context, 'Em breve'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: K.s8 + 3),
                KTextField(
                  rotulo: 'Nome completo',
                  controller: _nome,
                  erro: c.erroNome,
                  teclado: TextInputType.name,
                  acaoTeclado: TextInputAction.next,
                  onChanged: (_) => c.aoEscrever(),
                  onSaiu: () => c.validarNomeAoSair(_nome.text),
                ),
                const SizedBox(height: K.s16),
                EscolhaServicos(
                  categorias: c.visiveis(widget.dados.categorias),
                  escolhidos: c.escolhidos,
                  onAlternar: c.alternarServico,
                  onMais: c.mostrarMais,
                  mostrarMais: !c.mostrarTodos,
                  erro: c.erroServicos,
                ),
                const SizedBox(height: K.s8),
                KTextField(
                  rotulo: 'Anos de experiência',
                  controller: _anos,
                  erro: c.erroAnos,
                  teclado: TextInputType.number,
                  acaoTeclado: TextInputAction.next,
                  formatadores: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => c.aoEscrever(),
                  onSaiu: () => c.validarAnosAoSair(_anos.text),
                ),
                const SizedBox(height: K.s16),
                KTextField(
                  rotulo: 'Zona de atuação',
                  controller: _zona,
                  icone: KIcons.localizacao,
                  erro: c.erroZona,
                  acaoTeclado: TextInputAction.done,
                  onChanged: (_) => c.aoEscrever(),
                  onSaiu: () => c.validarZonaAoSair(_zona.text),
                  onSubmitted: (_) => _continuar(),
                ),
                const SizedBox(height: K.s16),
                RaioDeslocacao(km: c.raioKm, onMudar: c.mudarRaio),
                const Spacer(),
                const SizedBox(height: K.s24),
                if (c.erroGeral != null) ...[
                  KInlineAlert(
                    tipo: KAlertaTipo.erro,
                    titulo: 'Não guardámos o perfil.',
                    mensagem: c.erroGeral!,
                  ),
                  const SizedBox(height: K.s12),
                ],
                KPrimaryButton(
                  rotulo: 'Continuar',
                  aCarregar: c.aGuardar,
                  onPressed: _continuar,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
