import 'package:flutter_test/flutter_test.dart';
import 'package:kisalu_express/core/state/estado_ui.dart';
import 'package:kisalu_express/data/repositories/kisalu_repository.dart';
import 'package:kisalu_express/data/repositories/mock_kisalu_repository.dart';
import 'package:kisalu_express/features/confirmacao_profissional/controllers/servico_confirmado_controller.dart';
import 'package:kisalu_express/models/servico_confirmado.dart';

class _SemRede extends MockKisaluRepository {
  @override
  Future<ServicoConfirmado?> servicoConfirmado(String pedidoId) =>
      throw const SemRedeException();
}

void main() {
  ServicoConfirmadoController novo(MockKisaluRepository r, String id) {
    final c = ServicoConfirmadoController(r, id);
    addTearDown(c.dispose);
    return c;
  }

  test('carrega o serviço do Figma', () async {
    final c = novo(MockKisaluRepository(), 'tp1');
    expect(c.estado, isA<Carregar<ServicoConfirmadoDados>>());
    await c.carregar();
    final s = (c.estado as Sucesso<ServicoConfirmadoDados>).dados.servico;
    expect(s.servico, 'Fuga de água na cozinha');
    expect(s.cliente, 'Maria K.');
    expect(s.valor, 12500);
    expect(s.data.hour, 15);
    expect(s.data.minute, 52);
  });

  test('id desconhecido é "não encontrado"', () async {
    final c = novo(MockKisaluRepository(), 'zzz');
    await c.carregar();
    expect((c.estado as Erro).naoEncontrado, isTrue);
  });

  test('falha de rede é Erro', () async {
    final c = novo(_SemRede(), 'tp1');
    await c.carregar();
    expect((c.estado as Erro).semRede, isTrue);
  });
}
