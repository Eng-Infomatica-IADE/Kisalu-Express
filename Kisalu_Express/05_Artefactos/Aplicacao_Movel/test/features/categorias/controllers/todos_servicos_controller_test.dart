import 'package:flutter_test/flutter_test.dart';
import 'package:kisalu_express/core/state/estado_ui.dart';
import 'package:kisalu_express/data/repositories/kisalu_repository.dart';
import 'package:kisalu_express/data/repositories/mock_kisalu_repository.dart';
import 'package:kisalu_express/features/categorias/controllers/todos_servicos_controller.dart';
import 'package:kisalu_express/models/categoria.dart';

class _SemRede extends MockKisaluRepository {
  @override
  Future<List<Categoria>> categorias() => throw const SemRedeException();
}

class _Vazio extends MockKisaluRepository {
  @override
  Future<List<Categoria>> categorias() async => [];
}

void main() {
  TodosServicosController novo(MockKisaluRepository r) {
    final c = TodosServicosController(r);
    addTearDown(c.dispose);
    return c;
  }

  test('carrega as 13 categorias, sem filtro', () async {
    final c = novo(MockKisaluRepository());
    expect(c.estado, isA<Carregar<List<Categoria>>>());
    await c.carregar();
    expect(c.filtradas, hasLength(13));
  });

  test('sem categorias o estado é Vazio e não há resultados', () async {
    final c = novo(_Vazio());
    await c.carregar();
    expect(c.estado, isA<Vazio<List<Categoria>>>());
    expect(c.filtradas, isEmpty);
  });

  test('falha de rede é Erro', () async {
    final c = novo(_SemRede());
    await c.carregar();
    expect((c.estado as Erro).semRede, isTrue);
  });

  test('a pesquisa filtra por parte do nome, sem maiúsculas', () async {
    final c = novo(MockKisaluRepository());
    await c.carregar();
    c.pesquisar('ELE');
    expect(c.filtradas.map((x) => x.nome), ['Eletricista', 'Cabeleireira']);
    c.pesquisar('ra');
    expect(c.filtradas.map((x) => x.nome), contains('Transporte'));
    expect(c.filtradas.map((x) => x.nome), isNot(contains('Pintor')));
  });

  test('a pesquisa ignora acentos nos dois sentidos', () async {
    final c = novo(MockKisaluRepository());
    await c.carregar();
    c.pesquisar('mecanico');
    expect(c.filtradas.map((x) => x.nome), ['Mecânico']);
    c.pesquisar('informática');
    expect(c.filtradas.map((x) => x.nome), ['Informática']);
    c.pesquisar('informatica');
    expect(c.filtradas.map((x) => x.nome), ['Informática']);
  });

  test('sem correspondência a lista fica vazia e limpar volta às 13', () async {
    final c = novo(MockKisaluRepository());
    await c.carregar();
    c.pesquisar('zzz');
    expect(c.filtradas, isEmpty);
    c.pesquisar('   ');
    expect(c.filtradas, hasLength(13));
  });
}
