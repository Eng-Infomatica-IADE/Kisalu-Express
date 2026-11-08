import 'package:flutter/foundation.dart';

import '../../../core/state/estado_ui.dart';
import '../../../data/repositories/kisalu_repository.dart';
import '../../../models/painel_profissional.dart';

/// Dados do ecrã 14, já prontos a desenhar.
class InicioProfissionalDados {
  const InicioProfissionalDados({
    required this.painel,
    required this.saudacao,
    required this.agora,
    this.naoLidas = 0,
  });

  final PainelProfissional painel;

  /// "Boa tarde" (conforme a hora do repositório).
  final String saudacao;

  /// Relógio do repositório, para "há 22 min" e "Amanhã".
  final DateTime agora;

  /// Notificações por ler: ponto vermelho do sino.
  final int naoLidas;
}

/// Estado do ecrã 14 · Início do profissional. Volta a ler o painel quando o
/// repositório avisa de uma mudança (ex.: proposta enviada no ecrã 15).
class InicioProfissionalController extends ChangeNotifier {
  InicioProfissionalController(
    this._repositorio, {
    required this.saudacaoPara,
  }) {
    _repositorio.alteracoes.addListener(_aoMudar);
  }

  final KisaluRepository _repositorio;

  /// `KFormat.saudacao`, injetado para o controller não importar utilitários
  /// de apresentação.
  final String Function(DateTime agora) saudacaoPara;
  bool _terminado = false;

  EstadoUi<InicioProfissionalDados> estado = const Carregar();

  /// Interruptor "Disponível para trabalhar" (muda já, sem esperar).
  bool disponivel = true;

  Future<void> carregar() async {
    _definir(() => estado = const Carregar());
    await _ler();
  }

  /// Releitura silenciosa: não volta a mostrar esqueletos.
  void _aoMudar() => _ler();

  /// Pull-to-refresh e voltar ao separador.
  Future<void> recarregar() => _ler();

  Future<int> _naoLidas() async {
    try {
      return await _repositorio.notificacoesPorLer();
    } on KisaluException {
      return 0;
    }
  }

  Future<void> _ler() async {
    try {
      final painel = await _repositorio.painelProfissional();
      final naoLidas = await _naoLidas();
      final agora = _repositorio.agora();
      _definir(() {
        disponivel = painel.disponivel;
        estado = Sucesso(
          InicioProfissionalDados(
            painel: painel,
            saudacao: saudacaoPara(agora),
            agora: agora,
            naoLidas: naoLidas,
          ),
        );
      });
    } on KisaluException catch (e) {
      _definir(() => estado = Erro(e.mensagem, semRede: e is SemRedeException));
    }
  }

  /// Muda o interruptor; se o repositório recusar, volta ao valor anterior.
  Future<void> mudarDisponibilidade(bool novo) async {
    if (novo == disponivel) return;
    final anterior = disponivel;
    _definir(() => disponivel = novo);
    try {
      await _repositorio.definirDisponibilidade(novo);
    } on KisaluException {
      _definir(() => disponivel = anterior);
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
