// Gera as capturas de alta resolução de todos os ecrãs (arquivo documental).
//
//   flutter test tool/capturas/capturas_test.dart
//
// Saída: ../../build/capturas_v3/NN-nome.png (390x844 dp a 8x = 3120x6752 px).
// Variáveis opcionais: CAPTURAS_DIR (pasta de saída), CAPTURAS_SO (prefixos
// separados por vírgula, ex. "03,04" para refazer só alguns ecrãs).
// Não faz parte do `flutter test` por omissão (fica fora de test/).
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kisalu_express/core/router/app_routes.dart';
import 'package:kisalu_express/data/repositories/mock_kisalu_repository.dart';
import 'package:kisalu_express/kisalu_app.dart';
import 'package:kisalu_express/models/utilizador.dart';

const _largura = 390.0;
const _altura = 844.0;
const _escala = 8.0;

final _saida = Directory(
  Platform.environment['CAPTURAS_DIR'] ?? '../../build/capturas_v3',
);
final _so = (Platform.environment['CAPTURAS_SO'] ?? '')
    .split(',')
    .where((e) => e.isNotEmpty)
    .toList();

Future<void> _carregarFonte(String familia, String caminho) async {
  final bytes = await File(caminho).readAsBytes();
  final loader = FontLoader(familia)
    ..addFont(Future.value(ByteData.sublistView(bytes)));
  await loader.load();
}

Future<void> _fontes() async {
  const dm = {
    400: 'Regular',
    500: 'Medium',
    600: 'SemiBold',
    700: 'Bold',
  };
  // DMSans está declarada no pubspec; carregar à mão garante o mesmo em teste.
  final loader = FontLoader('DMSans');
  for (final f in dm.values) {
    final b = await File('assets/fonts/DMSans-$f.ttf').readAsBytes();
    loader.addFont(Future.value(ByteData.sublistView(b)));
  }
  await loader.load();
  // Sora (títulos) vem do Google Fonts em runtime; offline usamos o ficheiro
  // em tool/capturas/fontes sob os nomes de família que o google_fonts pede.
  for (final w in [
    'regular', '500', '600', '700', '800', //
  ]) {
    await _carregarFonte('Sora_$w', 'tool/capturas/fontes/Sora.ttf');
  }
  // Ícones Material (estrelas) a partir do SDK do Flutter.
  var raiz = Platform.environment['FLUTTER_ROOT'];
  if (raiz == null) {
    var d = File(Platform.resolvedExecutable).parent;
    while (d.parent.path != d.path && !Directory('${d.path}/bin/cache').existsSync()) {
      d = d.parent;
    }
    raiz = d.path;
  }
  await _carregarFonte(
    'MaterialIcons',
    '$raiz/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
  );
  // Símbolos como ✓ (o Windows fornece um tipo com cobertura; opcional).
  const simbolos = 'C:/Windows/Fonts/seguisym.ttf';
  if (File(simbolos).existsSync()) await _carregarFonte('Roboto', simbolos);
  // Ícones Lucide (o pacote só os regista no build da app).
  await _carregarFonte(
    'packages/lucide_icons_flutter/Lucide',
    'tool/capturas/fontes/Lucide.ttf',
  );
}

final _chave = GlobalKey();

Future<void> _abrir(
  WidgetTester t,
  String rota, {
  PerfilUtilizador perfil = PerfilUtilizador.cliente,
}) async {
  t.view.physicalSize = const Size(_largura * _escala, _altura * _escala);
  t.view.devicePixelRatio = _escala;
  addTearDown(t.view.reset);
  final repo = MockKisaluRepository();
  if (perfil != PerfilUtilizador.cliente) await repo.mudarPerfil(perfil);
  await t.pumpWidget(
    RepaintBoundary(
      key: _chave,
      child: KisaluApp(repository: repo, localInicial: rota),
    ),
  );
  await t.pumpAndSettle();
}

Future<void> _tocar(WidgetTester t, String texto) async {
  final f = find.text(texto).first;
  await t.ensureVisible(f);
  await t.tap(f);
  await t.pumpAndSettle();
}

