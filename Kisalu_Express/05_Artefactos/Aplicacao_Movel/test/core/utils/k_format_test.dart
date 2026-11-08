import 'package:flutter_test/flutter_test.dart';
import 'package:kisalu_express/core/utils/k_format.dart';
import 'package:kisalu_express/models/proposta.dart';

void main() {
  final agora = DateTime(2026, 10, 20, 15);

  group('valores', () {
    test('kz segue o tom de voz', () {
      expect(KFormat.kz(12500), '12.500 Kz');
      expect(KFormat.kz(6000), '6.000 Kz');
      expect(KFormat.kz(950), '950 Kz');
      expect(KFormat.kz(5000000), '5.000.000 Kz');
      expect(KFormat.kz(0), '0 Kz');
      expect(KFormat.kz(-1500), '-1.500 Kz');
    });

    test('decimal e km usam vírgula', () {
      expect(KFormat.decimal(4.8), '4,8');
      expect(KFormat.km(1.2), '1,2 km');
      expect(KFormat.km(2), '2,0 km');
    });

    test('codigo separa em 3 + 3', () {
      expect(KFormat.codigo('482173'), '482 173');
      expect(KFormat.codigo('123'), '123');
    });

    test('anos, contador e estrelas', () {
      expect(KFormat.anos(6), '6 anos');
      expect(KFormat.anos(1), '1 ano');
      expect(KFormat.contador(36, 300), '36 / 300');
      expect(KFormat.estrelas(4), '4 de 5 estrelas');
      expect(KFormat.estrelas(1), '1 de 5 estrelas');
    });
  });

  group('horas e datas', () {
    test('hora e horaRelogio', () {
      expect(KFormat.hora(DateTime(2026, 10, 20, 15, 40)), '15h40');
      expect(KFormat.hora(DateTime(2026, 10, 20, 9, 5)), '9h05');
      expect(KFormat.horaRelogio(DateTime(2026, 10, 20, 16)), '16:00');
      expect(KFormat.horaRelogio(DateTime(2026, 10, 20, 9, 5)), '09:05');
    });

    test('dataCurta: Hoje, Ontem, "24 set" e com ano', () {
      expect(KFormat.dataCurta(DateTime(2026, 10, 20, 8), agora), 'Hoje');
      expect(KFormat.dataCurta(DateTime(2026, 10, 19, 23), agora), 'Ontem');
      expect(KFormat.dataCurta(DateTime(2026, 9, 24), agora), '24 set');
      expect(KFormat.dataCurta(DateTime(2026, 8, 28), agora), '28 ago');
      expect(KFormat.dataCurta(DateTime(2025, 12, 3), agora), '3 dez 2025');
    });

    test('dataNumerica', () {
      expect(KFormat.dataNumerica(DateTime(2026, 10, 5)), '05/10/2026');
    });

    test('dataHora nos dois estilos', () {
      expect(
        KFormat.dataHora(DateTime(2026, 10, 20, 16), agora),
        'Hoje, 16:00',
      );
      expect(
        KFormat.dataHora(DateTime(2026, 10, 20, 15, 40), agora, relogio: false),
        'Hoje, 15h40',
      );
      expect(
        KFormat.dataHora(DateTime(2026, 10, 21, 9), agora),
        'Amanhã, 09:00',
      );
      expect(
        KFormat.dataHora(DateTime(2026, 10, 25, 9), agora),
        '25 out, 09:00',
      );
    });

    test('quandoPedido: null é o mais cedo possível', () {
      expect(KFormat.quandoPedido(null, agora), 'Hoje, o mais cedo possível');
      expect(
        KFormat.quandoPedido(DateTime(2026, 10, 20, 16), agora),
        'Hoje, 16:00',
      );
    });

    test('chegadaEm', () {
      DateTime em(int min) => agora.add(Duration(minutes: min));
      expect(KFormat.chegadaEm(em(40), agora), 'chega em 40 min');
      expect(KFormat.chegadaEm(em(25), agora), 'chega em 25 min');
      expect(KFormat.chegadaEm(em(60), agora), 'chega em 1 h');
      expect(KFormat.chegadaEm(em(90), agora), 'chega em 1 h 30');
      expect(KFormat.chegadaEm(em(0), agora), 'chega agora');
    });

    test('saudacao muda com a hora', () {
      expect(KFormat.saudacao(DateTime(2026, 1, 1, 6)), 'Bom dia');
      expect(KFormat.saudacao(DateTime(2026, 1, 1, 15)), 'Boa tarde');
      expect(KFormat.saudacao(DateTime(2026, 1, 1, 21)), 'Boa noite');
      expect(KFormat.saudacao(DateTime(2026, 1, 1, 2)), 'Boa noite');
    });
  });

  test('inclui junta componentes e detalha o material', () {
    const todos = [
      ComponenteProposta.maoDeObra,
      ComponenteProposta.material,
      ComponenteProposta.deslocacao,
    ];
    expect(KFormat.inclui(todos), 'mão de obra · material · deslocação');
    expect(
      KFormat.inclui(todos, materialDetalhe: 'sifão e vedante'),
      'mão de obra · material (sifão e vedante) · deslocação',
    );
    expect(
      KFormat.inclui(const [
        ComponenteProposta.maoDeObra,
        ComponenteProposta.deslocacao,
      ]),
      'mão de obra · deslocação',
    );
  });

  group('formatos do Figma v3', () {
    test('telemóvel completo e mascarado', () {
      expect(KFormat.telemovel('+244923000000'), '+244 923 000 000');
      expect(KFormat.telemovelMascarado('+244923000000'), '+244 923 *** 000');
      expect(KFormat.telemovel('923'), '923');
      expect(KFormat.telemovelMascarado('abc'), 'abc');
    });

    test('contagem do reenvio', () {
      expect(KFormat.contagem(42), '0:42');
      expect(KFormat.contagem(5), '0:05');
      expect(KFormat.contagem(60), '1:00');
      expect(KFormat.contagem(0), '0:00');
    });

    test('duração curta', () {
      expect(KFormat.duracaoCurta(const Duration(minutes: 40)), '40 min');
      expect(KFormat.duracaoCurta(const Duration(hours: 1)), '1 h');
      expect(KFormat.duracaoCurta(const Duration(hours: 2)), '2 h');
      expect(KFormat.duracaoCurta(const Duration(minutes: 90)), '1 h 30');
    });

    test('há quanto tempo', () {
      final agora = DateTime(2026, 10, 20, 15);
      expect(
        KFormat.haTempo(agora.subtract(const Duration(minutes: 22)), agora),
        'há 22 min',
      );
      expect(
        KFormat.haTempo(agora.subtract(const Duration(hours: 3)), agora),
        'há 3 h',
      );
      expect(KFormat.haTempo(agora, agora), 'agora mesmo');
      expect(KFormat.haTempo(DateTime(2026, 9, 24, 10), agora), '24 set');
    });

    test('quando na lista de pedidos: hora sem zero à esquerda', () {
      final agora = DateTime(2026, 10, 20, 15);
      expect(
        KFormat.quandoLista(DateTime(2026, 10, 20, 16), agora),
        'Hoje, 16:00',
      );
      expect(
        KFormat.quandoLista(DateTime(2026, 10, 21, 9), agora),
        'Amanhã, 9:00',
      );
      expect(
        KFormat.quandoLista(DateTime(2026, 10, 21, 9, 5), agora),
        'Amanhã, 9:05',
      );
    });

    test('quando na lista de conversas: hora se for hoje, senão a data', () {
      final agora = DateTime(2026, 10, 20, 15);
      expect(
        KFormat.quandoConversa(DateTime(2026, 10, 20, 15, 2), agora),
        '15:02',
      );
      expect(
        KFormat.quandoConversa(DateTime(2026, 9, 24, 11), agora),
        '24 set',
      );
      expect(
        KFormat.quandoConversa(DateTime(2026, 10, 19, 11), agora),
        'Ontem',
      );
    });

    test('moradas e milhares', () {
      expect(KFormat.moradas(2), '2 moradas');
      expect(KFormat.moradas(1), '1 morada');
      expect(KFormat.milhares(12500), '12.500');
      expect(KFormat.milhares(500), '500');
      expect(KFormat.milhares(0), '0');
      expect(KFormat.kz(12500), '12.500 Kz');
    });
  });
}
