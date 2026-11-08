import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/state/estado_ui.dart';
import '../../../core/theme/k_colors.dart';
import '../../../core/theme/k_icons.dart';
import '../../../core/theme/k_tokens.dart';
import '../../../core/utils/k_format.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/repositories/kisalu_repository.dart';
import '../../../models/conversa.dart';
import '../controllers/conversa_controller.dart';
import '../widgets/barra_escrita.dart';
import '../widgets/bolha_mensagem.dart';

/// Ecrã 19 · Conversa do pedido — ver docs/design/SCREENS.md#ecra-19.
class ConversaView extends StatelessWidget {
  const ConversaView({super.key, required this.conversaId});

  final String conversaId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (c) =>
          ConversaController(c.read<KisaluRepository>(), conversaId)
            ..carregar(),
      child: const _Conteudo(),
    );
  }
}

class _Conteudo extends StatefulWidget {
  const _Conteudo();

  @override
  State<_Conteudo> createState() => _ConteudoState();
}

class _ConteudoState extends State<_Conteudo> {
  final _texto = TextEditingController();
  final _rolagem = ScrollController();
  int _mensagensVistas = 0;

  @override
  void dispose() {
    _texto.dispose();
    _rolagem.dispose();
    super.dispose();
  }

  void _irParaOFim() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_rolagem.hasClients) {
        _rolagem.jumpTo(_rolagem.position.maxScrollExtent);
      }
    });
  }

  Future<void> _enviar() async {
    final c = context.read<ConversaController>();
    final enviada = await c.enviar(_texto.text);
    if (enviada) {
      _texto.clear();
      _irParaOFim();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ConversaController>();
    final margem = K.margemPara(context);
    final nome = switch (c.estado) {
      Sucesso(:final dados) => dados.interlocutor.nome,
      _ => 'Conversa',
    };
    if (c.estado case Sucesso(:final dados)) {
      // Só desce quando chega ou sai uma mensagem.
      if (dados.mensagens.length != _mensagensVistas) {
        _mensagensVistas = dados.mensagens.length;
        _irParaOFim();
      }
    }
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            KTopBar(
              titulo: nome,
              acao: c.estado is Sucesso<Conversa>
                  ? KIconButton(
                      icone: KIcons.telefone,
                      rotulo: 'Ligar a $nome',
                      onPressed: () => mostrarKSnack(context, 'Em breve'),
                    )
                  : null,
            ),
            Expanded(
              child: KEstadoBuilder<Conversa>(
                estado: c.estado,
                onTentar: c.carregar,
                rotuloNaoEncontrado: 'Ver as conversas',
                onNaoEncontrado: () => context.go(AppRoutes.conversas),
                carregar: (_) => Padding(
                  padding: EdgeInsets.all(margem),
                  child: const KSkeletonLista(),
                ),
                vazio: (_) => const SizedBox(),
                sucesso: (context, conversa) => ListView.builder(
                  controller: _rolagem,
                  padding: EdgeInsets.fromLTRB(margem, K.s4, margem, K.s16),
                  itemCount: conversa.mensagens.length + 1,
                  itemBuilder: (context, i) {
                    if (i == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: K.s16),
                        child: _PedidoChip(conversa: conversa),
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: K.s12),
                      child: BolhaMensagem(mensagem: conversa.mensagens[i - 1]),
                    );
                  },
                ),
              ),
            ),
            if (c.erro != null)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: margem),
                child: KInlineAlert(
                  tipo: KAlertaTipo.erro,
                  titulo: 'Não enviámos a mensagem.',
                  mensagem: c.erro!,
                ),
              ),
            if (c.estado is Sucesso<Conversa>)
              BarraEscrita(
                controller: _texto,
                aEnviar: c.aEnviar,
                onEnviar: _enviar,
                onFoto: () => mostrarKSnack(context, 'Em breve'),
              ),
          ],
        ),
      ),
    );
  }
}

/// Pedido a que a conversa pertence: "Fuga de água na cozinha · 12.500 Kz",
/// com seta, porque se toca para ver o pedido.
class _PedidoChip extends StatelessWidget {
  const _PedidoChip({required this.conversa});

  final Conversa conversa;

  @override
  Widget build(BuildContext context) {
    // Sem valor fechado mostra só o título (nunca "0 Kz").
    final valor = conversa.valor;
    final texto = valor == null
        ? conversa.pedidoTitulo
        : '${conversa.pedidoTitulo} · ${KFormat.kz(valor)}';
    return Semantics(
      button: true,
      label: 'Ver o pedido: $texto',
      excludeSemantics: true,
      child: Material(
        color: KColors.areia100,
        borderRadius: BorderRadius.circular(K.raioBotao),
        child: InkWell(
          borderRadius: BorderRadius.circular(K.raioBotao),
          onTap: () => mostrarKSnack(context, 'Em breve'),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: K.alvoMinimo),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: K.s12,
                vertical: K.s8,
              ),
              child: Row(
                children: [
                  ExcludeSemantics(
                    child: Icon(
                      KIcons.categoria(conversa.categoriaId),
                      size: K.icone16,
                      color: KColors.brasa,
                    ),
                  ),
                  const SizedBox(width: K.s8),
                  Expanded(
                    child: Text(
                      texto,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: KColors.neutro700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const ExcludeSemantics(
                    child: Icon(
                      KIcons.avancar,
                      size: K.icone16,
                      color: KColors.neutro700,
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
