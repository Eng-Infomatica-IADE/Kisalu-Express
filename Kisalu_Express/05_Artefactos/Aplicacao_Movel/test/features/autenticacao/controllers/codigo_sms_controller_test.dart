// ignore: depend_on_referenced_packages
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kisalu_express/core/state/estado_ui.dart';
import 'package:kisalu_express/data/repositories/kisalu_repository.dart';
import 'package:kisalu_express/data/repositories/mock_kisalu_repository.dart';
import 'package:kisalu_express/features/autenticacao/controllers/codigo_sms_controller.dart';
import 'package:kisalu_express/models/pedido_codigo_sms.dart';
import 'package:kisalu_express/models/utilizador.dart';

class _SemRede extends MockKisaluRepository {
  @override
  Future<PedidoCodigoSms> codigoSmsPendente() => throw const SemRedeException();
}

class _ReenvioFalha extends MockKisaluRepository {
  bool falhar = false;

  @override
  Future<void> pedirCodigoSms(
    String telemovel,
    PerfilUtilizador perfil, {
    bool criarConta = false,
  }) {
    if (falhar) throw const SemRedeException();
    return super.pedirCodigoSms(telemovel, perfil, criarConta: criarConta);
  }
}

void main() {
  CodigoSmsController novo(MockKisaluRepository r, {int segundos = 42}) {
    final c = CodigoSmsController(r, segundosReenvio: segundos);
    addTearDown(c.dispose);
    return c;
  }

  test('carrega o pedido em curso e o código predefinido', () async {
    final repo = MockKisaluRepository();
    await repo.pedirCodigoSms(
      '+244923111222',
      PerfilUtilizador.profissional,
      criarConta: true,
    );
    final c = novo(repo);
    expect(c.estado, isA<Carregar<PedidoCodigoSms>>());
    await c.carregar();
    final pedido = (c.estado as Sucesso<PedidoCodigoSms>).dados;
    expect(pedido.telemovel, '+244923111222');
    expect(pedido.perfil, PerfilUtilizador.profissional);
    expect(pedido.criarConta, isTrue);
    expect(c.codigoInicial, '48217');
    expect(c.segundosRestantes, 42);
  });

  test('sem pedido usa o de demonstração (cliente, sem criar conta)', () async {
    final c = novo(MockKisaluRepository());
    await c.carregar();
    final pedido = (c.estado as Sucesso<PedidoCodigoSms>).dados;
    expect(pedido.telemovel, '+244923000000');
    expect(pedido.perfil, PerfilUtilizador.cliente);
    expect(pedido.criarConta, isFalse);
  });

  test('falha de rede ao carregar é Erro', () async {
    final c = novo(_SemRede());
    await c.carregar();
    expect((c.estado as Erro).semRede, isTrue);
  });

  test('código incompleto não chama o repositório e mostra o erro', () async {
    final c = novo(MockKisaluRepository());
    await c.carregar();
    expect(await c.confirmar('48217'), isNull);
    expect(c.erro, 'Falta 1 número. O código tem 6 dígitos.');
    c.aoEscrever();
    expect(c.erro, isNull);
  });

  test(
    'código errado (000000) fica no ecrã com a mensagem do catálogo',
    () async {
      final c = novo(MockKisaluRepository());
      await c.carregar();
      expect(await c.confirmar('000000'), isNull);
      expect(
        c.erro,
        'O código não está certo. Confirme o SMS e tente outra vez.',
      );
      expect(c.aConfirmar, isFalse);
    },
  );

  test('cliente confirma e vai para o Início', () async {
    final repo = MockKisaluRepository();
    final c = novo(repo);
    await c.carregar();
    expect(await c.confirmar('482173'), DestinoCodigoSms.inicio);
    expect(repo.perfilAtivo, PerfilUtilizador.cliente);
  });

  test('profissional que entra (sem criar conta) vai para o Início em modo '
      'profissional', () async {
    final repo = MockKisaluRepository();
    await repo.pedirCodigoSms('+244923000000', PerfilUtilizador.profissional);
    final c = novo(repo);
    await c.carregar();
    expect(await c.confirmar('482 173'), DestinoCodigoSms.inicio);
    expect(repo.perfilAtivo, PerfilUtilizador.profissional);
  });

  test('profissional que cria conta continua no registo', () async {
    final repo = MockKisaluRepository();
    await repo.pedirCodigoSms(
      '+244923000000',
      PerfilUtilizador.profissional,
      criarConta: true,
    );
    final c = novo(repo);
    await c.carregar();
    expect(await c.confirmar('482173'), DestinoCodigoSms.registoProfissional);
  });

  test('a contagem do reenvio desce, chega a zero e o reenvio recomeça', () {
    fakeAsync((async) {
      final repo = MockKisaluRepository();
      final c = CodigoSmsController(repo, segundosReenvio: 3);
      c.carregar();
      async.flushMicrotasks();
      expect(c.segundosRestantes, 3);
      expect(c.podeReenviar, isFalse);
      async.elapse(const Duration(seconds: 2));
      expect(c.segundosRestantes, 1);
      async.elapse(const Duration(seconds: 5));
      expect(c.segundosRestantes, 0);
      expect(c.podeReenviar, isTrue);

      c.reenviar();
      async.flushMicrotasks();
      expect(c.segundosRestantes, 3);
      expect(c.podeReenviar, isFalse);
      c.dispose();
    });
  });

  test('reenviar antes de acabar a contagem não faz nada', () async {
    final c = novo(MockKisaluRepository());
    await c.carregar();
    await c.reenviar();
    expect(c.segundosRestantes, 42);
    expect(c.erro, isNull);
  });

  test('falha ao reenviar mostra o erro', () {
    fakeAsync((async) {
      final repo = _ReenvioFalha();
      final c = CodigoSmsController(repo, segundosReenvio: 1);
      c.carregar();
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 2));
      repo.falhar = true;
      c.reenviar();
      async.flushMicrotasks();
      expect(c.erro, 'Sem ligação. Confirme a sua rede e tente outra vez.');
      expect(c.aReenviar, isFalse);
      c.dispose();
    });
  });
}
