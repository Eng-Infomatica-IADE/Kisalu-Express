import 'json_leitura.dart';
import 'profissional.dart';

/// Profissional posicionado no mapa estático (ecrã 22). [x] e [y] são
/// frações (0 a 1) da largura e da altura do mapa: a ponta do pin fica aí.
class PinMapa {
  const PinMapa({required this.profissional, required this.x, required this.y});

  /// `{x, y, profissional}`.
  factory PinMapa.fromJson(Map<String, dynamic> j) => PinMapa(
    profissional: Profissional.fromJson(JsonLeitura.mapa(j['profissional'])),
    x: JsonLeitura.decimal(j['x']),
    y: JsonLeitura.decimal(j['y']),
  );

  final Profissional profissional;
  final double x;
  final double y;
}
