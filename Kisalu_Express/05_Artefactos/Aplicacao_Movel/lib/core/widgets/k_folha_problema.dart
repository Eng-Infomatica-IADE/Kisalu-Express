import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/kisalu_repository.dart';
import '../../models/resultado_reporte.dart';
import '../state/reportar_problema_controller.dart';
import '../theme/k_colors.dart';
import '../theme/k_tokens.dart';
import '../utils/k_format.dart';
import '../validators/k_validators.dart';
import 'k_folha.dart';
import 'k_primary_button.dart';
import 'k_snack.dart';
import 'k_text_field.dart';
import 'k_text_link.dart';

/// Abre a folha "O trabalho tem um problema?" (RF11) para [pedidoId]. Depois
/// de enviar mostra a resposta da equipa e, quando a API o devolve, o
/// contacto do profissional.
Future<void> mostrarKFolhaProblema(BuildContext context, String pedidoId) {
  final repositorio = context.read<KisaluRepository>();
  return mostrarKFolha<void>(
    context,
    builder: (_) => KFolhaProblema(
      controller: ReportarProblemaController(repositorio, pedidoId),
    ),
  );
}

/// Folha do reporte. É dona do [controller] (fecha-o ao sair).
class KFolhaProblema extends StatefulWidget {
  const KFolhaProblema({super.key, required this.controller});

  final ReportarProblemaController controller;

  @override
  State<KFolhaProblema> createState() => _KFolhaProblemaState();
}

class _KFolhaProblemaState extends State<KFolhaProblema> {
  final _texto = TextEditingController();

  @override
  void dispose() {
    _texto.dispose();
    widget.controller.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final navigator = Navigator.of(context);
    final contexto = navigator.context;
    final resultado = await widget.controller.enviar(_texto.text);
    if (resultado == null || !mounted) return;
    navigator.pop();
    if (!contexto.mounted) return;
    if (!resultado.temContacto) {
      mostrarKSnack(contexto, resultado.mensagem);
      return;
    }
    await showDialog<void>(
      context: contexto,
      builder: (dialogo) => _RespostaReporte(
        resultado: resultado,
        onFechar: () => Navigator.of(dialogo).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final c = widget.controller;
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text('O trabalho tem um problema?', style: text.titleLarge),
          ),
          const SizedBox(height: K.s8),
          Text(
            'Conte-nos o que aconteceu. Tem 7 dias.',
            style: text.bodyMedium!.copyWith(color: KColors.neutro700),
          ),
          const SizedBox(height: K.s16),
          KTextField(
            rotulo: 'O que aconteceu?',
            controller: _texto,
            linhas: 3,
            maxCaracteres: KValidators.maxReporte,
            erro: c.erro,
            onChanged: (_) => c.aoEscrever(),
            onSaiu: () => c.aoSair(_texto.text),
          ),
          const SizedBox(height: K.s16),
          KPrimaryButton(
            rotulo: 'Enviar',
            aCarregar: c.aEnviar,
            onPressed: _enviar,
          ),
        ],
      ),
    );
  }
}

class _RespostaReporte extends StatelessWidget {
  const _RespostaReporte({required this.resultado, required this.onFechar});

  final ResultadoReporte resultado;
  final VoidCallback onFechar;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final telemovel = resultado.contactoTelemovel;
    return AlertDialog(
      title: const Text('Problema enviado'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(resultado.mensagem, style: text.bodyLarge),
          const SizedBox(height: K.s12),
          Text(
            'Contacto do profissional',
            style: text.titleSmall!.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: K.s4),
          if (resultado.contactoNome != null)
            Text(resultado.contactoNome!, style: text.bodyLarge),
          if (telemovel != null)
            Text(KFormat.telemovel(telemovel), style: text.bodyLarge),
        ],
      ),
      actions: [KTextLink(rotulo: 'OK', onPressed: onFechar)],
    );
  }
}
