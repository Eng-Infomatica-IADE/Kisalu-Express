import 'package:flutter_test/flutter_test.dart';
import 'package:kisalu_express/core/state/estado_ui.dart';
import 'package:kisalu_express/data/repositories/kisalu_repository.dart';
import 'package:kisalu_express/data/repositories/mock_kisalu_repository.dart';
import 'package:kisalu_express/features/confirmacao_profissional/controllers/ler_qr_controller.dart';
import 'package:kisalu_express/models/utilizador.dart';

class _SemRede extends MockKisaluRepository {
  @override
  Future<String?> codigoClientePredefinido() => throw const SemRedeException();
}

class _SemPredefinido extends MockKisaluRepository {
  @override
  Future<String?> codigoClientePredefinido() async => null;
}

void main() {
  LerQrController novo(MockKisaluRepository r) {
    final c = LerQrController(r);
    addTearDown(c.dispose);
    return c;
  }

  test('o campo arranca com "482 173"', () async {
    final c = novo(MockKisaluRepository());
    expect(c.estado, isA<Carregar<String>>());
    await c.carregar();
    expect((c.estado as Sucesso<String>).dados, '482 173');
  });

  test('sem código predefinido o estado é Vazio', () async {
    final c = novo(_SemPredefinido());
    await c.carregar();
    expect(c.estado, isA<Vazio<String>>());
  });

  test('falha de rede ao carregar é Erro', () async {
    final c = novo(_SemRede());
    await c.carregar();
    expect((c.estado as Erro).semRede, isTrue);
  });

  test('formato inválido não chama o repositório', () async {
    final repo = MockKisaluRepository();
    final c = novo(repo);
    expect(await c.confirmar('48'), isNull);
    expect(c.erro, 'Faltam 4 números. O código tem 6 dígitos.');
    expect(await c.confirmar(''), isNull);
    expect(c.erro, 'Escreva o código que o cliente lhe disse.');
    expect(await c.confirmar('12a456'), isNull);
    expect(c.erro, 'Use só números. Exemplo: 482 173.');
    expect(await repo.servicoConfirmado('tp1'), isNotNull); // só o de demo
  });

  test('qualquer código de 6 dígitos confirma o trabalho tp1', () async {
    final c = novo(MockKisaluRepository());
    expect(await c.confirmar('482 173'), 'tp1');
    expect(c.erro, isNull);
    expect(await c.confirmar('123456'), 'tp1');
  });

  test('000000 não confere e fica no ecrã', () async {
    final c = novo(MockKisaluRepository());
    expect(await c.confirmar('000000'), isNull);
    expect(c.erro, 'O código não está certo. Confirme com o cliente.');
    expect(c.aConfirmar, isFalse);
    c.aoEscrever();
    expect(c.erro, isNull);
  });

  test('confirmar passa o trabalho do profissional a concluído', () async {
    final repo = MockKisaluRepository();
    await repo.mudarPerfil(PerfilUtilizador.profissional);
    final c = novo(repo);
    await c.confirmar('482173');
    final lista = await repo.historico();
    expect(lista.first.id, 'tp1');
    expect(lista.first.estado.rotulo, 'Concluído');
  });
}
