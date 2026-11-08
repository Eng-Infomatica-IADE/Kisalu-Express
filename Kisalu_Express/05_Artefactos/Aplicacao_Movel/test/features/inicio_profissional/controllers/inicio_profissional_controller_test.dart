import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kisalu_express/core/state/estado_ui.dart';
import 'package:kisalu_express/core/utils/k_format.dart';
import 'package:kisalu_express/data/repositories/kisalu_repository.dart';
import 'package:kisalu_express/data/repositories/mock_kisalu_repository.dart';
import 'package:kisalu_express/features/inicio_profissional/controllers/inicio_profissional_controller.dart';
import 'package:kisalu_express/models/painel_profissional.dart';

class _SemRede extends MockKisaluRepository {
  @override
  Future<PainelProfissional> painelProfissional() =>
      throw const SemRedeException();
}

/// Conta as leituras do painel, para ver se o controller volta a ler.
class _ContaLeituras extends MockKisaluRepository {
  int leituras = 0;
  final sinal = ChangeNotifier();

  @override
  Listenable get alteracoes => sinal;

  @override
  Future<PainelProfissional> painelProfissional() {
    leituras++;
    return super.painelProfissional();
  }
}

class _DisponibilidadeFalha extends MockKisaluRepository {
  @override
  Future<void> definirDisponibilidade(bool disponivel) =>
      throw const SemRedeException();
}

void main() {
  InicioProfissionalController novo(MockKisaluRepository r) {
    final c = InicioProfissionalController(r, saudacaoPara: KFormat.saudacao);
    addTearDown(c.dispose);
    return c;
  }

  test('carrega o painel do Figma', () async {
    final c = novo(MockKisaluRepository());
    expect(c.estado, isA<Carregar<InicioProfissionalDados>>());
    await c.carregar();
    final d = (c.estado as Sucesso<InicioProfissionalDados>).dados;
    expect(d.saudacao, 'Boa tarde');
    expect(d.painel.nome, 'Joaquim');
    expect(d.painel.zona, 'Viana');
    expect(d.painel.raioKm, 10);
    expect(d.painel.pedidosNovos, 3);
    expect(d.painel.rating, 4.8);
    expect(d.painel.servicos, 126);
    expect(d.painel.pedidos.map((p) => p.titulo), [
      'Fuga de água na cozinha',
      'Reparar muro do quintal',
    ]);
    expect(c.disponivel, isTrue);
  });

  test('os pedidos só trazem zona e distância, nunca morada', () async {
    final c = novo(MockKisaluRepository());
    await c.carregar();
    final p = (c.estado as Sucesso<InicioProfissionalDados>)
        .dados
        .painel
        .pedidos
        .first;
    expect(p.zona, 'Talatona');
    expect(p.distanciaKm, 3.4);
    expect(p.novo, isTrue);
  });

  test('falha de rede ao carregar é Erro', () async {
    final c = novo(_SemRede());
    await c.carregar();
    expect((c.estado as Erro).semRede, isTrue);
  });

  test('o interruptor muda e fica guardado no repositório', () async {
    final repo = MockKisaluRepository();
    final c = novo(repo);
    await c.carregar();
    await c.mudarDisponibilidade(false);
    expect(c.disponivel, isFalse);
    final outro = novo(repo);
    await outro.carregar();
    expect(outro.disponivel, isFalse);
  });

  test('se o repositório falha, o interruptor volta atrás', () async {
    final c = novo(_DisponibilidadeFalha());
    await c.carregar();
    await c.mudarDisponibilidade(false);
    expect(c.disponivel, isTrue);
  });

  test(
    'volta a ler o painel quando o repositório muda (proposta enviada)',
    () async {
      final r = _ContaLeituras();
      final c = novo(r);
      await c.carregar();
      expect(r.leituras, 1);
      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
      r.sinal.notifyListeners();
      await pumpEventQueue();
      expect(r.leituras, 2);
      expect(c.estado, isA<Sucesso<InicioProfissionalDados>>());
    },
  );
}
