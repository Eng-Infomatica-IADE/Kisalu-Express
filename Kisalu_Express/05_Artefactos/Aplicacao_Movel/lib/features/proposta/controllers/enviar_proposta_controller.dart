import 'package:flutter/foundation.dart';

import '../../../core/state/estado_ui.dart';
import '../../../core/validators/k_validators.dart';
import '../../../data/repositories/kisalu_repository.dart';
import '../../../models/nova_proposta.dart';
import '../../../models/pedido_perto.dart';

/// Os três componentes do preço (RF15).
enum ComponenteValor {
  maoDeObra('mão de obra'),
  material('material'),
  deslocacao('deslocação');

  const ComponenteValor(this.nome);

  /// Nome em minúsculas para as mensagens de erro.
  final String nome;
}

/// Dados do ecrã 15 já prontos a desenhar.
class EnviarPropostaDados {
  const EnviarPropostaDados({required this.pedido, required this.agora});

  final PedidoPerto pedido;
  final DateTime agora;
}

/// Estado do ecrã 15 · Enviar proposta. O valor fechado é calculado aqui, a
/// partir dos três componentes: nunca se escreve (RF04, RF15).
class EnviarPropostaController extends ChangeNotifier {
  EnviarPropostaController(this._repositorio, this.pedidoId);

  final KisaluRepository _repositorio;
  final String pedidoId;
  bool _terminado = false;

  EstadoUi<EnviarPropostaDados> estado = const Carregar();

  /// Valores em Kz; null → campo vazio ou inválido (ainda sem valor).
  final Map<ComponenteValor, int?> valores = {
    for (final c in ComponenteValor.values) c: 0,
  };
  final Map<ComponenteValor, String?> erros = {};
  ChegadaProposta chegada = ChegadaProposta.quarentaMinutos;
  bool aEnviar = false;
  String? erroGeral;

  /// Soma dos componentes válidos.
  int get valorFechado => valores.values.fold(0, (soma, v) => soma + (v ?? 0));

  Future<void> carregar() async {
    _definir(() => estado = const Carregar());
    try {
      final pedido = await _repositorio.pedidoPerto(pedidoId);
      if (pedido == null) {
        return _definir(
          () => estado = const Erro(
            'Este pedido já não está disponível.',
            naoEncontrado: true,
          ),
        );
      }
      final rascunho = await _repositorio.rascunhoProposta(pedidoId);
      final agora = _repositorio.agora();
      _definir(() {
        valores[ComponenteValor.maoDeObra] = rascunho?.maoDeObra ?? 0;
        valores[ComponenteValor.material] = rascunho?.material ?? 0;
        valores[ComponenteValor.deslocacao] = rascunho?.deslocacao ?? 0;
        chegada = rascunho?.chegada ?? chegada;
        estado = Sucesso(EnviarPropostaDados(pedido: pedido, agora: agora));
      });
    } on KisaluException catch (e) {
      _definir(
        () => estado = Erro(
          e.mensagem,
          semRede: e is SemRedeException,
          naoEncontrado: e is NaoEncontradoException,
        ),
      );
    }
  }

  /// Atualiza um componente a partir do que se escreveu. O erro só aparece
  /// ao sair do campo ([validarAoSair]) ou ao enviar.
  void alterar(ComponenteValor componente, String texto) {
    final invalido = KValidators.componenteKz(texto, nome: componente.nome);
    _definir(() {
      valores[componente] = invalido == null
          ? KValidators.kzParaInteiro(texto)
          : null;
      erros.remove(componente);
      erroGeral = null;
    });
  }

  void validarAoSair(ComponenteValor componente, String texto) {
    _definir(
      () => erros[componente] = KValidators.componenteKz(
        texto,
        nome: componente.nome,
      ),
    );
  }

  void escolherChegada(ChegadaProposta nova) {
    if (nova != chegada) _definir(() => chegada = nova);
  }

  /// "Enviar proposta": valida e envia. Devolve true se foi aceite.
  Future<bool> enviar() async {
    if (aEnviar) return false;
    var falhou = false;
    for (final c in ComponenteValor.values) {
      if (valores[c] == null) {
        erros[c] ??= 'Escreva o valor de ${c.nome}. Se não cobra, escreva 0.';
        falhou = true;
      }
    }
    final totalErro = KValidators.valorKz(valorFechado.toString());
    if (!falhou && totalErro != null) {
      _definir(() => erroGeral = totalErro);
      return false;
    }
    if (falhou) {
      _definir(() {});
      return false;
    }
    _definir(() {
      aEnviar = true;
      erroGeral = null;
    });
    try {
      await _repositorio.enviarProposta(
        NovaProposta(
          pedidoId: pedidoId,
          maoDeObra: valores[ComponenteValor.maoDeObra]!,
          material: valores[ComponenteValor.material]!,
          deslocacao: valores[ComponenteValor.deslocacao]!,
          chegada: chegada,
        ),
      );
      _definir(() => aEnviar = false);
      return true;
    } on KisaluException catch (e) {
      _definir(() {
        aEnviar = false;
        erroGeral = e.mensagem;
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
    _terminado = true;
    super.dispose();
  }
}
