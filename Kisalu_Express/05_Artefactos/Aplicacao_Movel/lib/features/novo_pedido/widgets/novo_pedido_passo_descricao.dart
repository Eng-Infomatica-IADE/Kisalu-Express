import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/k_colors.dart';
import '../../../core/theme/k_icons.dart';
import '../../../core/theme/k_tokens.dart';
import '../../../core/validators/k_validators.dart';
import '../../../core/widgets/widgets.dart';
import '../controllers/novo_pedido_controller.dart';

/// Passo 1 · categoria (Q-02), título, descrição e foto opcional.
class NovoPedidoPassoDescricao extends StatefulWidget {
  const NovoPedidoPassoDescricao({super.key});

  @override
  State<NovoPedidoPassoDescricao> createState() =>
      _NovoPedidoPassoDescricaoState();
}

class _NovoPedidoPassoDescricaoState extends State<NovoPedidoPassoDescricao> {
  late final TextEditingController _titulo;
  late final TextEditingController _descricao;

  @override
  void initState() {
    super.initState();
    final c = context.read<NovoPedidoController>();
    _titulo = TextEditingController(text: c.titulo);
    _descricao = TextEditingController(text: c.descricao);
  }

  @override
  void dispose() {
    _titulo.dispose();
    _descricao.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<NovoPedidoController>();
    final text = Theme.of(context).textTheme;
    final fotos = c.numFotos == 0
        ? 'Sem fotos'
        : c.numFotos == 1
        ? '1 foto anexada'
        : '${c.numFotos} fotos anexadas';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Que serviço precisa?', style: text.titleLarge),
        const SizedBox(height: K.s8),
        Wrap(
          spacing: K.s8,
          runSpacing: K.chipEntreLinhas,
          children: [
            for (final cat in c.categorias)
              KChip(
                rotulo: cat.nome,
                variante: KChipVariante.etiqueta,
                selecionado: c.categoriaId == cat.id,
                onSelecionar: (_) => c.escolherCategoria(cat.id),
              ),
          ],
        ),
        if (c.erroCategoria != null) ...[
          const SizedBox(height: K.s4),
          Text(
            c.erroCategoria!,
            style: text.bodyMedium!.copyWith(color: KColors.erro),
          ),
        ],
        const SizedBox(height: K.s16),
        KTextField(
          rotulo: 'Título do pedido',
          controller: _titulo,
          dica: 'Fuga de água na cozinha',
          maxCaracteres: NovoPedidoController.maxTitulo,
          erro: c.erroTitulo,
          onChanged: c.aoEscreverTitulo,
          onSaiu: c.aoSairTitulo,
        ),
        const SizedBox(height: K.s16),
        KTextField(
          rotulo: 'Descreva o problema',
          controller: _descricao,
          dica: 'Cano a pingar debaixo do lava-loiça.',
          linhas: 4,
          maxCaracteres: KValidators.maxDescricao,
          erro: c.erroDescricao,
          onChanged: c.aoEscreverDescricao,
          onSaiu: c.aoSairDescricao,
        ),
        const SizedBox(height: K.s16),
        Text('Foto (opcional)', style: text.titleMedium),
        const SizedBox(height: K.s8),
        Wrap(
          spacing: K.s12,
          runSpacing: K.s8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            KSecondaryButton(
              rotulo: 'Adicionar foto',
              icone: KIcons.foto,
              compacto: true,
              larguraTotal: false,
              onPressed: c.numFotos >= NovoPedidoController.maxFotos
                  ? null
                  : c.adicionarFoto,
            ),
            Text(fotos, style: text.bodyMedium),
            if (c.numFotos > 0)
              KTextLink(
                rotulo: 'Remover',
                pequeno: true,
                onPressed: c.removerFoto,
              ),
          ],
        ),
      ],
    );
  }
}
