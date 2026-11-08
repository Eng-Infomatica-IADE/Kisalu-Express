import 'package:flutter_test/flutter_test.dart';
import 'package:kisalu_express/core/state/estado_ui.dart';
import 'package:kisalu_express/data/repositories/kisalu_repository.dart';
import 'package:kisalu_express/data/repositories/mock_kisalu_repository.dart';
import 'package:kisalu_express/features/autenticacao/controllers/login_controller.dart';
import 'package:kisalu_express/models/utilizador.dart';

class _SemRede extends MockKisaluRepository {
  @override
  Future<void> pedirCodigoSms(
    String telemovel,
    PerfilUtilizador perfil, {
    bool criarConta = false,
  }) => throw const SemRedeException();
}

class _SemPredefinido extends MockKisaluRepository {
  @override
  Future<String?> telemovelPredefinido() async => null;
}

void main() {
  test('carrega o telemóvel predefinido (Sucesso)', () async {
    final c = LoginController(MockKisaluRepository());
    expect(c.estado, isA<Carregar<String>>());
    await c.carregar();
    expect((c.estado as Sucesso<String>).dados, '+244 923 000 000');
  });

  test('sem predefinido o estado é Vazio', () async {
    final c = LoginController(_SemPredefinido());
    await c.carregar();
    expect(c.estado, isA<Vazio<String>>());
  });

  test('perfil alterna entre cliente e profissional', () {
    final c = LoginController(MockKisaluRepository());
    expect(c.perfil, PerfilUtilizador.cliente);
    c.mudarPerfil(PerfilUtilizador.profissional);
    expect(c.perfil, PerfilUtilizador.profissional);
  });

  test('submeter com número curto não avança e mostra o erro', () async {
    final c = LoginController(MockKisaluRepository());
    expect(await c.submeter('+244 923 45'), isFalse);
    expect(
      c.erroTelefone,
      'Faltam 4 números. Um número angolano tem 9 dígitos.',
    );
    c.aoEscrever();
    expect(c.erroTelefone, isNull);
  });

  test(
    'submeter vazio pede o número; sair do campo vazio não é erro',
    () async {
      final c = LoginController(MockKisaluRepository());
      c.validarAoSair('  ');
      expect(c.erroTelefone, isNull);
      expect(await c.submeter(''), isFalse);
      expect(c.erroTelefone, 'Escreva o seu número de telemóvel.');
    },
  );

  test('validarAoSair valida depois de sair do campo', () {
    final c = LoginController(MockKisaluRepository());
    c.validarAoSair('823 456 789');
    expect(c.erroTelefone, 'O número começa por 9. Exemplo: 923 456 789.');
  });

  test('submeter válido avança', () async {
    final c = LoginController(MockKisaluRepository());
    expect(await c.submeter('+244 923 000 000'), isTrue);
    expect(c.erroTelefone, isNull);
    expect(c.aEnviar, isFalse);
  });

  test('falha de rede fica como erro do campo e não avança', () async {
    final c = LoginController(_SemRede());
    expect(await c.submeter('923 456 789'), isFalse);
    expect(
      c.erroTelefone,
      'Sem ligação. Confirme a sua rede e tente outra vez.',
    );
  });
}
