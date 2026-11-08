import 'package:flutter/foundation.dart';

import '../../../core/state/estado_ui.dart';
import '../../../data/repositories/kisalu_repository.dart';
import '../../../models/estatisticas_avaliacoes.dart';
import '../../../models/profissional.dart';

/// Ecrã 03. Só expõe dados públicos: contacto e morada ficam ocultos até o
/// cliente aceitar uma proposta (RNF10).
class PerfilProfissionalController extends ChangeNotifier {
  PerfilProfissionalController(this._repositorio, this.profissionalId);

  final KisaluRepository _repositorio;
  final String profissionalId;
  bool _terminado = false;

  EstadoUi<Profissional> estado = const Carregar();

  /// "Avaliações em números". Opcional: se falhar, o perfil mostra-se na
  /// mesma, só sem este bloco.
  EstatisticasAvaliacoes? estatisticas;

  Future<void> carregar() async {
    _definir(const Carregar());
    try {
      final p = await _repositorio.profissional(profissionalId);
      _definir(
        p == null
            ? const Erro(
                'Não encontrámos este profissional. Volte ao Início.',
                naoEncontrado: true,
              )
            : Sucesso(p),
      );
      if (p != null) await _carregarEstatisticas();
    } on NaoEncontradoException catch (e) {
      _definir(Erro(e.mensagem, naoEncontrado: true));
    } on KisaluException catch (e) {
      _definir(Erro(e.mensagem, semRede: e is SemRedeException));
    }
  }

  Future<void> _carregarEstatisticas() async {
    try {
      final e = await _repositorio.estatisticasAvaliacoes(profissionalId);
      if (_terminado) return;
      estatisticas = e;
      notifyListeners();
    } on KisaluException {
      // Sem estatística o bloco não aparece; o resto do perfil já está visível.
    }
  }

  void _definir(EstadoUi<Profissional> novo) {
    if (_terminado) return;
    estado = novo;
    notifyListeners();
  }

  @override
  void dispose() {
    _terminado = true;
    super.dispose();
  }
}
