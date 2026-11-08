import 'package:flutter_test/flutter_test.dart';
import 'package:kisalu_express/core/state/estado_ui.dart';
import 'package:kisalu_express/data/repositories/kisalu_repository.dart';
import 'package:kisalu_express/data/repositories/mock_kisalu_repository.dart';
import 'package:kisalu_express/features/proposta/controllers/enviar_proposta_controller.dart';
import 'package:kisalu_express/models/nova_proposta.dart';

class _SemRede extends MockKisaluRepository {
  @override
  Future<void> enviarProposta(NovaProposta proposta) =>
      throw const SemRedeException();
}

void main() {
  EnviarPropostaController novo(MockKisaluRepository r, [String id = 'pp1']) {
    final c = EnviarPropostaController(r, id);
    addTearDown(c.dispose);
    return c;
  }

  test('carrega o pedido e os valores do Figma', () async {
    final c = novo(MockKisaluRepository());
    expect(c.estado, isA<Carregar<EnviarPropostaDados>>());
    await c.carregar();
    final d = (c.estado as Sucesso<EnviarPropostaDados>).dados;
    expect(d.pedido.titulo, 'Fuga de água na cozinha');
    expect(c.valores[ComponenteValor.maoDeObra], 8000);
    expect(c.valores[ComponenteValor.material], 3500);
    expect(c.valores[ComponenteValor.deslocacao], 1000);
    expect(c.valorFechado, 12500);
    expect(c.chegada, ChegadaProposta.quarentaMinutos);
  });

  test('pedido desconhecido é "não encontrado"', () async {
    final c = novo(MockKisaluRepository(), 'zzz');
    await c.carregar();
    expect((c.estado as Erro).naoEncontrado, isTrue);
  });

  test('o valor fechado acompanha os componentes', () async {
    final c = novo(MockKisaluRepository());
    await c.carregar();
    c.alterar(ComponenteValor.material, '5.000 Kz');
    expect(c.valorFechado, 14000);
    c.alterar(ComponenteValor.deslocacao, '0');
    expect(c.valorFechado, 13000);
  });

  test('texto inválido deixa o componente sem valor', () async {
    final c = novo(MockKisaluRepository());
    await c.carregar();
    c.alterar(ComponenteValor.material, 'abc');
    expect(c.valores[ComponenteValor.material], isNull);
    expect(c.valorFechado, 9000);
    c.validarAoSair(ComponenteValor.material, 'abc');
    expect(
      c.erros[ComponenteValor.material],
      'Use só números. Exemplo: 12.500 Kz.',
    );
    c.alterar(ComponenteValor.material, '3500');
    expect(c.erros[ComponenteValor.material], isNull);
  });

  test('cêntimos têm mensagem própria', () async {
    final c = novo(MockKisaluRepository());
    await c.carregar();
    c.validarAoSair(ComponenteValor.maoDeObra, '8000,50');
    expect(
      c.erros[ComponenteValor.maoDeObra],
      'Escreva o valor sem cêntimos. Exemplo: 12.500 Kz.',
    );
  });

  test('enviar com um campo vazio mostra o erro e não envia', () async {
    final repo = MockKisaluRepository();
    final c = novo(repo);
    await c.carregar();
    c.alterar(ComponenteValor.maoDeObra, '');
    expect(await c.enviar(), isFalse);
    expect(
      c.erros[ComponenteValor.maoDeObra],
      'Escreva o valor de mão de obra. Se não cobra, escreva 0.',
    );
    expect(repo.propostasEnviadas, isEmpty);
  });

  test('valor total abaixo do mínimo não envia', () async {
    final repo = MockKisaluRepository();
    final c = novo(repo);
    await c.carregar();
    c.alterar(ComponenteValor.maoDeObra, '100');
    c.alterar(ComponenteValor.material, '0');
    c.alterar(ComponenteValor.deslocacao, '0');
    expect(await c.enviar(), isFalse);
    expect(c.erroGeral, 'O valor mínimo é 500 Kz.');
    expect(repo.propostasEnviadas, isEmpty);
  });

  test('enviar válido guarda a proposta com a chegada escolhida', () async {
    final repo = MockKisaluRepository();
    final c = novo(repo);
    await c.carregar();
    c.escolherChegada(ChegadaProposta.umaHora);
    expect(await c.enviar(), isTrue);
    final enviada = repo.propostasEnviadas.single;
    expect(enviada.pedidoId, 'pp1');
    expect(enviada.valorFechado, 12500);
    expect(enviada.chegada, ChegadaProposta.umaHora);
  });

  test('falha de rede ao enviar fica no ecrã', () async {
    final c = novo(_SemRede());
    await c.carregar();
    expect(await c.enviar(), isFalse);
    expect(c.erroGeral, 'Sem ligação. Confirme a sua rede e tente outra vez.');
    expect(c.aEnviar, isFalse);
  });
}
