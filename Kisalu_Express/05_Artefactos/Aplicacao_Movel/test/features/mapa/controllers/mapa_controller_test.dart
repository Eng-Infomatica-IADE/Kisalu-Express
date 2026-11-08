import 'package:flutter_test/flutter_test.dart';
import 'package:kisalu_express/core/state/estado_ui.dart';
import 'package:kisalu_express/data/repositories/kisalu_repository.dart';
import 'package:kisalu_express/data/repositories/mock_kisalu_repository.dart';
import 'package:kisalu_express/features/mapa/controllers/mapa_controller.dart';
import 'package:kisalu_express/models/pin_mapa.dart';

class _SemRede extends MockKisaluRepository {
  @override
  Future<List<PinMapa>> pinsMapa() => throw const SemRedeException();
}

class _Vazio extends MockKisaluRepository {
  @override
  Future<List<PinMapa>> pinsMapa() async => [];
}

void main() {
  MapaController novo(MockKisaluRepository r) {
    final c = MapaController(r);
    addTearDown(c.dispose);
    return c;
  }

  test('carrega 4 pins e destaca o Joaquim', () async {
    final c = novo(MockKisaluRepository());
    expect(c.estado, isA<Carregar<List<PinMapa>>>());
    await c.carregar();
    expect((c.estado as Sucesso<List<PinMapa>>).dados, hasLength(4));
    expect(c.selecionadoId, 'p1');
    expect(c.selecionado!.profissional.nome, 'Joaquim Manuel');
  });

  test('os pins estão dentro do mapa (frações entre 0 e 1)', () async {
    final c = novo(MockKisaluRepository());
    await c.carregar();
    for (final p in (c.estado as Sucesso<List<PinMapa>>).dados) {
      expect(p.x, inInclusiveRange(0, 1));
      expect(p.y, inInclusiveRange(0, 1));
    }
  });

  test('selecionar outro pin muda o cartão de baixo', () async {
    final c = novo(MockKisaluRepository());
    await c.carregar();
    c.selecionar('p2');
    expect(c.selecionado!.profissional.nome, 'Ana Cardoso');
  });

  test('sem pins o estado é Vazio e não há selecionado', () async {
    final c = novo(_Vazio());
    await c.carregar();
    expect(c.estado, isA<Vazio<List<PinMapa>>>());
    expect(c.selecionado, isNull);
  });

  test('falha de rede é Erro', () async {
    final c = novo(_SemRede());
    await c.carregar();
    expect((c.estado as Erro).semRede, isTrue);
  });
}
