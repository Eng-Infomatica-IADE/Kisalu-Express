import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kisalu_express/core/state/estado_ui.dart';
import 'package:kisalu_express/data/repositories/mock_kisalu_repository.dart';
import 'package:kisalu_express/features/trabalho/controllers/trabalho_detalhe_controller.dart';
import 'package:kisalu_express/features/trabalho/views/trabalho_detalhe_view.dart';
import 'package:kisalu_express/models/estado_pedido.dart';
import 'package:kisalu_express/models/pedido.dart';
import 'package:kisalu_express/models/utilizador.dart';

import '../../helpers/ecra_apoio.dart';

Future<MockKisaluRepository> _profissional() async {
  final repo = MockKisaluRepository();
  await repo.mudarPerfil(PerfilUtilizador.profissional);
  return repo;
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('TrabalhoDetalheController', () {
    test('carrega o trabalho e avança as etapas', () async {
      final repo = await _profissional();
      final c = TrabalhoDetalheController(repo, 'tp1');
      await c.carregar();
      expect((c.estado as Sucesso<Pedido>).dados.morada, isNotNull);
      expect(c.podeIrACaminho, isTrue);
      expect(c.podeComecar, isTrue);

      expect(await c.mudarEtapa(EtapaServico.aCaminho), isTrue);
      expect(c.podeIrACaminho, isFalse);
      expect(c.podeComecar, isTrue);

      expect(await c.mudarEtapa(EtapaServico.emCurso), isTrue);
      expect(c.podeComecar, isFalse);
      expect(c.faltaConfirmar, isTrue);

      expect(await c.mudarEtapa(EtapaServico.aCaminho), isFalse);
      expect(c.erro, isNotNull);
      c.dispose();
    });

    test('trabalho concluído não tem ações', () async {
      final c = TrabalhoDetalheController(await _profissional(), 'tp2');
      await c.carregar();
      expect(c.ativo, isFalse);
      c.dispose();
    });

    test('id desconhecido → não encontrado', () async {
      final c = TrabalhoDetalheController(await _profissional(), 'zzz');
      await c.carregar();
      expect((c.estado as Erro<Pedido>).naoEncontrado, isTrue);
      c.dispose();
    });
  });

  group('TrabalhoDetalheView', () {
    testWidgets('mostra morada, contacto e as etapas com confirmação', (
      t,
    ) async {
      final repo = await _profissional();
      await montarEcra(
        t,
        const TrabalhoDetalheView(pedidoId: 'tp1'),
        repo: repo,
        destinos: ['/conversas/:id', '/qr'],
        comScaffold: false,
      );
      for (final s in [
        'O trabalho',
        'Fuga de água na cozinha',
        'Maria Kiala',
        '+244 923 000 000',
        'Rua 21, casa 14, Talatona',
        'Ponto de referência: perto da cantina do Sr. Zé',
        'Ligar',
        'Conversa',
        'Estou a caminho',
        'Comecei o trabalho',
      ]) {
        expect(find.text(s), findsOneWidget, reason: s);
      }

      await t.tap(find.text('Ligar'));
      await t.pump();
      expect(find.text('Em breve'), findsOneWidget);

      await t.ensureVisible(find.text('Estou a caminho'));
      await t.tap(find.text('Estou a caminho'));
      await t.pumpAndSettle();
      expect(find.text('Está a caminho?'), findsOneWidget);
      await t.tap(find.text('Sim, avisar'));
      await t.pumpAndSettle();
      expect(find.text('A CAMINHO'), findsOneWidget);
      expect(find.text('Estou a caminho'), findsNothing);
      expect(find.text('Feito. O cliente já foi avisado.'), findsOneWidget);

      await t.ensureVisible(find.text('Comecei o trabalho'));
      await t.tap(find.text('Comecei o trabalho'));
      await t.pumpAndSettle();
      await t.tap(find.text('Sim, avisar'));
      await t.pumpAndSettle();
      expect(
        find.text('Quando acabar, peça ao cliente o código de 6 dígitos.'),
        findsOneWidget,
      );
      // Espera o SnackBar sair de cima do botão.
      await t.pump(const Duration(seconds: 5));
      await t.pumpAndSettle();
      await t.drag(find.byType(ListView), const Offset(0, -600));
      await t.pumpAndSettle();
      await t.tap(find.text('Confirmar serviço'));
      await t.pumpAndSettle();
      expect(find.text('DESTINO /qr'), findsOneWidget);
    });

    testWidgets('sem overflow com texto a 200 %', (t) async {
      await montarEcra(
        t,
        const TrabalhoDetalheView(pedidoId: 'tp1'),
        repo: await _profissional(),
        escala: 2,
        comScaffold: false,
      );
      expect(t.takeException(), isNull);
    });
  });
}
