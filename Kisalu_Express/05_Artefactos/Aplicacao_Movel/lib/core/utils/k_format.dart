import '../../models/proposta.dart';

/// Formatação de valores segundo o tom de voz (Style Guide, cap. 08):
/// "12.500 Kz" · "15h40" · "1,2 km" · "4,8" · "Hoje" · "24 set".
///
/// Funções puras: o relógio entra sempre como [agora] (o do repositório).
abstract final class KFormat {
  static const _meses = [
    'jan',
    'fev',
    'mar',
    'abr',
    'mai',
    'jun',
    'jul',
    'ago',
    'set',
    'out',
    'nov',
    'dez',
  ];

  static String _dois(int n) => n.toString().padLeft(2, '0');

  static bool _mesmoDia(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static DateTime _dia(DateTime d) => DateTime(d.year, d.month, d.day);

  /// 12500 → "12.500" (ponto de milhares, sem moeda).
  static String milhares(int valor) {
    final digitos = valor.abs().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digitos.length; i++) {
      if (i > 0 && (digitos.length - i) % 3 == 0) buffer.write('.');
      buffer.write(digitos[i]);
    }
    return '${valor < 0 ? '-' : ''}$buffer';
  }

  /// 12500 → "12.500 Kz" (ponto de milhares, espaço antes de Kz).
  static String kz(int valor) => '${milhares(valor)} Kz';

  /// 4.8 → "4,8"
  static String decimal(double valor, {int casas = 1}) =>
      valor.toStringAsFixed(casas).replaceAll('.', ',');

  /// 1.2 → "1,2 km"
  static String km(double valor) => '${decimal(valor)} km';

  /// 15:40 → "15h40" (folha de confirmação, spec do ecrã 08).
  static String hora(DateTime t) => '${t.hour}h${_dois(t.minute)}';

  /// 16:00 → "16:00" (cartão do pedido, spec do ecrã 04).
  static String horaRelogio(DateTime t) =>
      '${_dois(t.hour)}:${_dois(t.minute)}';

  /// "+244923000000" → "+244 923 000 000" (só para números normalizados).
  static String telemovel(String normalizado) {
    final m = RegExp(r'^\+244(\d{3})(\d{3})(\d{3})$').firstMatch(normalizado);
    return m == null ? normalizado : '+244 ${m[1]} ${m[2]} ${m[3]}';
  }

  /// "+244923000000" → "+244 923 *** 000": esconde os 3 dígitos do meio.
  static String telemovelMascarado(String normalizado) {
    final m = RegExp(r'^\+244(\d{3})(\d{3})(\d{3})$').firstMatch(normalizado);
    return m == null ? normalizado : '+244 ${m[1]} *** ${m[3]}';
  }

  /// Contagem decrescente do reenvio: 42 → "0:42".
  static String contagem(int segundos) =>
      '${segundos ~/ 60}:${_dois(segundos % 60)}';

  /// 40 min → "40 min"; 1 h → "1 h"; 90 min → "1 h 30".
  static String duracaoCurta(Duration d) {
    final minutos = d.inMinutes;
    if (minutos < 60) return '$minutos min';
    final h = minutos ~/ 60;
    final m = minutos % 60;
    return m == 0 ? '$h h' : '$h h $m';
  }

  /// "há 22 min" · "há 3 h" · "24 set" (a partir de um dia).
  static String haTempo(DateTime momento, DateTime agora) {
    final minutos = agora.difference(momento).inMinutes;
    if (minutos < 1) return 'agora mesmo';
    if (minutos < 60) return 'há $minutos min';
    if (minutos < 24 * 60) return 'há ${minutos ~/ 60} h';
    return dataCurta(momento, agora);
  }

  /// Pedidos perto do profissional (14): "Hoje, 16:00" · "Amanhã, 9:00".
  /// A hora não leva zero à esquerda, como no Figma. null → "O mais cedo
  /// possível".
  static String quandoLista(DateTime? quando, DateTime agora) => quando == null
      ? 'O mais cedo possível'
      : '${diaRelativo(quando, agora)}, ${quando.hour}:${_dois(quando.minute)}';