Future<void> _gravar(WidgetTester t, String nome) async {
  await t.pumpAndSettle();
  final boundary =
      _chave.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await t.runAsync(() async {
    final img = await boundary.toImage(pixelRatio: _escala);
    final dados = await img.toByteData(format: ui.ImageByteFormat.png);
    _saida.createSync(recursive: true);
    File('${_saida.path}/$nome.png')
        .writeAsBytesSync(dados!.buffer.asUint8List());
    img.dispose();
  });
}

void _ecra(
  String nome,
  String rota, {
  PerfilUtilizador perfil = PerfilUtilizador.cliente,
  Future<void> Function(WidgetTester t)? passos,
}) {
  if (_so.isNotEmpty && !_so.any(nome.startsWith)) return;
  testWidgets(nome, (t) async {
    await _abrir(t, rota, perfil: perfil);
    if (passos != null) await passos(t);
    await _gravar(t, nome);
  });
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
    await _fontes();
  });

  const prof = PerfilUtilizador.profissional;

  _ecra('01-login', AppRoutes.login);
  _ecra('02-inicio', AppRoutes.inicio);
  _ecra('03-perfil-profissional', AppRoutes.profissional('p1'));
  _ecra('04-pedido-propostas', AppRoutes.pedido('ped1'));
  _ecra('05-confirmar-qr', AppRoutes.qr);
  _ecra('06-avaliar-servico', AppRoutes.avaliar('ped1'));
  _ecra('07-historico-pedidos', AppRoutes.pedidos);
  _ecra('08-confirmar-proposta', AppRoutes.pedido('ped1'),
      passos: (t) => _tocar(t, 'Ver e aceitar'));
  _ecra('09-qr-sem-servico', '${AppRoutes.qr}?vazio=1');
  _ecra('10-novo-pedido', AppRoutes.novoPedidoInicio);
  _ecra('10b-novo-pedido-sem-rede', AppRoutes.novoPedido);
  _ecra('11-codigo-sms', AppRoutes.codigoSms);
  _ecra('12-registo-profissional', AppRoutes.registoProfissional);
  _ecra('13-verificar-identidade', AppRoutes.verificarIdentidade);
  _ecra('14-inicio-profissional', AppRoutes.inicio, perfil: prof);
  _ecra('15-enviar-proposta', AppRoutes.enviarProposta('pp1'), perfil: prof);
  _ecra('16-ler-qr', AppRoutes.qr, perfil: prof);
  _ecra('17-servico-confirmado', AppRoutes.servicoConfirmado('tp1'),
      perfil: prof);
  _ecra('18-conversas', AppRoutes.conversas);
  _ecra('19-conversa', AppRoutes.conversa('c1'));
  _ecra('20-perfil', AppRoutes.perfil);
  _ecra('21-todos-servicos', AppRoutes.categorias);
  _ecra('22-mapa', AppRoutes.mapa);
  _ecra('23-notificacoes', AppRoutes.notificacoes);
  _ecra('24-ajuda', AppRoutes.ajuda);
  _ecra('25-trabalho-detalhe', AppRoutes.trabalho('tp1'), perfil: prof);
  _ecra('26-pedido-aceite', AppRoutes.pedido('ped1'), passos: (t) async {
    await _tocar(t, 'Ver e aceitar');
    await _tocar(t, 'Confirmar proposta');
  });
  _ecra('27-editar-pedido', AppRoutes.editarPedido('ped1'));
  _ecra('28-reportar-problema', AppRoutes.pedidos, passos: (t) async {
    await _tocar(t, 'Ver comprovativo');
    await _tocar(t, 'Reportar problema');
  });
  _ecra('29-comprovativo', AppRoutes.pedidos,
      passos: (t) => _tocar(t, 'Ver comprovativo'));
  _ecra('30-recusar-proposta', AppRoutes.pedido('ped1'),
      passos: (t) => _tocar(t, 'Recusar'));
}
