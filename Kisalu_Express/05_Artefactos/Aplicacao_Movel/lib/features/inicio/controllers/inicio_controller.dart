import 'package:flutter/foundation.dart';

import '../../../core/state/estado_ui.dart';
import '../../../data/repositories/kisalu_repository.dart';
import '../../../models/categoria.dart';
import '../../../models/profissional.dart';
import '../../../models/utilizador.dart';

/// Dados do ecrã 02, já prontos a desenhar.
class InicioDados {
  const InicioDados({
    required this.utilizador,
    required this.saudacao,
    required this.categorias,
    required this.profissionais,
    this.naoLidas = 0,
  });

  final Utilizador utilizador;

  /// "Boa tarde" (conforme a hora do repositório).
  final String saudacao;

  /// Só as da grelha (emDestaque).
  final List<Categoria> categorias;
  final List<Profissional> profissionais;

  /// Notificações por ler: ponto vermelho do sino.
  final int naoLidas;
}

class InicioController extends ChangeNotifier {
  InicioController(this._repositorio, {required this.saudacaoPara});

  final KisaluRepository _repositorio;

  /// `KFormat.saudacao`, injetado para o controller não importar utilitários
  /// de apresentação.
  final String Function(DateTime agora) saudacaoPara;
  bool _terminado = false;

  EstadoUi<InicioDados> estado = const Carregar();

  /// Estado local: o banner pode ser fechado (P06).
  bool bannerVisivel = true;

  /// A categoria destacada no Figma.
  String categoriaSelecionada = CategoriaId.canalizador;

  Future<void> carregar() async {
    _definir(() => estado = const Carregar());
    await recarregar();
  }

  /// Releitura sem esqueletos (pull-to-refresh, voltar ao separador ou à
  /// lista de notificações).
  Future<void> recarregar() async {
    try {
      final utilizador = await _repositorio.utilizador();
      final categorias = (await _repositorio.categorias())
          .where((c) => c.emDestaque)
          .toList();
      final profissionais = await _repositorio.profissionaisPertoDeSi();
      final naoLidas = await _naoLidas();
      final dados = InicioDados(
        naoLidas: naoLidas,
        utilizador: utilizador,
        saudacao: saudacaoPara(_repositorio.agora()),
        categorias: categorias,
        profissionais: profissionais,
      );
      _definir(
        () => estado = categorias.isEmpty && profissionais.isEmpty
            ? const Vazio()
            : Sucesso(dados),
      );
    } on KisaluException catch (e) {
      _definir(() => estado = Erro(e.mensagem, semRede: e is SemRedeException));
    }
  }

  /// O sino não deve deitar abaixo o Início: falha → sem ponto.
  Future<int> _naoLidas() async {
    try {
      return await _repositorio.notificacoesPorLer();
    } on KisaluException {
      return 0;
    }
  }

  void fecharBanner() {
    if (bannerVisivel) _definir(() => bannerVisivel = false);
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
