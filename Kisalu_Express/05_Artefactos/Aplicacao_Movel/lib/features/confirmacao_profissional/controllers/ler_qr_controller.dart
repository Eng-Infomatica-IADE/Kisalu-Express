import 'package:flutter/foundation.dart';

import '../../../core/state/estado_ui.dart';
import '../../../core/utils/k_format.dart';
import '../../../core/validators/k_validators.dart';
import '../../../data/repositories/kisalu_repository.dart';
import '../../../models/trabalho_por_confirmar.dart';

/// Estado do ecrã 16 · Confirmar serviço (separador QR do profissional). Não
/// há leitura por câmara: o visor é só desenho e o código de 6 dígitos que o
/// cliente diz é a forma de confirmar.
class LerQrController extends ChangeNotifier {
  LerQrController(this._repositorio);

  final KisaluRepository _repositorio;
  bool _terminado = false;

  /// Código com que o campo arranca, já formatado ("482 173"); Vazio = em
  /// branco.
  EstadoUi<String> estado = const Carregar();
  String? erro;
  bool aConfirmar = false;

  /// Trabalhos à espera do código (serviço, cliente e valor). Com mais do
  /// que um, o ecrã lista-os; o código do cliente diz qual se confirma.
  List<TrabalhoPorConfirmar> trabalhos = const [];

  /// O único trabalho por confirmar; null se há zero ou vários.
  TrabalhoPorConfirmar? get trabalho =>
      trabalhos.length == 1 ? trabalhos.single : null;

  Future<void> carregar() async {
    _definir(() => estado = const Carregar());
    try {
      trabalhos = await _repositorio.trabalhosPorConfirmar();
      final codigo = await _repositorio.codigoClientePredefinido();
      _definir(
        () => estado = codigo == null || codigo.isEmpty
            ? const Vazio()
            : Sucesso(KFormat.codigo(codigo)),
      );
    } on KisaluException catch (e) {
      _definir(() => estado = Erro(e.mensagem, semRede: e is SemRedeException));
    }
  }

  /// Volta a ler a lista (separador escolhido outra vez) sem mexer no campo.
  Future<void> recarregar() async {
    try {
      final novos = await _repositorio.trabalhosPorConfirmar();
      _definir(() => trabalhos = novos);
    } on KisaluException {
      // Fica a lista anterior.
    }
  }

  /// Ao escrever, o erro desaparece (só se revalida ao confirmar).
  void aoEscrever() {
    if (erro != null) _definir(() => erro = null);
  }

  /// "Confirmar serviço": valida o formato e chama o repositório. Devolve o
  /// id do pedido confirmado, ou null se ficou no ecrã.
  Future<String?> confirmar(String codigo) async {
    if (aConfirmar) return null;
    final invalido = KValidators.codigoConfirmacao(codigo);
    if (invalido != null) {
      _definir(() => erro = invalido);
      return null;
    }
    _definir(() {
      erro = null;
      aConfirmar = true;
    });
    try {
      final servico = await _repositorio.confirmarServicoComCodigo(
        KValidators.normalizarCodigo(codigo)!,
      );
      _definir(() => aConfirmar = false);
      return servico.pedidoId;
    } on KisaluException catch (e) {
      _definir(() {
        aConfirmar = false;
        erro = e.mensagem;
      });
      return null;
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
