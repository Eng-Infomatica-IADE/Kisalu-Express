import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/k_icons.dart';
import '../../../core/theme/k_tokens.dart';

/// Galeria de desenvolvimento: abre qualquer ecrã do Figma diretamente.
/// Serve para rever as telas estáticas e para a demonstração.
/// Só existe em debug (o router não regista `/dev` em release).
class DevGalleryView extends StatelessWidget {
  const DevGalleryView({super.key});

  static final _ecras = <(String, String, String)>[
    ('01', 'Login / Registo', AppRoutes.login),
    ('02', 'Início — pesquisa de profissionais', AppRoutes.inicio),
    ('03', 'Perfil do profissional', AppRoutes.profissional('p1')),
    ('04', 'Pedido e propostas', AppRoutes.pedido('ped1')),
    ('05', 'Confirmação por QR Code', AppRoutes.qr),
    ('06', 'Avaliação do serviço', AppRoutes.avaliar('ped1')),
    ('07', 'Histórico de pedidos', AppRoutes.pedidos),
    ('08', 'Confirmar proposta (folha no ecrã 04)', AppRoutes.pedido('ped1')),
    ('09', 'QR sem serviço em curso', '${AppRoutes.qr}?vazio=1'),
    ('10', 'Novo pedido sem rede', AppRoutes.novoPedido),
  ];

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kisalu · ecrãs (dev)'),
        actions: [
          TextButton(
            onPressed: () => context.go(AppRoutes.devComponentes),
            child: const Text('Componentes'),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(K.margem),
        itemCount: _ecras.length,
        separatorBuilder: (_, _) => const Divider(),
        itemBuilder: (context, i) {
          final (numero, nome, rota) = _ecras[i];
          return ListTile(
            minTileHeight: K.alvoMinimo,
            leading: Text(numero, style: text.titleMedium),
            title: Text(nome, style: text.bodyLarge),
            trailing: const Icon(KIcons.avancar),
            onTap: () => context.go(rota),
          );
        },
      ),
    );
  }
}
