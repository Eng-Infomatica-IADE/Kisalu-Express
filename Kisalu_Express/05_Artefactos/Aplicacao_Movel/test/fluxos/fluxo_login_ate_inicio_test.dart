import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kisalu_express/data/repositories/mock_kisalu_repository.dart';
import 'package:kisalu_express/kisalu_app.dart';
import 'package:kisalu_express/models/utilizador.dart';

/// Fluxos de ponta a ponta, na app inteira: do Login ao Início, como cliente
/// e como profissional (ecrãs 01, 11, 12, 13, 02 e 14), e o que se faz a
/// seguir no modo profissional (15, 16, 17).
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<MockKisaluRepository> abrirApp(WidgetTester t) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final repo = MockKisaluRepository();
    await t.pumpWidget(KisaluApp(repository: repo));
    await t.pumpAndSettle();
    return repo;
  }

  Future<void> receberCodigo(WidgetTester t, {bool criarConta = false}) async {
    await t.tap(find.text(criarConta ? 'Criar conta' : 'Receber código SMS'));
    await t.pumpAndSettle();
    expect(find.text('Introduza o código'), findsOneWidget);
  }

  Future<void> confirmarCodigo(
    WidgetTester t, [
    String codigo = '482173',
  ]) async {
    await t.enterText(find.byType(TextField), codigo);
    await t.pump();
    await t.tap(find.text('Confirmar'));
    await t.pumpAndSettle();
  }

  group('cliente', () {
    testWidgets('Receber código SMS → código → Início do cliente', (t) async {
      final repo = await abrirApp(t);
      await receberCodigo(t);
      expect(
        find.text('Enviámos um código de 6 dígitos para\n+244 923 000 000.'),
        findsOneWidget,
      );
      await confirmarCodigo(t);
      expect(find.text('Boa tarde, Maria'), findsOneWidget);
      expect(find.text('Perto de si'), findsOneWidget);
      expect(repo.perfilAtivo, PerfilUtilizador.cliente);
    });

    testWidgets('Criar conta como cliente → código → Início do cliente', (
      t,
    ) async {
      await abrirApp(t);
      await receberCodigo(t, criarConta: true);
      await confirmarCodigo(t);
      expect(find.text('Boa tarde, Maria'), findsOneWidget);
      expect(find.text('Criar perfil'), findsNothing);
    });

    testWidgets('o número que se escreveu é o do ecrã do código', (t) async {
      await abrirApp(t);
      await t.enterText(find.byType(TextField), '+244 912 345 678');
      await receberCodigo(t);
      expect(
        find.text('Enviámos um código de 6 dígitos para\n+244 912 345 678.'),
        findsOneWidget,
      );
    });

    testWidgets('número inválido não passa do Login', (t) async {
      await abrirApp(t);
      await t.enterText(find.byType(TextField), '+244 923 45');
      await t.tap(find.text('Receber código SMS'));
      await t.pumpAndSettle();
      expect(find.text('Introduza o código'), findsNothing);
      expect(find.text('Entrar ou criar conta'), findsOneWidget);
    });

    testWidgets(
      'código errado fica no ecrã e "Alterar número" volta ao Login',
      (t) async {
        await abrirApp(t);
        await receberCodigo(t);
        await confirmarCodigo(t, '000000');
        expect(
          find.text(
            'O código não está certo. Confirme o SMS e tente outra vez.',
          ),
          findsOneWidget,
        );
        expect(find.text('Boa tarde, Maria'), findsNothing);
        await t.tap(find.text('Alterar número'));
        await t.pumpAndSettle();
        expect(find.text('Entrar ou criar conta'), findsOneWidget);
      },
    );

    testWidgets('o Início do cliente leva a Todos os serviços e ao Mapa', (
      t,
    ) async {
      await abrirApp(t);
      await receberCodigo(t);
      await confirmarCodigo(t);
      await t.tap(find.text('Ver todos'));
      await t.pumpAndSettle();
      expect(find.text('Todos os serviços'), findsOneWidget);
      await t.tap(find.bySemanticsLabel('Voltar'));
      await t.pumpAndSettle();
      await t.ensureVisible(find.text('Mapa'));
      await t.tap(find.text('Mapa'));
      await t.pumpAndSettle();
      expect(find.text('Lista'), findsOneWidget);
    });

    testWidgets('Conversas → conversa → enviar mensagem', (t) async {
      await abrirApp(t);
      await receberCodigo(t);
      await confirmarCodigo(t);
      await t.tap(find.text('Conversas'));
      await t.pumpAndSettle();
      await t.tap(find.text('Joaquim Manuel'));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField), 'Até já!');
      await t.tap(find.bySemanticsLabel('Enviar mensagem'));
      await t.pumpAndSettle();
      expect(find.text('Até já!'), findsOneWidget);
    });

    testWidgets('Perfil → Terminar sessão → Login', (t) async {
      await abrirApp(t);
      await receberCodigo(t);
      await confirmarCodigo(t);
      await t.tap(find.text('Perfil'));
      await t.pumpAndSettle();
      expect(find.text('+244 923 *** 000'), findsOneWidget);
      await t.tap(find.text('Terminar sessão'));
      await t.pumpAndSettle();
      expect(find.text('Terminar sessão?'), findsOneWidget);
      await t.tap(find.text('Terminar sessão').last);
      await t.pumpAndSettle();
      expect(find.text('Entrar ou criar conta'), findsOneWidget);
    });
  });

  group('profissional', () {
    Future<void> escolherProfissional(WidgetTester t) async {
      await t.tap(find.text('Sou profissional'));
      await t.pumpAndSettle();
    }

    testWidgets('Sou profissional → Receber código → Início do profissional', (
      t,
    ) async {
      final repo = await abrirApp(t);
      await escolherProfissional(t);
      await receberCodigo(t);
      await confirmarCodigo(t);
      expect(find.text('Boa tarde, Joaquim'), findsOneWidget);
      expect(find.text('Disponível para trabalhar'), findsOneWidget);
      expect(find.text('Pedidos perto de si'), findsOneWidget);
      expect(find.text('Boa tarde, Maria'), findsNothing);
      expect(repo.perfilAtivo, PerfilUtilizador.profissional);
    });

    testWidgets(
      'Criar conta → código → Criar perfil → Verificar identidade → Início',
      (t) async {
        await abrirApp(t);
        await escolherProfissional(t);
        await receberCodigo(t, criarConta: true);
        await confirmarCodigo(t);
        expect(find.text('Que serviços presta?'), findsOneWidget);
        await t.ensureVisible(find.text('Continuar'));
        await t.pump();
        await t.tap(find.text('Continuar'));
        await t.pumpAndSettle();
        expect(find.text('Documento de identidade'), findsOneWidget);
        await t.ensureVisible(find.text('Fazer mais tarde'));
        await t.pump();
        await t.tap(find.text('Fazer mais tarde'));
        await t.pumpAndSettle();
        expect(find.text('Boa tarde, Joaquim'), findsOneWidget);
      },
    );

    testWidgets('verificar identidade completa e enviada vai ao Início', (
      t,
    ) async {
      await abrirApp(t);
      await escolherProfissional(t);
      await receberCodigo(t, criarConta: true);
      await confirmarCodigo(t);
      await t.ensureVisible(find.text('Continuar'));
      await t.pump();
      await t.tap(find.text('Continuar'));
      await t.pumpAndSettle();
      await t.tap(find.text('Fotografia do rosto'));
      await t.pumpAndSettle();
      await t.ensureVisible(find.text('Enviar para verificação'));
      await t.pump();
      await t.tap(find.text('Enviar para verificação'));
      await t.pumpAndSettle();
      expect(find.text('Boa tarde, Joaquim'), findsOneWidget);
      expect(find.text('Enviado para verificação.'), findsOneWidget);
    });

    testWidgets('registo sem nome não avança', (t) async {
      await abrirApp(t);
      await escolherProfissional(t);
      await receberCodigo(t, criarConta: true);
      await confirmarCodigo(t);
      await t.enterText(find.widgetWithText(TextField, 'Joaquim Manuel'), '');
      await t.ensureVisible(find.text('Continuar'));
      await t.pump();
      await t.tap(find.text('Continuar'));
      await t.pumpAndSettle();
      expect(find.text('Escreva o seu nome.'), findsOneWidget);
      expect(find.text('Documento de identidade'), findsNothing);
    });

    testWidgets('Ver pedido → Enviar proposta → volta ao Início com aviso', (
      t,
    ) async {
      final repo = await abrirApp(t);
      await escolherProfissional(t);
      await receberCodigo(t);
      await confirmarCodigo(t);
      await t.tap(find.text('Ver pedido').first);
      await t.pumpAndSettle();
      expect(find.text('O que inclui o preço?'), findsOneWidget);
      expect(find.text('12.500 Kz'), findsOneWidget);
      await t.tap(find.widgetWithText(GestureDetector, 'Enviar proposta'));
      await t.pumpAndSettle();
      expect(find.text('Boa tarde, Joaquim'), findsOneWidget);
      expect(
        find.text('Proposta enviada. O cliente já a pode ver.'),
        findsOneWidget,
      );
      expect(repo.propostasEnviadas.single.valorFechado, 12500);
    });

    testWidgets('o separador QR é o ecrã 16 e confirma o serviço (17)', (
      t,
    ) async {
      await abrirApp(t);
      await escolherProfissional(t);
      await receberCodigo(t);
      await confirmarCodigo(t);
      await t.tap(find.text('QR'));
      await t.pumpAndSettle();
      expect(find.text('Código de confirmação'), findsOneWidget);
      await t.tap(find.widgetWithText(GestureDetector, 'Confirmar serviço'));
      await t.pumpAndSettle();
      expect(find.text('Trabalho concluído'), findsOneWidget);
      expect(
        find.text('Maria K. confirmou o valor combinado.'),
        findsOneWidget,
      );
      await t.tap(find.text('Voltar ao Início'));
      await t.pumpAndSettle();
      expect(find.text('Boa tarde, Joaquim'), findsOneWidget);
    });

    testWidgets('o separador Pedidos mostra os trabalhos do profissional', (
      t,
    ) async {
      await abrirApp(t);
      await escolherProfissional(t);
      await receberCodigo(t);
      await confirmarCodigo(t);
      await t.tap(find.text('Pedidos'));
      await t.pumpAndSettle();
      expect(find.text('Desentupir pia'), findsOneWidget);
      expect(find.textContaining('Maria K.'), findsOneWidget);
    });

    testWidgets(
      'Perfil → Mudar para cliente → Início do cliente → e de volta',
      (t) async {
        final repo = await abrirApp(t);
        await escolherProfissional(t);
        await receberCodigo(t);
        await confirmarCodigo(t);
        await t.tap(find.text('Perfil'));
        await t.pumpAndSettle();
        expect(find.text('Joaquim Manuel'), findsOneWidget);
        await t.tap(find.text('Mudar para cliente'));
        await t.pumpAndSettle();
        expect(find.text('Boa tarde, Maria'), findsOneWidget);
        expect(repo.perfilAtivo, PerfilUtilizador.cliente);

        await t.tap(find.text('Perfil'));
        await t.pumpAndSettle();
        await t.tap(find.text('Mudar para profissional'));
        await t.pumpAndSettle();
        expect(find.text('Boa tarde, Joaquim'), findsOneWidget);
      },
    );

    testWidgets('Terminar sessão no modo profissional volta ao Login', (
      t,
    ) async {
      await abrirApp(t);
      await escolherProfissional(t);
      await receberCodigo(t);
      await confirmarCodigo(t);
      await t.tap(find.text('Perfil'));
      await t.pumpAndSettle();
      await t.tap(find.text('Terminar sessão'));
      await t.pumpAndSettle();
      expect(find.text('Terminar sessão?'), findsOneWidget);
      await t.tap(find.text('Terminar sessão').last);
      await t.pumpAndSettle();
      expect(find.text('Entrar ou criar conta'), findsOneWidget);
    });
  });
}
