import 'package:flutter_test/flutter_test.dart';
import 'package:kisalu_express/core/state/estado_ui.dart';
import 'package:kisalu_express/data/repositories/kisalu_repository.dart';
import 'package:kisalu_express/data/repositories/mock_kisalu_repository.dart';
import 'package:kisalu_express/features/perfil/controllers/perfil_controller.dart';
import 'package:kisalu_express/models/utilizador.dart';

class _SemRede extends MockKisaluRepository {
  @override
  Future<void> terminarSessao() => throw const SemRedeException();
}

class _MudarFalha extends MockKisaluRepository {
  @override
  Future<void> mudarPerfil(PerfilUtilizador perfil) =>
      throw const SemRedeException();
}

class _UtilizadorFalha extends MockKisaluRepository {
  @override
  Future<Utilizador> utilizador() => throw const SemRedeException();
}

void main() {
  PerfilController novo(MockKisaluRepository r) {
    final c = PerfilController(r);
    addTearDown(c.dispose);
    return c;
  }

  test('carrega os dados da Maria no modo cliente', () async {
    final c = novo(MockKisaluRepository());
    expect(c.estado, isA<Carregar<PerfilDados>>());
    await c.carregar();
    final d = (c.estado as Sucesso<PerfilDados>).dados;
    expect(d.utilizador.nomeCompleto, 'Maria Kiala');
    expect(d.utilizador.telemovel, '+244923000000');
    expect(d.utilizador.zona, 'Talatona, Luanda');
    expect(d.utilizador.moradasGuardadas, 2);
    expect(d.utilizador.favoritos, 3);
    expect(d.perfilAtivo, PerfilUtilizador.cliente);
  });

  test('falha de rede ao carregar é Erro', () async {
    final c = novo(_UtilizadorFalha());
    await c.carregar();
    expect((c.estado as Erro).semRede, isTrue);
  });

  test('mudar de perfil alterna cliente e profissional', () async {
    final repo = MockKisaluRepository();
    final c = novo(repo);
    await c.carregar();
    expect(await c.mudarPerfil(), DestinoMudarPerfil.inicio);
    expect(repo.perfilAtivo, PerfilUtilizador.profissional);
    await Future<void>.delayed(Duration.zero);
    final d = (c.estado as Sucesso<PerfilDados>).dados;
    expect(d.perfilAtivo, PerfilUtilizador.profissional);
    expect(d.utilizador.nomeCompleto, 'Joaquim Manuel');

    expect(await c.mudarPerfil(), DestinoMudarPerfil.inicio);
    expect(repo.perfilAtivo, PerfilUtilizador.cliente);
  });

  test('sem registo completo manda para o registo e não muda', () async {
    final repo = MockKisaluRepository(registoProfissionalCompleto: false);
    final c = novo(repo);
    await c.carregar();
    expect(await c.mudarPerfil(), DestinoMudarPerfil.registo);
    expect(repo.perfilAtivo, PerfilUtilizador.cliente);
  });

  test('falha ao mudar de perfil fica com o erro', () async {
    final c = novo(_MudarFalha());
    await c.carregar();
    expect(await c.mudarPerfil(), DestinoMudarPerfil.nenhum);
    expect(c.erro, 'Sem ligação. Confirme a sua rede e tente outra vez.');
    expect(c.aMudar, isFalse);
  });

  test('terminar sessão devolve true', () async {
    final c = novo(MockKisaluRepository());
    expect(await c.terminarSessao(), isTrue);
    expect(c.aTerminar, isFalse);
    expect(c.erro, isNull);
  });

  test('falha ao terminar guarda a mensagem e devolve false', () async {
    final c = novo(_SemRede());
    expect(await c.terminarSessao(), isFalse);
    expect(c.erro, 'Sem ligação. Confirme a sua rede e tente outra vez.');
  });
}
