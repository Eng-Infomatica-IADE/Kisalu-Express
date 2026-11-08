import 'package:flutter/foundation.dart';

import '../../../core/state/estado_ui.dart';
import '../../../data/repositories/kisalu_repository.dart';
import '../../../models/utilizador.dart';

/// Dados do ecrã 20 já prontos a desenhar.
class PerfilDados {
  const PerfilDados({required this.utilizador, required this.perfilAtivo});

  final Utilizador utilizador;
  final PerfilUtilizador perfilAtivo;
}

/// Para onde vai a view depois de "Mudar para …".
enum DestinoMudarPerfil {
  /// Nada mudou (erro ou já a mudar).
  nenhum,

  /// Perfil mudado: Início do novo perfil.
  inicio,

  /// Quer ser profissional mas ainda não fez o registo: ecrã 12.
  registo,
}

/// Estado do separador Perfil (ecrã 20): dados da pessoa, alternar entre
/// cliente e profissional e terminar sessão.
class PerfilController extends ChangeNotifier {
  PerfilController(this._repositorio) {
    _repositorio.alteracoes.addListener(_aoMudar);
  }

  final KisaluRepository _repositorio;
  bool _terminado = false;

  EstadoUi<PerfilDados> estado = const Carregar();
  bool aTerminar = false;
  bool aMudar = false;
  String? erro;

  Future<void> carregar() async {
    _definir(() => estado = const Carregar());
    await _ler();
  }

  /// O perfil ativo mudou (aqui ou noutro ecrã): relê sem esqueletos.
  void _aoMudar() => _ler();

  Future<void> _ler() async {
    try {
      final utilizador = await _repositorio.utilizador();
      _definir(
        () => estado = Sucesso(
          PerfilDados(
            utilizador: utilizador,
            perfilAtivo: _repositorio.perfilAtivo,
          ),
        ),
      );
    } on KisaluException catch (e) {
      _definir(() => estado = Erro(e.mensagem, semRede: e is SemRedeException));
    }
  }

  /// "Mudar para profissional" / "Mudar para cliente": alterna o perfil da
  /// sessão. Sem registo de profissional completo não muda e manda para o
  /// registo (ecrã 12), que no fim passa a sessão a profissional.
  Future<DestinoMudarPerfil> mudarPerfil() async {
    final atual = estado;
    if (atual is! Sucesso<PerfilDados> || aMudar) {
      return DestinoMudarPerfil.nenhum;
    }
    final novo = atual.dados.perfilAtivo == PerfilUtilizador.cliente
        ? PerfilUtilizador.profissional
        : PerfilUtilizador.cliente;
    if (novo == PerfilUtilizador.profissional &&
        !atual.dados.utilizador.registoProfissionalCompleto) {
      return DestinoMudarPerfil.registo;
    }
    _definir(() {
      aMudar = true;
      erro = null;
    });
    try {
      await _repositorio.mudarPerfil(novo);
      _definir(() => aMudar = false);
      return DestinoMudarPerfil.inicio;
    } on KisaluException catch (e) {
      _definir(() {
        aMudar = false;
        erro = e.mensagem;
      });
      return DestinoMudarPerfil.nenhum;
    }
  }

  /// Devolve true se a sessão terminou e se pode ir para o login.
  Future<bool> terminarSessao() async {
    if (aTerminar) return false;
    _definir(() {
      aTerminar = true;
      erro = null;
    });
    try {
      await _repositorio.terminarSessao();
      _definir(() => aTerminar = false);
      return true;
    } on KisaluException catch (e) {
      _definir(() {
        aTerminar = false;
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
