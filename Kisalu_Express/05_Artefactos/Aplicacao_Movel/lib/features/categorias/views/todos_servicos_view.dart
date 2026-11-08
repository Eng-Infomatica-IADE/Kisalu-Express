import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/k_colors.dart';
import '../../../core/theme/k_icons.dart';
import '../../../core/theme/k_tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/repositories/kisalu_repository.dart';
import '../../../models/categoria.dart';
import '../controllers/todos_servicos_controller.dart';

/// Ecrã 21 · Todos os serviços — ver docs/design/SCREENS.md#ecra-21.
/// Aberto por "Ver todos" no Início. Tocar numa categoria começa um novo
/// pedido.
class TodosServicosView extends StatelessWidget {
  const TodosServicosView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (c) =>
          TodosServicosController(c.read<KisaluRepository>())..carregar(),
      child: const _Conteudo(),
    );
  }
}

class _Conteudo extends StatelessWidget {
  const _Conteudo();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<TodosServicosController>();
    final margem = K.margemPara(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const KTopBar(titulo: 'Todos os serviços'),
            Padding(
              padding: EdgeInsets.fromLTRB(margem, K.s4, margem, K.s16),
              child: KSearchField(
                dica: 'Procurar um serviço',
                onChanged: c.pesquisar,
              ),
            ),
            Expanded(
              child: KEstadoBuilder<List<Categoria>>(
                estado: c.estado,
                onTentar: c.carregar,
                carregar: (_) => Padding(
                  padding: EdgeInsets.all(margem),
                  child: const KSkeletonLista(),
                ),
                vazio: (_) => Padding(
                  padding: EdgeInsets.all(margem),
                  child: const Center(
                    child: Text(
                      'Ainda não há serviços.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                sucesso: (context, _) {
                  final categorias = c.filtradas;
                  if (categorias.isEmpty) {
                    return SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: margem + K.s16,
                        vertical: K.s24,
                      ),
                      child: const Column(
                        children: [
                          KEmptyState(
                            icone: KIcons.pesquisa,
                            titulo: 'Sem resultados',
                            mensagem:
                                'Não encontrámos nenhum serviço com esse '
                                'nome. Tente outra palavra.',
                          ),
                          SizedBox(height: K.s16),
                          _NaoEncontra(),
                        ],
                      ),
                    );
                  }
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(K.s24, 0, K.s24, K.s24),
                    child: Column(
                      children: [
                        KGrelhaCategorias(
                          categorias: categorias,
                          onSelecionar: (_) =>
                              context.push(AppRoutes.novoPedidoInicio),
                        ),
                        const SizedBox(height: K.s24),
                        const _NaoEncontra(),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Saída para quem não encontra a categoria: descrever o pedido.
class _NaoEncontra extends StatelessWidget {
  const _NaoEncontra();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Não encontra o serviço?',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium!
              .copyWith(color: KColors.neutro700),
        ),
        KTextLink(
          rotulo: 'Descreva o que precisa',
          grande: true,
          onPressed: () => context.push(AppRoutes.novoPedidoInicio),
        ),
      ],
    );
  }
}
