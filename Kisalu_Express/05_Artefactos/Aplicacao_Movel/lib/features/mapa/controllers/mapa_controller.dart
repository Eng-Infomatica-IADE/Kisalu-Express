import 'package:flutter/foundation.dart';

import '../../../core/state/estado_ui.dart';
import '../../../data/repositories/kisalu_repository.dart';
import '../../../models/pin_mapa.dart';

/// Estado do ecrã 22 · Mapa "Perto de si". O mapa é um desenho estático; só
/// se escolhe qual dos pins aparece no cartão de baixo.
class MapaController extends ChangeNotifier {
  MapaController(this._repositorio);

  final KisaluRepository _repositorio;
  bool _terminado = false;

  EstadoUi<List<PinMapa>> estado = const Carregar();

  /// Id do profissional destacado; por omissão o primeiro (o mais perto).
  String? selecionadoId;

  Future<void> carregar() async {
    _definir(() => estado = const Carregar());
    try {
      final pins = await _repositorio.pinsMapa();
      _definir(() {
        selecionadoId = pins.isEmpty ? null : pins.first.profissional.id;
        estado = pins.isEmpty ? const Vazio() : Sucesso(pins);
      });
    } on KisaluException catch (e) {
      _definir(() => estado = Erro(e.mensagem, semRede: e is SemRedeException));
    }
  }

  void selecionar(String profissionalId) {
    if (profissionalId != selecionadoId) {
      _definir(() => selecionadoId = profissionalId);
    }
  }

  /// O pin destacado; null se ainda não há pins.
  PinMapa? get selecionado => switch (estado) {
    Sucesso(:final dados) =>
      dados.where((p) => p.profissional.id == selecionadoId).firstOrNull,
    _ => null,
  };

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
