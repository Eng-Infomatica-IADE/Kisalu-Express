import '../../models/avaliacao.dart';
import '../../models/categoria.dart';
import '../../models/codigo_confirmacao.dart';
import '../../models/novo_pedido.dart';
import '../../models/utilizador.dart';

/// Relógio, utilizador e conteúdo de ecrãs com estado local (dados fictícios).
abstract final class MockSessao {
  /// Relógio fixo: terça, 20/10/2026, 15h00. Faz "Hoje", "chega em 40 min"
  /// e "Boa tarde" baterem certo com os mockups.
  static final agora = DateTime(2026, 10, 20, 15);

  static const utilizador = Utilizador(
    nome: 'Maria',
    zona: 'Talatona, Luanda',
    temNovidades: true,
    nomeCompleto: 'Maria Kiala',
    telemovel: '+244923000000',
    moradasGuardadas: 2,
    favoritos: 3,
  );

  /// Mesma sessão vista no modo profissional (ecrã 20 com "Mudar para
  /// cliente").
  static const utilizadorProfissional = Utilizador(
    nome: 'Joaquim',
    zona: 'Viana, Luanda',
    nomeCompleto: 'Joaquim Manuel',
    telemovel: '+244923000000',
    moradasGuardadas: 2,
    favoritos: 3,
  );

  /// Valor do campo do ecrã 01 no Figma.
  static const telemovelPredefinido = '+244 923 000 000';

  /// Código SMS do ecrã 11 no Figma (5 de 6 dígitos escritos).
  static const codigoSmsPredefinido = '48217';

  /// Código do cliente escrito no ecrã 16 no Figma.
  static const codigoClientePredefinido = '482173';

  /// QR fictício: texto opaco sem relação com o id nem com o código.
  static const tokenQr = 'kx_qr_8Wm4Zt1LrQ7cXb2NvHs9YdKe5AuPj3Gf0';

  /// Código alternativo do ecrã 05.
  static const codigoQr = '482173';

  static CodigoConfirmacao codigoConfirmacao(String pedidoId) =>
      CodigoConfirmacao(
        pedidoId: pedidoId,
        token: tokenQr,
        codigo: codigoQr,
        validoAte: agora.add(const Duration(minutes: 10)),
      );

  /// Passo 3/4 "Rever o pedido" do ecrã 10.
  static const rascunhoPedido = NovoPedido(
    categoriaId: CategoriaId.canalizador,
    titulo: 'Fuga de água na cozinha',
    descricao:
        'Cano a pingar debaixo do lava-loiça. Precisa de reparação hoje.',
    zona: 'Talatona',
    pontoReferencia: 'perto da cantina do Sr. Zé',
    numFotos: 1,
  );

  /// Estado inicial do ecrã 06 no Figma.
  static const rascunhoAvaliacao = NovaAvaliacao(
    estrelas: 4,
    etiquetas: [
      EtiquetaAvaliacao.pontual,
      EtiquetaAvaliacao.precoJusto,
      EtiquetaAvaliacao.trabalhoLimpo,
    ],
    comentario: 'Resolveu tudo em 40 minutos. Voltaria a chamar.',
  );

  /// "Já avisámos 8 canalizadores perto de si." (ecrã 10, com rede)
  static const profissionaisAvisados = 8;
}
