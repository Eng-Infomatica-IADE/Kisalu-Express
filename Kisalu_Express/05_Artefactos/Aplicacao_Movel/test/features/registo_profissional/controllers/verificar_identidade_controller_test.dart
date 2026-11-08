import 'package:flutter_test/flutter_test.dart';
import 'package:kisalu_express/core/state/estado_ui.dart';
import 'package:kisalu_express/data/repositories/kisalu_repository.dart';
import 'package:kisalu_express/data/repositories/mock_kisalu_repository.dart';
import 'package:kisalu_express/features/registo_profissional/controllers/verificar_identidade_controller.dart';
import 'package:kisalu_express/models/verificacao_identidade.dart';

class _SemRede extends MockKisaluRepository {
  @override
  Future<VerificacaoIdentidade> verificacaoIdentidade() =>
      throw const SemRedeException();
}

void main() {
  VerificarIdentidadeController novo(MockKisaluRepository r) {
    final c = VerificarIdentidadeController(r);
    addTearDown(c.dispose);
    return c;
  }

  test('arranca com documento enviado e rosto em falta', () async {
    final c = novo(MockKisaluRepository());
    expect(c.estado, isA<Carregar<VerificacaoIdentidade>>());
    await c.carregar();
    final v = (c.estado as Sucesso<VerificacaoIdentidade>).dados;
    expect(v.documentoEnviado, isTrue);
    expect(v.rostoEnviado, isFalse);
  });

  test('falha de rede ao carregar é Erro', () async {
    final c = novo(_SemRede());
    await c.carregar();
    expect((c.estado as Erro).semRede, isTrue);
  });

  test('enviar sem o rosto fica no ecrã com aviso', () async {
    final c = novo(MockKisaluRepository());
    await c.carregar();
    expect(await c.enviar(), isFalse);
    expect(c.erro, 'Falta a fotografia do rosto. Adicione-a para enviar.');
    expect(c.aEnviar, isFalse);
  });

  test('adicionar o rosto completa e permite enviar', () async {
    final c = novo(MockKisaluRepository());
    await c.carregar();
    await c.adicionarFotoRosto();
    final v = (c.estado as Sucesso<VerificacaoIdentidade>).dados;
    expect(v.completa, isTrue);
    expect(await c.enviar(), isTrue);
    expect(c.erro, isNull);
  });

  test('adicionar o rosto duas vezes é inofensivo', () async {
    final c = novo(MockKisaluRepository());
    await c.carregar();
    await c.adicionarFotoRosto();
    await c.adicionarFotoRosto();
    expect((c.estado as Sucesso<VerificacaoIdentidade>).dados.completa, isTrue);
  });
}
