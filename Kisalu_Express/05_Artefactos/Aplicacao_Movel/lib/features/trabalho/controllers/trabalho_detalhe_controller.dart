import 'package:flutter/foundation.dart';

import '../../../core/state/estado_ui.dart';
import '../../../data/repositories/kisalu_repository.dart';
import '../../../models/estado_pedido.dart';
import '../../../models/pedido.dart';

/// Estado do detalhe de um trabalho aceite (profissional, RF08/RF15):
/// morada, contacto do cliente e as etapas "A caminho" e "Começado".
class TrabalhoDetalheController extends ChangeNotifier {
  TrabalhoDetalheController(this._repositorio, this.pedidoId) {
    _repositorio.alteracoes.addListener(_aoMudar);
  }

  final KisaluRepository _repositorio;
  final String pedidoId;
  bool _terminado = false;

  EstadoUi<Pedido> estado = const Carregar();
  bool aMudar = false;
  String? erro;

  Future<void> carregar() async {
    _definir(() => estado = const Carregar());
    await _ler();
  }

  /// Releitura sem esqueletos.
  Future<void> recarregar() => _ler();

  void _aoMudar() => _ler();

  Future<void> _ler() async {
    try {
      final pedido = await _repositorio.pedido(pedidoId);
      _definir(
        () => estado = pedido == null
            ? const Erro(
                'Não encontrámos este trabalho. Veja os seus pedidos.',
                naoEncontrado: true,
              )
            : Sucesso(pedido),
      );
    } on KisaluException catch (e) {
      _definir(() => estado = Erro(e.mensagem, semRede: e is SemRedeException));
    }
  }

  Pedido? get _pedido => switch (estado) {
    Sucesso<Pedido>(:final dados) => dados,
    _ => null,
  };

  /// Trabalho ainda por concluir (há etapas para avançar).
  bool get ativo => _pedido?.estado == EstadoPedido.emCurso;

  /// "Estou a caminho": só antes de sair.
  bool get podeIrACaminho => ativo && _pedido?.etapa == EtapaServico.aceite;

  /// "Comecei o trabalho": aceite ou a caminho.
  bool get podeComecar =>
      ativo &&
      (_pedido?.etapa == EtapaServico.aceite ||
          _pedido?.etapa == EtapaServico.aCaminho);

  /// Já começou: falta o código do cliente (ecrã 16).
  bool get faltaConfirmar => ativo && _pedido?.etapa == EtapaServico.emCurso;

  /// Avança a etapa. Devolve true se mudou; senão o motivo fica em [erro].
  Future<bool> mudarEtapa(EtapaServico etapa) async {
    if (aMudar) return false;
    _definir(() {
      aMudar = true;
      erro = null;
    });
    try {
      await _repositorio.mudarEtapaServico(pedidoId, etapa);
      await _ler();
      _definir(() => aMudar = false);
      return true;
    } on KisaluException catch (e) {
      _definir(() {
        aMudar = false;
        erro = e.mensagem;
      });
      return false;
    }
  }

  void _definir(VoidCallback alterar) {
    if (_terminado) return;
    alterar();
    notifyListeners();
  }

  @override
  void dispose() {
    _repositorio.alteracoes.removeListener(_aoMudar);
    _terminado = true;
    super.dispose();
  }
}
