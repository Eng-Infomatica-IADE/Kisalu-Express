import 'package:flutter_test/flutter_test.dart';
import 'package:kisalu_express/core/state/estado_ui.dart';

String descrever(EstadoUi<List<int>> e) => switch (e) {
  Carregar() => 'a carregar',
  Sucesso(:final dados) => 'sucesso ${dados.length}',
  Vazio() => 'vazio',
  Erro(:final mensagem, :final semRede) => 'erro $mensagem $semRede',
};

void main() {
  test('o switch cobre os quatro estados', () {
    expect(descrever(const Carregar()), 'a carregar');
    expect(descrever(const Sucesso([1, 2])), 'sucesso 2');
    expect(descrever(const Vazio()), 'vazio');
    expect(descrever(const Erro('x', semRede: true)), 'erro x true');
  });

  test('Erro tem semRede e naoEncontrado falsos por omissão', () {
    const e = Erro<int>('x');
    expect(e.semRede, isFalse);
    expect(e.naoEncontrado, isFalse);
  });
}
