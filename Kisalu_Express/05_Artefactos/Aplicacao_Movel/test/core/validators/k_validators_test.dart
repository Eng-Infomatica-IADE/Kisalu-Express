import 'package:flutter_test/flutter_test.dart';
import 'package:kisalu_express/core/validators/k_validators.dart';

String texto(int n) => List.filled(n, 'a').join();

void main() {
  final agora = DateTime(2026, 10, 20, 15);

  group('telemovel', () {
    test('formatos válidos', () {
      for (final v in [
        '923456789',
        '923 456 789',
        '+244 923 456 789',
        '00244923456789',
        '244923456789',
        '  923456789  ',
      ]) {
        expect(KValidators.telemovel(v), isNull, reason: v);
      }
    });

    test('mensagens exatas', () {
      expect(KValidators.telemovel(null), 'Escreva o seu número de telemóvel.');
      expect(KValidators.telemovel('  '), 'Escreva o seu número de telemóvel.');
      expect(
        KValidators.telemovel('92345'),
        'Faltam 4 números. Um número angolano tem 9 dígitos.',
      );
      expect(
        KValidators.telemovel('92345678'),
        'Falta 1 número. Um número angolano tem 9 dígitos.',
      );
      expect(
        KValidators.telemovel('9234567890'),
        'Tem 1 número a mais. Um número angolano tem 9 dígitos.',
      );
      expect(
        KValidators.telemovel('92345678901'),
        'Tem 2 números a mais. Um número angolano tem 9 dígitos.',
      );
      expect(
        KValidators.telemovel('823456789'),
        'O número começa por 9. Exemplo: 923 456 789.',
      );
      expect(
        KValidators.telemovel('92a456789'),
        'Use só números. Exemplo: 923 456 789.',
      );
    });

    test('normalizarTelemovel', () {
      expect(KValidators.normalizarTelemovel('923 456 789'), '+244923456789');
      expect(
        KValidators.normalizarTelemovel('+244 923 456 789'),
        '+244923456789',
      );
      expect(KValidators.normalizarTelemovel('823456789'), isNull);
      expect(KValidators.normalizarTelemovel(null), isNull);
    });
  });

  group('codigoSms', () {
    test('válido e inválidos', () {
      expect(KValidators.codigoSms('482173'), isNull);
      expect(
        KValidators.codigoSms(''),
        'Escreva o código que recebeu por SMS.',
      );
      expect(
        KValidators.codigoSms('48217'),
        'Falta 1 número. O código tem 6 dígitos.',
      );
      expect(
        KValidators.codigoSms('4821'),
        'Faltam 2 números. O código tem 6 dígitos.',
      );
      expect(KValidators.codigoSms('4821735'), 'O código tem 6 dígitos.');
    });
  });

  group('codigoConfirmacao', () {
    test('válido com e sem espaço', () {
      expect(KValidators.codigoConfirmacao('482 173'), isNull);
      expect(KValidators.codigoConfirmacao('482173'), isNull);
    });

    test('mensagens exatas', () {
      expect(
        KValidators.codigoConfirmacao(null),
        'Escreva o código que o cliente lhe disse.',
      );
      expect(
        KValidators.codigoConfirmacao('48 217'),
        'Falta 1 número. O código tem 6 dígitos.',
      );
      expect(
        KValidators.codigoConfirmacao('4821'),
        'Faltam 2 números. O código tem 6 dígitos.',
      );
      expect(
        KValidators.codigoConfirmacao('4821735'),
        'O código tem 6 dígitos. Confirme com o cliente.',
      );
      expect(
        KValidators.codigoConfirmacao('48a173'),
        'Use só números. Exemplo: 482 173.',
      );
    });

    test('normalizarCodigo', () {
      expect(KValidators.normalizarCodigo('482 173'), '482173');
      expect(KValidators.normalizarCodigo('48 217'), isNull);
    });
  });

  group('descricaoPedido', () {
    test('limites', () {
      expect(KValidators.descricaoPedido(texto(10)), isNull);
      expect(KValidators.descricaoPedido(texto(300)), isNull);
      expect(
        KValidators.descricaoPedido(''),
        'Descreva o problema para receber propostas certas.',
      );
      expect(
        KValidators.descricaoPedido('          '),
        'Descreva o problema para receber propostas certas.',
      );
      expect(
        KValidators.descricaoPedido(texto(9)),
        'Escreva um pouco mais. Exemplo: Cano a pingar debaixo do lava-loiça.',
      );
      expect(
        KValidators.descricaoPedido(texto(301)),
        'A descrição pode ter até 300 caracteres.',
      );
    });
  });

  group('pontoReferencia', () {
    test('limites', () {
      expect(KValidators.pontoReferencia(texto(5)), isNull);
      expect(KValidators.pontoReferencia(texto(120)), isNull);
      expect(KValidators.pontoReferencia('', obrigatorio: false), isNull);
      expect(
        KValidators.pontoReferencia(''),
        'Diga-nos um ponto de referência perto de si.',
      );
      expect(
        KValidators.pontoReferencia(texto(4)),
        'Dê um pouco mais de detalhe. Exemplo: Perto da cantina do Sr. Zé.',
      );
      expect(
        KValidators.pontoReferencia(texto(121)),
        'O ponto de referência pode ter até 120 caracteres.',
      );
    });
  });

  group('dataPedido', () {
    test('válidas', () {
      expect(KValidators.dataPedido(agora, agora: agora), isNull);
      expect(
        KValidators.dataPedido(
          agora.add(const Duration(days: 30)),
          agora: agora,
        ),
        isNull,
      );
      expect(KValidators.dataPedido(null, agora: agora, semData: true), isNull);
      // Só o dia de hoje (sem hora) não conta como hora passada.
      expect(
        KValidators.dataPedido(DateTime(2026, 10, 20), agora: agora),
        isNull,
      );
    });

    test('inválidas', () {
      expect(
        KValidators.dataPedido(
          agora.subtract(const Duration(days: 1)),
          agora: agora,
        ),
        'Escolha uma data a partir de hoje.',
      );
      expect(
        KValidators.dataPedido(
          agora.add(const Duration(days: 31)),
          agora: agora,
        ),
        'Escolha uma data nos próximos 30 dias.',
      );
      expect(
        KValidators.dataPedido(null, agora: agora),
        'Escolha quando precisa do serviço.',
      );
      expect(
        KValidators.dataPedido(DateTime(2026, 10, 20, 9), agora: agora),
        'Essa hora já passou. Escolha outra.',
      );
    });
  });

  group('valorKz', () {
    test('válidos', () {
      for (final v in ['500', '12500', '12.500', '12.500 Kz', '5.000.000']) {
        expect(KValidators.valorKz(v), isNull, reason: v);
      }
    });

    test('mensagens exatas', () {
      expect(KValidators.valorKz(''), 'Escreva o valor da proposta.');
      expect(KValidators.valorKz('499'), 'O valor mínimo é 500 Kz.');
      expect(
        KValidators.valorKz('5000001'),
        'O valor máximo é 5.000.000 Kz. Confirme o que escreveu.',
      );
      expect(
        KValidators.valorKz('12,50'),
        'Escreva o valor sem cêntimos. Exemplo: 12.500 Kz.',
      );
      expect(
        KValidators.valorKz('12.50'),
        'Escreva o valor sem cêntimos. Exemplo: 12.500 Kz.',
      );
      expect(KValidators.valorKz('abc'), 'Use só números. Exemplo: 12.500 Kz.');
      expect(
        KValidators.valorKz('-500'),
        'Use só números. Exemplo: 12.500 Kz.',
      );
    });

    test('limites configuráveis', () {
      expect(KValidators.valorKz('1000', minimo: 2000), isNotNull);
    });

    test('kzParaInteiro', () {
      expect(KValidators.kzParaInteiro('12.500 Kz'), 12500);
      expect(KValidators.kzParaInteiro('12500'), 12500);
      expect(KValidators.kzParaInteiro('12,50'), isNull);
      expect(KValidators.kzParaInteiro('12.50'), isNull);
      expect(KValidators.kzParaInteiro(null), isNull);
    });
  });

  test('comentario: opcional até 300', () {
    expect(KValidators.comentario(''), isNull);
    expect(KValidators.comentario(null), isNull);
    expect(KValidators.comentario(texto(300)), isNull);
    expect(
      KValidators.comentario(texto(301)),
      'O comentário pode ter até 300 caracteres.',
    );
  });

  test('estrelas: 1 a 5', () {
    for (final n in [1, 2, 3, 4, 5]) {
      expect(KValidators.estrelas(n), isNull);
    }
    for (final n in [null, 0, 6]) {
      expect(KValidators.estrelas(n), 'Escolha de 1 a 5 estrelas.');
    }
  });

  test('reporteProblema: 10 a 500', () {
    expect(KValidators.reporteProblema(texto(10)), isNull);
    expect(KValidators.reporteProblema(texto(500)), isNull);
    expect(KValidators.reporteProblema(''), 'Conte-nos o que aconteceu.');
    expect(
      KValidators.reporteProblema(texto(9)),
      'Escreva um pouco mais para percebermos o problema.',
    );
    expect(
      KValidators.reporteProblema(texto(501)),
      'A descrição pode ter até 500 caracteres.',
    );
  });

  group('registo do profissional', () {
    test('nome completo: 2 a 60 caracteres', () {
      expect(KValidators.nomeCompleto('Joaquim Manuel'), isNull);
      expect(KValidators.nomeCompleto(''), 'Escreva o seu nome.');
      expect(KValidators.nomeCompleto('   '), 'Escreva o seu nome.');
      expect(KValidators.nomeCompleto('J'), 'Escreva o seu nome completo.');
      expect(KValidators.nomeCompleto('a' * 60), isNull);
      expect(
        KValidators.nomeCompleto('a' * 61),
        'O nome pode ter até 60 caracteres.',
      );
    });

    test('serviços: pelo menos um', () {
      expect(KValidators.servicosPrestados(['pintor']), isNull);
      expect(
        KValidators.servicosPrestados([]),
        'Escolha pelo menos um serviço.',
      );
    });

    test('anos de experiência: inteiro de 0 a 60', () {
      expect(KValidators.anosExperiencia('0'), isNull);
      expect(KValidators.anosExperiencia('10'), isNull);
      expect(KValidators.anosExperiencia('60'), isNull);
      expect(
        KValidators.anosExperiencia(''),
        'Escreva os seus anos de experiência.',
      );
      expect(
        KValidators.anosExperiencia('dez'),
        'Use só números. Exemplo: 10.',
      );
      expect(
        KValidators.anosExperiencia('61'),
        'Escreva um valor até 60 anos.',
      );
    });

    test('zona de atuação: obrigatória, até 60 caracteres', () {
      expect(KValidators.zonaAtuacao('Viana, Luanda'), isNull);
      expect(KValidators.zonaAtuacao(' '), 'Diga-nos a sua zona de atuação.');
      expect(
        KValidators.zonaAtuacao('a' * 61),
        'A zona pode ter até 60 caracteres.',
      );
    });
  });

  group('proposta e conversa', () {
    test('componente em Kz: de 0 ao máximo, com ou sem formatação', () {
      expect(KValidators.componenteKz('0', nome: 'material'), isNull);
      expect(KValidators.componenteKz('8000', nome: 'material'), isNull);
      expect(KValidators.componenteKz('8.000 Kz', nome: 'material'), isNull);
      expect(
        KValidators.componenteKz('', nome: 'material'),
        'Escreva o valor de material. Se não cobra, escreva 0.',
      );
      expect(
        KValidators.componenteKz('abc', nome: 'material'),
        'Use só números. Exemplo: 12.500 Kz.',
      );
      expect(
        KValidators.componenteKz('1,5', nome: 'material'),
        'Escreva o valor sem cêntimos. Exemplo: 12.500 Kz.',
      );
      expect(
        KValidators.componenteKz('5000001', nome: 'material'),
        'O valor máximo é 5.000.000 Kz. Confirme o que escreveu.',
      );
    });

    test('mensagem de conversa: só passa do limite de 1.000', () {
      expect(KValidators.mensagemChat(''), isNull);
      expect(KValidators.mensagemChat('Olá'), isNull);
      expect(KValidators.mensagemChat('a' * 1000), isNull);
      expect(
        KValidators.mensagemChat('a' * 1001),
        'A mensagem pode ter até 1.000 caracteres.',
      );
    });
  });
}
