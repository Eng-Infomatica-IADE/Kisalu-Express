import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kisalu_express/features/profissional/widgets/avaliacoes_em_numeros.dart';
import 'package:kisalu_express/models/estatisticas_avaliacoes.dart';

import '../../../helpers/montar_widget.dart';

// Valores do Joaquim devolvidos pela API (dados fictícios).
final _joaquim = EstatisticasAvaliacoes.fromJson({
  'n': 126,
  'media': 4.79,
  'mediana': 5,
  'moda': 5,
  'desvio_padrao': 0.6,
  'variancia': 0.357,
  'ic95': {'inferior': 4.69, 'superior': 4.9, 'metodo': 'z'},
  'distribuicao': {'1': 1, '2': 1, '3': 3, '4': 13, '5': 108},
  'media_bayesiana': 4.79,
});

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('mostra média ± desvio, intervalo, barras e n', (t) async {
    await t.pumpWidget(
      montarWidget(AvaliacoesEmNumeros(estatisticas: _joaquim), rolavel: true),
    );
    expect(find.text('Avaliações em números'), findsOneWidget);
    expect(find.text('4,8 ± 0,6'), findsOneWidget);
    expect(find.text('média ± desvio padrão'), findsOneWidget);
    expect(find.text('Entre 4,7 e 4,9 com 95% de confiança'), findsOneWidget);
    expect(find.text('108'), findsOneWidget);
    expect(find.text('13'), findsOneWidget);
    expect(find.text('n = 126 avaliações'), findsOneWidget);
  });

  testWidgets('as barras leem-se como texto no leitor de ecrã', (t) async {
    final s = t.ensureSemantics();
    await t.pumpWidget(
      montarWidget(AvaliacoesEmNumeros(estatisticas: _joaquim), rolavel: true),
    );
    expect(find.bySemanticsLabel('5 estrelas: 108 avaliações'), findsOneWidget);
    expect(find.bySemanticsLabel('1 estrela: 1 avaliação'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Média de 4,8 estrelas, desvio padrão 0,6'),
      findsOneWidget,
    );
    s.dispose();
  });

  testWidgets('sem overflow com texto a 200 %', (t) async {
    await t.pumpWidget(
      montarWidget(
        AvaliacoesEmNumeros(estatisticas: _joaquim),
        rolavel: true,
        escalaTexto: 2,
      ),
    );
    expect(t.takeException(), isNull);
  });

  testWidgets('com uma só avaliação não mostra desvio nem intervalo', (
    t,
  ) async {
    final uma = EstatisticasAvaliacoes.fromJson({
      'n': 1,
      'media': 5,
      'mediana': 5,
      'moda': 5,
      'desvio_padrao': null,
      'variancia': null,
      'ic95': null,
      'distribuicao': {'1': 0, '2': 0, '3': 0, '4': 0, '5': 1},
      'media_bayesiana': 4.8,
    });
    await t.pumpWidget(
      montarWidget(AvaliacoesEmNumeros(estatisticas: uma), rolavel: true),
    );
    expect(find.text('5,0'), findsOneWidget);
    expect(find.textContaining('confiança'), findsNothing);
    expect(find.text('n = 1 avaliação'), findsOneWidget);
  });
}
