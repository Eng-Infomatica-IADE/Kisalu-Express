import '../../models/pin_mapa.dart';
import 'mock_profissionais.dart';

/// Posições fictícias no mapa estático (ecrã 22), em frações do mapa.
abstract final class MockMapa {
  static const pins = <PinMapa>[
    PinMapa(profissional: MockProfissionais.joaquim, x: .345, y: .35),
    PinMapa(profissional: MockProfissionais.ana, x: .77, y: .265),
    PinMapa(profissional: MockProfissionais.rui, x: .668, y: .43),
    PinMapa(profissional: MockProfissionais.paulo, x: .21, y: .54),
  ];
}
