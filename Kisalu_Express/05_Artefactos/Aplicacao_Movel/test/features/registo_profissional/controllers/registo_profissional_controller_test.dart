import 'package:flutter_test/flutter_test.dart';
import 'package:kisalu_express/core/state/estado_ui.dart';
import 'package:kisalu_express/data/repositories/kisalu_repository.dart';
import 'package:kisalu_express/data/repositories/mock_kisalu_repository.dart';
import 'package:kisalu_express/features/registo_profissional/controllers/registo_profissional_controller.dart';
import 'package:kisalu_express/models/categoria.dart';
import 'package:kisalu_express/models/registo_profissional.dart';
import 'package:kisalu_express/models/utilizador.dart';

class _SemRede extends MockKisaluRepository {
  @override
  Future<List<Categoria>> categorias() => throw const SemRedeException();
}

class _GuardarFalha extends MockKisaluRepository {
  @override
  Future<void> guardarRegistoProfissional(RegistoProfissional registo) =>
      throw const SemRedeException();
}

void main() {
  RegistoProfissionalController novo(MockKisaluRepository r) {
    final c = RegistoProfissionalController(r);
    addTearDown(c.dispose);
    return c;
  }

  test('carrega as categorias e o rascunho do Figma', () async {
    final c = novo(MockKisaluRepository());
    expect(c.estado, isA<Carregar<RegistoDados>>());
    await c.carregar();
    final dados = (c.estado as Sucesso<RegistoDados>).dados;
    expect(dados.categorias, hasLength(13));
    expect(dados.rascunho!.nomeCompleto, 'Joaquim Manuel');
    expect(c.escolhidos, {CategoriaId.canalizador, CategoriaId.pedreiro});
    expect(c.raioKm, 10);
  });

  test('falha de rede ao carregar é Erro', () async {
    final c = novo(_SemRede());
    await c.carregar();
    expect((c.estado as Erro).semRede, isTrue);
  });

  test('mostra 4 serviços e "Mais…" abre os 13', () async {
    final c = novo(MockKisaluRepository());
    await c.carregar();
    final todas = (c.estado as Sucesso<RegistoDados>).dados.categorias;
    expect(c.visiveis(todas).map((x) => x.nome), [
      'Canalizador',
      'Pedreiro',
      'Eletricista',
      'Pintor',
    ]);
    c.mostrarMais();
    expect(c.visiveis(todas), hasLength(13));
  });

  test('alternar serviço marca e desmarca', () async {
    final c = novo(MockKisaluRepository());
    await c.carregar();
    c.alternarServico(CategoriaId.pintor);
    expect(c.escolhidos, contains(CategoriaId.pintor));
    c.alternarServico(CategoriaId.pintor);
    expect(c.escolhidos, isNot(contains(CategoriaId.pintor)));
  });

  test('o raio fica entre 1 e 30 km', () async {
    final c = novo(MockKisaluRepository());
    await c.carregar();
    c.mudarRaio(14.4);
    expect(c.raioKm, 14);
    c.mudarRaio(99);
    expect(c.raioKm, 30);
    c.mudarRaio(-5);
    expect(c.raioKm, 1);
  });

  test('continuar com tudo vazio mostra todos os erros', () async {
    final c = novo(MockKisaluRepository());
    await c.carregar();
    c.escolhidos.clear();
    expect(await c.continuar(nome: '', anos: '', zona: ''), isFalse);
    expect(c.erroNome, 'Escreva o seu nome.');
    expect(c.erroServicos, 'Escolha pelo menos um serviço.');
    expect(c.erroAnos, 'Escreva os seus anos de experiência.');
    expect(c.erroZona, 'Diga-nos a sua zona de atuação.');
  });

  test(
    'validar ao sair ignora vazio e mostra o erro se for inválido',
    () async {
      final c = novo(MockKisaluRepository());
      await c.carregar();
      c.validarAnosAoSair('');
      expect(c.erroAnos, isNull);
      c.validarAnosAoSair('99');
      expect(c.erroAnos, 'Escreva um valor até 60 anos.');
      c.aoEscrever();
      expect(c.erroAnos, isNull);
    },
  );

  test('continuar válido guarda e passa a sessão a profissional', () async {
    final repo = MockKisaluRepository();
    final c = novo(repo);
    await c.carregar();
    expect(
      await c.continuar(
        nome: 'Joaquim Manuel',
        anos: '10',
        zona: 'Viana, Luanda',
      ),
      isTrue,
    );
    expect(repo.perfilAtivo, PerfilUtilizador.profissional);
  });

  test('falha ao guardar fica no ecrã com a mensagem', () async {
    final c = novo(_GuardarFalha());
    await c.carregar();
    expect(
      await c.continuar(nome: 'Joaquim Manuel', anos: '10', zona: 'Viana'),
      isFalse,
    );
    expect(c.erroGeral, 'Sem ligação. Confirme a sua rede e tente outra vez.');
    expect(c.aGuardar, isFalse);
  });
}
