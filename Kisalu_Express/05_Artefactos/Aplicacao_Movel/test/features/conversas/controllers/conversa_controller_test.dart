import 'package:flutter_test/flutter_test.dart';
import 'package:kisalu_express/core/state/estado_ui.dart';
import 'package:kisalu_express/data/repositories/kisalu_repository.dart';
import 'package:kisalu_express/data/repositories/mock_kisalu_repository.dart';
import 'package:kisalu_express/features/conversas/controllers/conversa_controller.dart';
import 'package:kisalu_express/models/conversa.dart';
import 'package:kisalu_express/models/mensagem.dart';

class _EnvioFalha extends MockKisaluRepository {
  @override
  Future<Mensagem> enviarMensagem(String conversaId, String texto) =>
      throw const SemRedeException();
}

void main() {
  ConversaController novo(MockKisaluRepository r, [String id = 'c1']) {
    final c = ConversaController(r, id);
    addTearDown(c.dispose);
    return c;
  }

  Conversa dados(ConversaController c) => (c.estado as Sucesso<Conversa>).dados;

  test('carrega a conversa do Figma', () async {
    final c = novo(MockKisaluRepository());
    expect(c.estado, isA<Carregar<Conversa>>());
    await c.carregar();
    final conversa = dados(c);
    expect(conversa.interlocutor.nome, 'Joaquim Manuel');
    expect(conversa.pedidoTitulo, 'Fuga de água na cozinha');
    expect(conversa.valor, 12500);
    expect(conversa.mensagens.map((m) => m.texto), [
      'Boa tarde. Já tem o sifão para a reparação?',
      'Boa tarde, Maria. Sim, levo o sifão e o vedante.',
      'Chego às 15h40, como combinado.',
    ]);
    expect(conversa.mensagens.map((m) => m.minha), [true, false, false]);
  });

  test('abrir a conversa marca as mensagens como lidas', () async {
    final repo = MockKisaluRepository();
    final c = novo(repo);
    await c.carregar();
    expect((await repo.conversa('c1'))!.naoLidas, 0);
  });

  test('conversa desconhecida é "não encontrada"', () async {
    final c = novo(MockKisaluRepository(), 'zzz');
    await c.carregar();
    expect((c.estado as Erro).naoEncontrado, isTrue);
  });

  test(
    'enviar acrescenta a mensagem em memória, sem espaços à volta',
    () async {
      final c = novo(MockKisaluRepository());
      await c.carregar();
      expect(await c.enviar('  Obrigada, até já!  '), isTrue);
      final ultima = dados(c).mensagens.last;
      expect(ultima.texto, 'Obrigada, até já!');
      expect(ultima.minha, isTrue);
      expect(dados(c).mensagens, hasLength(4));
    },
  );

  test('campo vazio ou só espaços não envia nem dá erro', () async {
    final c = novo(MockKisaluRepository());
    await c.carregar();
    expect(await c.enviar(''), isFalse);
    expect(await c.enviar('    '), isFalse);
    expect(dados(c).mensagens, hasLength(3));
    expect(c.erro, isNull);
  });

  test('mais de 1.000 caracteres não envia e mostra o limite', () async {
    final c = novo(MockKisaluRepository());
    await c.carregar();
    expect(await c.enviar('a' * 1001), isFalse);
    expect(c.erro, 'A mensagem pode ter até 1.000 caracteres.');
    expect(await c.enviar('a' * 1000), isTrue);
    expect(c.erro, isNull);
  });

  test('falha ao enviar fica no ecrã com a mensagem do catálogo', () async {
    final c = novo(_EnvioFalha());
    await c.carregar();
    expect(await c.enviar('Olá'), isFalse);
    expect(c.erro, 'Sem ligação. Confirme a sua rede e tente outra vez.');
    expect(dados(c).mensagens, hasLength(3));
    expect(c.aEnviar, isFalse);
  });
}
