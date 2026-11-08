import 'package:flutter_test/flutter_test.dart';
import 'package:kisalu_express/core/state/estado_ui.dart';
import 'package:kisalu_express/core/utils/k_format.dart';
import 'package:kisalu_express/data/repositories/kisalu_repository.dart';
import 'package:kisalu_express/data/repositories/mock_kisalu_repository.dart';
import 'package:kisalu_express/features/inicio/controllers/inicio_controller.dart';
import 'package:kisalu_express/models/categoria.dart';
import 'package:kisalu_express/models/profissional.dart';

class _SemRede extends MockKisaluRepository {
  @override
  Future<List<Categoria>> categorias() => throw const SemRedeException();
}

class _Vazio extends MockKisaluRepository {
  @override
  Future<List<Categoria>> categorias() async => [];
  @override
  Future<List<Profissional>> profissionaisPertoDeSi() async => [];
}

void main() {
  InicioController novo(MockKisaluRepository r) =>
      InicioController(r, saudacaoPara: KFormat.saudacao);

  test('carrega dados do Início', () async {
    final c = novo(MockKisaluRepository());
    expect(c.estado, isA<Carregar<InicioDados>>());
    await c.carregar();
    final d = (c.estado as Sucesso<InicioDados>).dados;
    expect(d.saudacao, 'Boa tarde');
    expect(d.utilizador.nome, 'Maria');
    expect(d.categorias, hasLength(8));
    expect(d.categorias.every((x) => x.emDestaque), isTrue);
    expect(d.profissionais.map((p) => p.nome), [
      'Joaquim Manuel',
      'Ana Cardoso',
    ]);
    expect(c.categoriaSelecionada, CategoriaId.canalizador);
  });

  test('o banner fecha e fica fechado', () async {
    final c = novo(MockKisaluRepository());
    expect(c.bannerVisivel, isTrue);
    c.fecharBanner();
    expect(c.bannerVisivel, isFalse);
  });

  test('sem dados o estado é Vazio', () async {
    final c = novo(_Vazio());
    await c.carregar();
    expect(c.estado, isA<Vazio<InicioDados>>());
  });

  test('falha de rede dá Erro com semRede', () async {
    final c = novo(_SemRede());
    await c.carregar();
    final e = c.estado as Erro<InicioDados>;
    expect(e.semRede, isTrue);
    expect(e.mensagem, 'Sem ligação. Confirme a sua rede e tente outra vez.');
  });
}
