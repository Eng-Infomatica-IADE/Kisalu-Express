import 'package:flutter_test/flutter_test.dart';
import 'package:kisalu_express/core/state/estado_ui.dart';
import 'package:kisalu_express/data/repositories/kisalu_repository.dart';
import 'package:kisalu_express/data/repositories/mock_kisalu_repository.dart';
import 'package:kisalu_express/features/conversas/controllers/conversas_controller.dart';
import 'package:kisalu_express/models/conversa.dart';

class _SemRede extends MockKisaluRepository {
  @override
  Future<List<Conversa>> conversas() => throw const SemRedeException();
}

class _SemConversas extends MockKisaluRepository {
  @override
  Future<List<Conversa>> conversas() async => [];
}

void main() {
  ConversasController novo(MockKisaluRepository r) {
    final c = ConversasController(r);
    addTearDown(c.dispose);
    return c;
  }

  test('carrega as 3 conversas do Figma, a mais recente primeiro', () async {
    final c = novo(MockKisaluRepository());
    expect(c.estado, isA<Carregar<ConversasDados>>());
    await c.carregar();
    final d = (c.estado as Sucesso<ConversasDados>).dados;
    expect(d.conversas.map((x) => x.interlocutor.nome), [
      'Joaquim Manuel',
      'Carlos Dias',
      'Nuno Ferreira',
    ]);
    expect(d.conversas.first.ultima!.texto, 'Chego às 15h40, como combinado.');
    expect(d.conversas.first.naoLidas, 2);
  });

  test('sem conversas o estado é Vazio', () async {
    final c = novo(_SemConversas());
    await c.carregar();
    expect(c.estado, isA<Vazio<ConversasDados>>());
  });

  test('falha de rede é Erro', () async {
    final c = novo(_SemRede());
    await c.carregar();
    expect((c.estado as Erro).semRede, isTrue);
  });

  test(
    'relê quando o repositório avisa (mensagem enviada, conversa lida)',
    () async {
      final repo = MockKisaluRepository();
      final c = novo(repo);
      await c.carregar();
      await repo.marcarConversaLida('c1');
      await Future<void>.delayed(Duration.zero);
      final d = (c.estado as Sucesso<ConversasDados>).dados;
      expect(d.conversas.first.naoLidas, 0);

      await repo.enviarMensagem('c3', 'Obrigada!');
      await Future<void>.delayed(Duration.zero);
      final depois = (c.estado as Sucesso<ConversasDados>).dados;
      expect(depois.conversas.map((x) => x.id), ['c1', 'c3', 'c2']);
      expect(depois.conversas[1].ultima!.texto, 'Obrigada!');
    },
  );
}