  /// Lista de conversas (18): a hora se for hoje, senão "24 set".
  static String quandoConversa(DateTime momento, DateTime agora) =>
      _mesmoDia(momento, agora)
      ? horaRelogio(momento)
      : dataCurta(momento, agora);

  /// 2 → "2 moradas"; 1 → "1 morada".
  static String moradas(int n) => n == 1 ? '1 morada' : '$n moradas';

  /// "482173" → "482 173"
  static String codigo(String codigo) => codigo.length == 6
      ? '${codigo.substring(0, 3)} ${codigo.substring(3)}'
      : codigo;

  /// Dia relativo: "Hoje", "Ontem" ou "24 set" (com ano se não for o atual).
  static String dataCurta(DateTime data, DateTime agora) {
    if (_mesmoDia(data, agora)) return 'Hoje';
    if (_mesmoDia(data, _dia(agora).subtract(const Duration(days: 1)))) {
      return 'Ontem';
    }
    final base = '${data.day} ${_meses[data.month - 1]}';
    return data.year == agora.year ? base : '$base ${data.year}';
  }

  /// "Hoje", "Amanhã" ou "24 set" — para datas futuras.
  static String diaRelativo(DateTime data, DateTime agora) {
    if (_mesmoDia(data, _dia(agora).add(const Duration(days: 1)))) {
      return 'Amanhã';
    }
    return dataCurta(data, agora);
  }

  /// "20/10/2026"
  static String dataNumerica(DateTime d) =>
      '${_dois(d.day)}/${_dois(d.month)}/${d.year}';

  /// "Hoje, 16:00" ([relogio] true) ou "Hoje, 15h40" (false).
  static String dataHora(
    DateTime quando,
    DateTime agora, {
    bool relogio = true,
  }) =>
      '${diaRelativo(quando, agora)}, '
      '${relogio ? horaRelogio(quando) : hora(quando)}';

  /// Pedido: null → "Hoje, o mais cedo possível".
  static String quandoPedido(DateTime? quando, DateTime agora) =>
      quando == null ? 'Hoje, o mais cedo possível' : dataHora(quando, agora);

  /// "chega em 40 min" · "chega em 1 h" · "chega em 1 h 30" · "chega agora".
  static String chegadaEm(DateTime chegada, DateTime agora) {
    final minutos = chegada.difference(agora).inMinutes;
    if (minutos <= 0) return 'chega agora';
    if (minutos < 60) return 'chega em $minutos min';
    final h = minutos ~/ 60;
    final m = minutos % 60;
    return m == 0 ? 'chega em $h h' : 'chega em $h h $m';
  }

  /// Saudação do Início: Bom dia (5–11 h) · Boa tarde (12–19 h) · Boa noite.
  static String saudacao(DateTime agora) {
    final h = agora.hour;
    if (h >= 5 && h < 12) return 'Bom dia';
    if (h >= 12 && h < 20) return 'Boa tarde';
    return 'Boa noite';
  }

  /// 6 → "6 anos"; 1 → "1 ano".
  static String anos(int n) => n == 1 ? '1 ano' : '$n anos';

  /// Contador dos campos de texto: "36 / 300".
  static String contador(int atual, int maximo) => '$atual / $maximo';

  /// Semântica das estrelas: "4 de 5 estrelas".
  static String estrelas(int n) => '$n de 5 estrelas';

  /// ["mão de obra", "material", "deslocação"] → "mão de obra · material ·
  /// deslocação"; com [materialDetalhe]: "material (sifão e vedante)".
  static String inclui(
    List<ComponenteProposta> componentes, {
    String? materialDetalhe,
  }) => componentes
      .map(
        (c) => c == ComponenteProposta.material && materialDetalhe != null
            ? '${c.rotulo} ($materialDetalhe)'
            : c.rotulo,
      )
      .join(' · ');
}
