import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kisalu_express/core/state/estado_ui.dart';
import 'package:kisalu_express/data/repositories/mock_kisalu_repository.dart';
import 'package:kisalu_express/features/novo_pedido/controllers/novo_pedido_controller.dart';
import 'package:kisalu_express/models/categoria.dart';

NovoPedidoController _c(MockKisaluRepository repo) =>
    NovoPedidoController(repo, pausaTentativa: Duration.zero);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  test('com rascunho abre no passo de rever, sem rede', () async {
    final c = _c(MockKisaluRepository());
    await c.carregar();
    expect(c.estado, isA<Sucesso<dynamic>>());
    expect(c.passo, PassoNovoPedido.rever);
    expect(c.titulo, 'Fuga de água na cozinha');
    expect(c.semRede, isTrue);
    expect(c.temPassoAnterior, isFalse);
    expect(c.dataEditavel, isFalse);
  });

  test(
    '"Tentar outra vez" sem rede continua sem rede, com rede recupera',
    () async {
      final repo = MockKisaluRepository();
      final c = _c(repo);
      await c.carregar();
      await c.tentarOutraVez();
      expect(c.semRede, isTrue);
      expect(await c.publicar(), isFalse);
      repo.semRede = false;
      await c.tentarOutraVez();
      expect(c.semRede, isFalse);
      expect(await c.publicar(), isTrue);
      expect(c.publicado!.profissionaisAvisados, 8);
      expect(c.publicado!.categoriaPlural, 'canalizadores');
    },
  );

  test('passo 1 valida categoria, título e descrição', () async {
    final c = _c(MockKisaluRepository());
    await c.carregar(passoInicial: PassoNovoPedido.descricao);
    expect(c.passo, PassoNovoPedido.descricao);
    expect(c.avancar(), isFalse);
    expect(c.erroCategoria, 'Escolha o tipo de serviço.');
    expect(
      c.erroTitulo,
      'Dê um título curto ao pedido. Exemplo: Fuga de água na cozinha.',
    );
    expect(
      c.erroDescricao,
      'Descreva o problema para receber propostas certas.',
    );
    c.escolherCategoria(CategoriaId.canalizador);
    c.aoEscreverTitulo('Fuga de água');
    c.aoEscreverDescricao('Cano a pingar debaixo do lava-loiça.');
    expect(c.avancar(), isTrue);
    expect(c.passo, PassoNovoPedido.morada);
  });

  test('só valida o ponto de referência ao sair e ao submeter', () async {
    final c = _c(MockKisaluRepository());
    await c.carregar(passoInicial: PassoNovoPedido.morada);
    c.aoSairPonto();
    expect(c.erroPonto, isNull); // vazio ao sair não é erro
    c.aoEscreverPonto('ab');
    c.aoSairPonto();
    expect(
      c.erroPonto,
      'Dê um pouco mais de detalhe. Exemplo: Perto da cantina do Sr. Zé.',
    );
    c.aoEscreverPonto('abc');
    expect(c.erroPonto, isNull); // some ao escrever
    expect(c.avancar(), isFalse);
    expect(c.erroZona, isNotNull);
  });

  test('fluxo completo 1 → 2 → 3 e alterar a data (4)', () async {
    final repo = MockKisaluRepository(semRede: false);
    final c = _c(repo);
    await c.carregar(passoInicial: PassoNovoPedido.descricao);
    c.escolherCategoria(CategoriaId.canalizador);
    c.aoEscreverTitulo('Fuga de água');
    c.aoEscreverDescricao('Cano a pingar debaixo do lava-loiça.');
    c.adicionarFoto();
    c.avancar();
    c.aoEscreverZona('Talatona');
    c.aoEscreverPonto('perto da cantina do Sr. Zé');
    c.avancar();
    expect(c.passo, PassoNovoPedido.rever);
    expect(c.semRede, isFalse);
    expect(c.dataEditavel, isTrue);
    c.alterarData();
    expect(c.passo, PassoNovoPedido.data);
    c.escolherData(DateTime(2026, 10, 19, 10)); // ontem
    expect(c.erroData, 'Escolha uma data a partir de hoje.');
    expect(c.avancar(), isFalse);
    c.escolherData(repo.agora().add(const Duration(days: 1)));
    expect(c.avancar(), isTrue);
    expect(c.passo, PassoNovoPedido.rever);
    expect(await c.publicar(), isTrue);
  });

  test('voltar percorre os passos e devolve false no primeiro', () async {
    final c = _c(MockKisaluRepository());
    await c.carregar(passoInicial: PassoNovoPedido.morada);
    expect(c.voltar(), isTrue);
    expect(c.passo, PassoNovoPedido.descricao);
    expect(c.voltar(), isFalse);
  });

  group('editar, pedir de novo e rascunho (QA)', () {
    test('publicar com sucesso apaga o rascunho guardado', () async {
      final repo = MockKisaluRepository(semRede: false);
      final c = _c(repo);
      await c.carregar();
      expect(await c.publicar(), isTrue);
      expect(await repo.rascunhoPedido(), isNull);
    });

    test('avançar um passo guarda o rascunho; sem rede também', () async {
      final repo = MockKisaluRepository(semRede: false);
      await repo.apagarRascunhoPedido();
      final c = _c(repo);
      await c.carregar(passoInicial: PassoNovoPedido.descricao);
      c.escolherCategoria(CategoriaId.eletricista);
      c.aoEscreverTitulo('Tomada sem luz');
      c.aoEscreverDescricao('A tomada da sala deixou de dar luz.');
      expect(c.avancar(), isTrue);
      await Future<void>.delayed(Duration.zero);
      expect((await repo.rascunhoPedido())!.titulo, 'Tomada sem luz');
    });

    test('editar abre preenchido e grava com PATCH', () async {
      final repo = MockKisaluRepository(semRede: false);
      final c = _c(repo);
      await c.carregar(editarId: 'ped1');
      expect(c.modo, ModoNovoPedido.editar);
      expect(c.passo, PassoNovoPedido.descricao);
      expect(c.titulo, 'Fuga de água na cozinha');
      expect(c.zona, 'Talatona');
      expect(c.pontoReferencia, 'perto da cantina do Sr. Zé');
      c.aoEscreverTitulo('Fuga de água grande');
      expect(c.avancar(), isTrue);
      expect(c.passo, PassoNovoPedido.morada);
      c.aoEscreverZona('Kilamba');
      expect(c.avancar(), isTrue);
      expect(c.passo, PassoNovoPedido.rever);
      expect(await c.publicar(), isTrue);
      expect(repo.editados['ped1']!.zona, 'Kilamba');
      expect(c.editado!.titulo, 'Fuga de água grande');
      expect(c.publicado, isNull);
      expect(repo.editados['ped1']!.titulo, 'Fuga de água grande');
      // Editar não mexe no rascunho do pedido novo.
      expect(await repo.rascunhoPedido(), isNotNull);
    });

    test('não edita um pedido com proposta aceite', () async {
      final repo = MockKisaluRepository();
      await repo.aceitarProposta('ped1', 'pr1');
      final c = _c(repo);
      await c.carregar(editarId: 'ped1');
      expect(c.estado, isA<Erro<dynamic>>());
    });

    test('pedir de novo começa preenchido a partir do antigo', () async {
      final repo = MockKisaluRepository(semRede: false);
      final c = _c(repo);
      await c.carregar(deId: 'ped2');
      expect(c.modo, ModoNovoPedido.pedirDeNovo);
      expect(c.passo, PassoNovoPedido.descricao);
      expect(c.titulo, 'Tomada sem luz');
      expect(c.categoriaId, CategoriaId.eletricista);
      expect(c.avancar(), isTrue);
      expect(c.avancar(), isTrue);
      expect(c.passo, PassoNovoPedido.rever);
      expect(await c.publicar(), isTrue);
      expect(c.publicado, isNotNull);
    });
  });
}
