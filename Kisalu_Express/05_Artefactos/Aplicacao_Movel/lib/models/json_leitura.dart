/// Leitura defensiva dos campos que vêm da kisalu-api (CONTRATO-API.md, 0).
/// Usado só pelos construtores `fromJson` dos modelos.
abstract final class JsonLeitura {
  /// Os ids são `int` no servidor e `String` na app.
  static String id(Object? v) => v?.toString() ?? '';

  static String? idOuNull(Object? v) => v?.toString();

  static String texto(Object? v) => v is String ? v : (v?.toString() ?? '');

  static String? textoOuNull(Object? v) => v?.toString();

  /// O mysql2 pode devolver 0/1 em vez de true/false.
  static bool booleano(Object? v) => v == true || v == 1;

  /// Kz e contagens: inteiros. null → 0.
  static int inteiro(Object? v) => v is num ? v.round() : 0;

  static int? inteiroOuNull(Object? v) => v is num ? v.round() : null;

  static double decimal(Object? v) => v is num ? v.toDouble() : 0;

  /// ISO 8601 em UTC → hora local.
  static DateTime data(Object? v) => dataOuNull(v) ?? DateTime.now();

  static DateTime? dataOuNull(Object? v) =>
      v is String ? DateTime.tryParse(v)?.toLocal() : null;

  static Map<String, dynamic> mapa(Object? v) =>
      v is Map ? v.cast<String, dynamic>() : const {};

  static Map<String, dynamic>? mapaOuNull(Object? v) =>
      v is Map ? v.cast<String, dynamic>() : null;

  static List<T> lista<T>(Object? v, T Function(Map<String, dynamic>) ler) => [
    if (v is List)
      for (final e in v)
        if (e is Map) ler(e.cast<String, dynamic>()),
  ];

  static List<String> textos(Object? v) => [
    if (v is List)
      for (final e in v)
        if (e != null) e.toString(),
  ];

  /// "Maria Kiala" → "Maria".
  static String primeiroNome(String nome) =>
      nome.trim().split(RegExp(r'\s+')).first;
}
