import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/k_icons.dart';
import '../../../core/theme/k_tokens.dart';
import '../../../core/validators/k_validators.dart';
import '../../../core/widgets/widgets.dart';
import '../controllers/novo_pedido_controller.dart';

/// Passo 2 · zona e ponto de referência. O ponto de referência fica oculto
/// até o cliente aceitar uma proposta (RNF10).
class NovoPedidoPassoMorada extends StatefulWidget {
  const NovoPedidoPassoMorada({super.key});

  @override
  State<NovoPedidoPassoMorada> createState() => _NovoPedidoPassoMoradaState();
}

class _NovoPedidoPassoMoradaState extends State<NovoPedidoPassoMorada> {
  late final TextEditingController _zona;
  late final TextEditingController _ponto;

  @override
  void initState() {
    super.initState();
    final c = context.read<NovoPedidoController>();
    _zona = TextEditingController(text: c.zona);
    _ponto = TextEditingController(text: c.pontoReferencia);
  }

  @override
  void dispose() {
    _zona.dispose();
    _ponto.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<NovoPedidoController>();
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Onde precisa do serviço?', style: text.titleLarge),
        const SizedBox(height: K.s16),
        KTextField(
          rotulo: 'Zona',
          controller: _zona,
          dica: 'Talatona',
          icone: KIcons.localizacao,
          erro: c.erroZona,
          onChanged: c.aoEscreverZona,
        ),
        const SizedBox(height: K.s16),
        KTextField(
          rotulo: 'Ponto de referência',
          controller: _ponto,
          dica: 'Perto da cantina do Sr. Zé',
          ajuda: 'Ajuda o profissional a encontrar a sua casa.',
          maxCaracteres: KValidators.maxPontoReferencia,
          erro: c.erroPonto,
          onChanged: c.aoEscreverPonto,
          onSaiu: c.aoSairPonto,
        ),
        const SizedBox(height: K.s16),
        Text(
          'A morada e o ponto de referência só são partilhados com o '
          'profissional depois de aceitar a proposta.',
          style: text.bodyMedium,
        ),
      ],
    );
  }
}
