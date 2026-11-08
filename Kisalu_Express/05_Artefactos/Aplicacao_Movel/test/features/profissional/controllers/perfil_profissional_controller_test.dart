import 'package:flutter_test/flutter_test.dart';
import 'package:kisalu_express/core/state/estado_ui.dart';
import 'package:kisalu_express/data/repositories/kisalu_repository.dart';
import 'package:kisalu_express/data/repositories/mock_kisalu_repository.dart';
import 'package:kisalu_express/features/profissional/controllers/perfil_profissional_controller.dart';
import 'package:kisalu_express/models/estatisticas_avaliacoes.dart';
import 'package:kisalu_express/models/profissional.dart';

class _SemRede extends MockKisaluRepository {
  @override
  Future<Profissional?> profissional(String id) =>
      throw const SemRedeException();
}

class _EstatisticaFalha extends MockKisaluRepository {
  @override
  Future<EstatisticasAvaliacoes?> estatisticasAvaliacoes(String id) =>
      throw const SemRedeException();
}

void main() {
  test('carrega o profissional', () async {
    final c = PerfilProfissionalController(MockKisaluRepository(), 'p1');
    expect(c.estado, isA<Carregar<Profissional>>());
    await c.carregar();
    final p = (c.estado as Sucesso<Profissional>).dados;
    expect(p.nome, 'Joaquim Manuel');
    expect(p.maoDeObraDesde, 8000);
  });

  test('id desconhecido dá "não encontrado"', () async {
    final c = PerfilProfissionalController(MockKisaluRepository(), 'zzz');
    await c.carregar();
    expect((c.estado as Erro<Profissional>).naoEncontrado, isTrue);
  });

  test('falha de rede dá Erro com semRede', () async {
    final c = PerfilProfissionalController(_SemRede(), 'p1');
    await c.carregar();
    final e = c.estado as Erro<Profissional>;
    expect(e.semRede, isTrue);
    expect(e.naoEncontrado, isFalse);
  });

  test('carrega também as "Avaliações em números"', () async {
    final c = PerfilProfissionalController(MockKisaluRepository(), 'p1');
    await c.carregar();
    final e = c.estatisticas!;
    expect(e.n, 126);
    expect(e.media, 4.79);
    expect(e.ic95!.inferior, 4.69);
    expect(e.distribuicao.values.reduce((a, b) => a + b), 126);
  });

  test('se a estatística falhar, o perfil aparece na mesma', () async {
    final c = PerfilProfissionalController(_EstatisticaFalha(), 'p1');
    await c.carregar();
    expect(c.estado, isA<Sucesso<Profissional>>());
    expect(c.estatisticas, isNull);
  });
}
