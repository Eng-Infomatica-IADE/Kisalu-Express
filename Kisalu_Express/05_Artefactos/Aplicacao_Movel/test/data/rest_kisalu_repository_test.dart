import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kisalu_express/data/repositories/kisalu_repository.dart';
import 'package:kisalu_express/data/repositories/rest_kisalu_repository.dart';
import 'package:kisalu_express/models/avaliacao.dart';
import 'package:kisalu_express/models/comprovativo.dart';
import 'package:kisalu_express/models/conversa.dart';
import 'package:kisalu_express/models/estado_pedido.dart';
import 'package:kisalu_express/models/nova_proposta.dart';
import 'package:kisalu_express/models/novo_pedido.dart';
import 'package:kisalu_express/models/pedido.dart';
import 'package:kisalu_express/models/proposta.dart';
import 'package:kisalu_express/models/registo_profissional.dart';
import 'package:kisalu_express/models/utilizador.dart';
import 'package:kisalu_express/services/api_client.dart';
import 'package:kisalu_express/services/armazenamento_local.dart';

// Dados fictícios, com a forma de docs/CONTRATO-API.md (secção 1).

const _base = 'http://api.teste/api';

Map<String, dynamic> _env(Object? data, {int status = 200, String? detail}) => {
  'title': 'ok',
  'status': status,
  'detail': detail,
  'instance': '/x',
  'data': data,
};

const _joaquim = {
  'id': 2,
  'nome': 'Joaquim Manuel',
  'foto_url': null,
  'categoria': 'Canalizador',
  'categoria_chave': 'canalizador',
  'zona': 'Talatona, Luanda',
  'distancia_km': 1.2,
  'rating': 4.8,
  'num_avaliacoes': 126,
  'servicos_confirmados': 126,
  'anos_experiencia': 6,
  'verificado': 1,
  'mao_de_obra_desde': 8000,
};

const _proposta = {
  'id': 1,
  'proposta_id': 1,
  'estado': 'enviada',
  'valor_total': 12500,
  'componentes': {'mao_de_obra': 8000, 'material': 3500, 'deslocacao': 1000},
  'material_detalhe': 'sifão e vedante',
  'tempo_chegada_min': 40,
  'na_hora_pedida': false,
  'chegada_prevista': '2026-10-20T14:40:00Z',
  'profissional': _joaquim,
};

const _pedido = {
  'id': 1,
  'titulo': 'Fuga de água na cozinha',
  'descricao': 'Cano a pingar debaixo do lava-loiça.',
  'categoria_chave': 'canalizador',
  'estado': 'com_propostas',
  'criado_em': '2026-10-20T13:00:00Z',
  'data_pretendida': null,
  'zona': 'Talatona',
  'num_fotos': 1,
  'profissional': null,
  'valor_acordado': null,
  'proposta_aceite_id': null,
  'cliente_curto': null,
  'propostas': [_proposta],
};

const _eu = {
  'id': 1,
  'nome': 'Maria Kiala',
  'telemovel': '+244923000000',
  'email': null,
  'foto_url': null,
  'tipo_perfil': 'cliente',
  'perfil_ativo': 'cliente',
  'zona': 'Talatona, Luanda',
  'tem_novidades': true,
  'moradas_guardadas': 2,
  'favoritos': 3,
  'profissional': null,
};

const _comprovativo = {
  'numero_comprovativo': 'KX-2026-000001',
  'pedido_id': 1,
  'titulo': 'Fuga de água na cozinha',
  'cliente': 'Maria Kiala',
  'cliente_curto': 'Maria K.',
  'profissional': _joaquim,
  'valor_kz': 12500,
  'metodo_pagamento': 'multicaixa_express',
  'metodo_confirmacao': 'codigo',
  'confirmado_em': '2026-10-20T15:10:00Z',
  'valor_formatado': '12 500 Kz',
  'partilha_whatsapp': '…',
};

typedef _Resposta = ({int status, Object? corpo});

/// Servidor falso: regista os pedidos e responde por "MÉTODO /caminho".
class _Servidor {
  final pedidos = <http.Request>[];
  final rotas = <String, _Resposta Function(http.Request)>{};

  void em(String rota, Object? data, {int status = 200, String? detail}) {
    rotas[rota] = (_) =>
        (status: status, corpo: _env(data, status: status, detail: detail));
  }

  http.Request get ultimo => pedidos.last;

  Map<String, dynamic> corpo([http.Request? p]) =>
      jsonDecode((p ?? ultimo).body) as Map<String, dynamic>;

  late final cliente = MockClient((pedido) async {
    pedidos.add(pedido);
    final chave =
        '${pedido.method} ${pedido.url.path.replaceFirst('/api', '')}';
    final rota = rotas[chave];
    if (rota == null) {
      return http.Response(
        jsonEncode(_env(null, status: 404, detail: 'Não existe.')),
        404,
      );
    }
    final r = rota(pedido);
    return http.Response.bytes(utf8.encode(jsonEncode(r.corpo)), r.status);
  });
}

void main() {
  late _Servidor servidor;
  late ApiClient api;
  late RestKisaluRepository repo;

  setUp(() {
    servidor = _Servidor();
    api = ApiClient(baseUrl: '$_base/', cliente: servidor.cliente);
    repo = RestKisaluRepository(api);
  });

  /// Entra como Maria (cliente): fica com token. Devolve o resultado de
  /// `validarCodigoSms` ("precisa de registo profissional").
  Future<bool> entrar({
    PerfilUtilizador perfil = PerfilUtilizador.cliente,
    bool criarConta = false,
    bool novo = false,
    Map<String, dynamic>? profissional,
  }) async {
    servidor
      ..em('POST /auth/sms/pedir', {
        'mensagem': 'Enviámos o código.',
        'expira_em_min': 5,
        'reenviar_em_s': 60,
        'codigo_dev': '123456',
      })
      ..em('POST /auth/sms/verificar', {
        'token': 'tok-abc',
        'novo': novo,
        'perfil_ativo': perfil.name,
        'utilizador': {..._eu, 'profissional': profissional},
      });
    await repo.pedirCodigoSms('+244923000000', perfil, criarConta: criarConta);
    return repo.validarCodigoSms('+244923000000', '123456');
  }

  group('ApiClient', () {
    test('desembrulha data e junta o caminho à base sem barra dupla', () async {
      servidor.em('GET /saude', {'ok': true});
      expect(await api.get('/saude'), {'ok': true});
      expect(servidor.ultimo.url.toString(), '$_base/saude');
      expect(servidor.ultimo.headers['Accept'], 'application/json');
    });

    test('sem token não manda Authorization; com token manda Bearer', () async {
      servidor.em('GET /eu', _eu);
      await api.get('/eu');
      expect(servidor.ultimo.headers.containsKey('Authorization'), isFalse);
      api.definirToken('xyz');
      await api.get('/eu');
      expect(servidor.ultimo.headers['Authorization'], 'Bearer xyz');
    });

    test('envia JSON em UTF-8', () async {
      servidor.em('POST /eco', null);
      await api.post('/eco', {'texto': 'Olá, até já'});
      expect(servidor.ultimo.headers['Content-Type'], contains('json'));
      expect(servidor.corpo(), {'texto': 'Olá, até já'});
    });

    test('401 apaga o token, avisa e lança SessaoExpiradaException', () async {
      var avisos = 0;
      api
        ..definirToken('velho')
        ..aoExpirarSessao = () => avisos++;
      servidor.em('GET /eu', null, status: 401, detail: 'Sessão inválida.');
      await expectLater(
        api.get('/eu'),
        throwsA(isA<SessaoExpiradaException>()),
      );
      expect(api.token, isNull);
      expect(avisos, 1);
    });

    test('403 → SemPermissaoException com o detail', () async {
      servidor.em('GET /x', null, status: 403, detail: 'Conta desativada.');
      await expectLater(
        api.get('/x'),
        throwsA(
          isA<SemPermissaoException>().having(
            (e) => e.mensagem,
            'mensagem',
            'Conta desativada.',
          ),
        ),
      );
    });

    test('404 → NaoEncontradoException', () async {
      await expectLater(
        api.get('/nada'),
        throwsA(isA<NaoEncontradoException>()),
      );
    });

    for (final status in [400, 409, 422, 429]) {
      test('$status → ValidacaoException com o detail', () async {
        servidor.em('POST /x', null, status: status, detail: 'Não pode.');
        await expectLater(
          api.post('/x', const {}),
          throwsA(
            isA<ValidacaoException>().having(
              (e) => e.mensagem,
              'mensagem',
              'Não pode.',
            ),
          ),
        );
      });
    }

    test('5xx → ServidorException (sem mostrar o detail)', () async {
      servidor.em('GET /x', null, status: 500, detail: 'stack trace');
      await expectLater(
        api.get('/x'),
        throwsA(
          isA<ServidorException>().having(
            (e) => e.mensagem,
            'mensagem',
            isNot(contains('stack')),
          ),
        ),
      );
    });

    test('falha de rede → SemRedeException', () async {
      final semRede = ApiClient(
        baseUrl: _base,
        cliente: MockClient((_) => throw http.ClientException('offline')),
      );
      await expectLater(
        semRede.get('/saude'),
        throwsA(isA<SemRedeException>()),
      );
    });

    test('timeout → SemRedeException', () async {
      final lento = ApiClient(
        baseUrl: _base,
        timeout: const Duration(milliseconds: 10),
        cliente: MockClient((_) => Completer<http.Response>().future),
      );
      await expectLater(lento.get('/saude'), throwsA(isA<SemRedeException>()));
    });
  });

  group('sessão', () {
    test('pedirCodigoSms envia telemovel, perfil e criar_conta', () async {
      await entrar();
      final pedir = servidor.pedidos.first;
      expect(pedir.url.path, '/api/auth/sms/pedir');
      expect(servidor.corpo(pedir), {
        'telemovel': '+244923000000',
        'perfil': 'cliente',
        'criar_conta': false,
      });
      final pendente = await repo.codigoSmsPendente();
      expect(pendente.telemovel, '+244923000000');
    });

    test('codigoSmsPendente sem pedido lança ValidacaoException', () async {
      await expectLater(
        repo.codigoSmsPendente(),
        throwsA(isA<ValidacaoException>()),
      );
    });

    test(
      'em debug o código de desenvolvimento pré-preenche o ecrã 11',
      () async {
        servidor.em('POST /auth/sms/pedir', {'codigo_dev': '654321'});
        await repo.pedirCodigoSms('+244923000000', PerfilUtilizador.cliente);
        expect(await repo.codigoSmsPredefinido(), '654321');
      },
    );

    test('validarCodigoSms guarda o token e o perfil ativo', () async {
      expect(await entrar(), isFalse);
      expect(api.token, 'tok-abc');
      expect(repo.temSessao, isTrue);
      expect(repo.perfilAtivo, PerfilUtilizador.cliente);
      expect(servidor.corpo(), {
        'telemovel': '+244923000000',
        'codigo': '123456',
        'perfil': 'cliente',
        'aceita_privacidade': true,
      });
      servidor.em('GET /eu', _eu);
      await repo.utilizador();
      expect(servidor.ultimo.headers['Authorization'], 'Bearer tok-abc');
    });

    test('cliente nunca precisa de registo profissional', () async {
      servidor
        ..em('POST /auth/sms/pedir', const {})
        ..em('POST /auth/sms/verificar', {
          'token': 't',
          'novo': true,
          'perfil_ativo': 'cliente',
          'utilizador': _eu,
        });
      await repo.pedirCodigoSms('+244923000000', PerfilUtilizador.cliente);
      expect(await repo.validarCodigoSms('+244923000000', '123456'), isFalse);
    });

    Future<bool> validarProfissional({
      bool novo = false,
      bool criarConta = false,
      bool registoCompleto = true,
    }) async {
      servidor
        ..em('POST /auth/sms/pedir', const {})
        ..em('POST /auth/sms/verificar', {
          'token': 't',
          'novo': novo,
          'perfil_ativo': 'profissional',
          'utilizador': {
            ..._eu,
            'profissional': {'registo_completo': registoCompleto},
          },
        });
      await repo.pedirCodigoSms(
        '+244923000002',
        PerfilUtilizador.profissional,
        criarConta: criarConta,
      );
      return repo.validarCodigoSms('+244923000002', '123456');
    }

    test('profissional com registo completo vai para o Início', () async {
      expect(await validarProfissional(), isFalse);
      expect(repo.perfilAtivo, PerfilUtilizador.profissional);
    });

    test(
      'profissional novo, a criar conta ou incompleto vai para o registo',
      () async {
        expect(await validarProfissional(novo: true), isTrue);
        expect(await validarProfissional(criarConta: true), isTrue);
        expect(await validarProfissional(registoCompleto: false), isTrue);
      },
    );

    test('código errado → ValidacaoException com a mensagem da API', () async {
      servidor
        ..em('POST /auth/sms/pedir', const {})
        ..em(
          'POST /auth/sms/verificar',
          {'codigo': 'CODIGO_ERRADO'},
          status: 400,
          detail: 'O código não está certo. Confirme o SMS e tente outra vez.',
        );
      await repo.pedirCodigoSms('+244923000000', PerfilUtilizador.cliente);
      await expectLater(
        repo.validarCodigoSms('+244923000000', '000000'),
        throwsA(
          isA<ValidacaoException>().having(
            (e) => e.mensagem,
            'mensagem',
            startsWith('O código não está certo'),
          ),
        ),
      );
      expect(repo.temSessao, isFalse);
    });

    test('utilizador lê EuJSON', () async {
      await entrar();
      servidor.em('GET /eu', _eu);
      final u = await repo.utilizador();
      expect(u.nome, 'Maria');
      expect(u.nomeCompleto, 'Maria Kiala');
      expect(u.zona, 'Talatona, Luanda');
      expect(u.temNovidades, isTrue);
      expect(u.moradasGuardadas, 2);
      expect(u.favoritos, 3);
    });

    test('mudarPerfil chama PUT /eu/perfil-ativo e avisa', () async {
      await entrar();
      var avisos = 0;
      repo.alteracoes.addListener(() => avisos++);
      servidor.em('PUT /eu/perfil-ativo', {
        'perfil_ativo': 'profissional',
        'utilizador': _eu,
      });
      await repo.mudarPerfil(PerfilUtilizador.profissional);
      expect(servidor.corpo(), {'perfil': 'profissional'});
      expect(repo.perfilAtivo, PerfilUtilizador.profissional);
      expect(avisos, 1);
      final n = servidor.pedidos.length;
      await repo.mudarPerfil(PerfilUtilizador.profissional);
      expect(servidor.pedidos.length, n, reason: 'mesmo perfil não chama');
    });

    test('terminarSessao chama /auth/sair e apaga o token', () async {
      await entrar();
      servidor.em('POST /auth/sair', null);
      await repo.terminarSessao();
      expect(servidor.ultimo.url.path, '/api/auth/sair');
      expect(repo.temSessao, isFalse);
    });

    test('terminarSessao apaga o token mesmo sem resposta da API', () async {
      await entrar();
      await repo.terminarSessao(); // /auth/sair não existe → 404
      expect(repo.temSessao, isFalse);
    });

    test('401 limpa a sessão e avisa sessaoExpirada', () async {
      await entrar(perfil: PerfilUtilizador.profissional);
      var avisos = 0;
      repo.sessaoExpirada.addListener(() => avisos++);
      servidor.em('GET /conversas', null, status: 401);
      await expectLater(
        repo.conversas(),
        throwsA(isA<SessaoExpiradaException>()),
      );
      expect(avisos, 1);
      expect(repo.temSessao, isFalse);
      expect(repo.perfilAtivo, PerfilUtilizador.cliente);
    });
  });

  group('início, profissional e pedidos', () {
    test('categorias usa a chave como id', () async {
      servidor.em('GET /categorias', [
        {
          'id': 1,
          'chave': 'ar_cond',
          'nome': 'Ar condicionado',
          'plural': 'técnicos de ar condicionado',
          'em_destaque': 1,
          'icone': 'ar',
          'profissionais_disponiveis': 4,
        },
      ]);
      final c = (await repo.categorias()).single;
      expect(c.id, 'ar_cond');
      expect(c.nome, 'Ar condicionado');
      expect(c.emDestaque, isTrue);
    });

    test('profissionaisPertoDeSi pede limit=20 e converte o resumo', () async {
      servidor.em('GET /profissionais/perto', [
        _joaquim,
        {..._joaquim, 'id': 3, 'distancia_km': null, 'mao_de_obra_desde': null},
      ]);
      final lista = await repo.profissionaisPertoDeSi();
      expect(servidor.ultimo.url.queryParameters, {'limit': '20'});
      expect(lista.first.id, '2');
      expect(lista.first.verificado, isTrue);
      expect(lista.first.rating, 4.8);
      expect(lista.first.maoDeObraDesde, 8000);
      expect(lista.last.distanciaKm, 0);
      expect(lista.last.maoDeObraDesde, 0);
    });

    test('profissional(id) lê o detalhe com trabalhos e avaliações', () async {
      servidor.em('GET /profissionais/2', {
        ..._joaquim,
        'especialidades': ['Fugas de água'],
        'trabalhos_feitos': [
          {'id': 1, 'legenda': 'Antes/depois', 'url': '/uploads/t/x.jpg'},
        ],
        'total_trabalhos_feitos': 41,
        'avaliacoes': [
          {
            'autor': 'Maria K.',
            'estrelas': 5,
            'comentario': 'Rápido e limpo.',
            'etiquetas': ['pontual', 'preco_justo', 'desconhecida'],
          },
        ],
      });
      final p = (await repo.profissional('2'))!;
      expect(p.especialidades, ['Fugas de água']);
      expect(p.trabalhosFeitos.single.fotoUrl, '/uploads/t/x.jpg');
      expect(p.totalTrabalhosFeitos, 41);
      expect(p.avaliacoes.single.etiquetas, [
        EtiquetaAvaliacao.pontual,
        EtiquetaAvaliacao.precoJusto,
      ]);
    });

    test('ids que não são números devolvem null sem chamar a API', () async {
      expect(await repo.profissional('p1'), isNull);
      expect(await repo.pedido('ped1'), isNull);
      expect(await repo.conversa('c1'), isNull);
      expect(await repo.pedidoPerto('pp1'), isNull);
      expect(await repo.comprovativo('ped1'), isNull);
      expect(await repo.servicoConfirmado('tp1'), isNull);
      expect(servidor.pedidos, isEmpty);
    });

    test('404 nos métodos T? devolve null', () async {
      expect(await repo.profissional('99'), isNull);
      expect(await repo.pedido('99'), isNull);
      expect(await repo.comprovativo('99'), isNull);
    });

    test('pedido(id) converte PedidoJSON e propostas', () async {
      servidor.em('GET /pedidos/1', _pedido);
      final p = (await repo.pedido('1'))!;
      expect(p.id, '1');
      expect(p.estado, EstadoPedido.novo);
      expect(p.quando, isNull);
      expect(p.data, DateTime.utc(2026, 10, 20, 13).toLocal());
      expect(p.numFotos, 1);
      final proposta = p.propostas.single;
      expect(proposta.id, '1');
      expect(proposta.valor, 12500);
      expect(proposta.inclui, ComponenteProposta.values);
      expect(proposta.materialDetalhe, 'sifão e vedante');
      expect(proposta.profissional.nome, 'Joaquim Manuel');
    });

    test('estados do servidor → estados da app', () {
      const casos = {
        'rascunho': EstadoPedido.novo,
        'publicado': EstadoPedido.novo,
        'com_propostas': EstadoPedido.novo,
        'aceite': EstadoPedido.emCurso,
        'a_caminho': EstadoPedido.emCurso,
        'em_curso': EstadoPedido.emCurso,
        'concluido': EstadoPedido.concluido,
        'cancelado': EstadoPedido.cancelado,
      };
      casos.forEach((servidor, app) {
        expect(EstadoPedido.doServidor(servidor), app, reason: servidor);
      });
    });

    test('componentes a zero não entram no "inclui"', () async {
      servidor.em('GET /pedidos/1', {
        ..._pedido,
        'propostas': [
          {
            ..._proposta,
            'componentes': {'mao_de_obra': 8000, 'material': 0},
          },
        ],
      });
      final p = (await repo.pedido('1'))!;
      expect(p.propostas.single.inclui, [ComponenteProposta.maoDeObra]);
    });

    test('cancelarPedido chama POST e avisa', () async {
      var avisos = 0;
      repo.alteracoes.addListener(() => avisos++);
      servidor.em('POST /pedidos/1/cancelar', null);
      await repo.cancelarPedido('1');
      expect(servidor.ultimo.method, 'POST');
      expect(avisos, 1);
    });

    test('cancelar um pedido já fechado → ValidacaoException', () async {
      servidor.em(
        'POST /pedidos/1/cancelar',
        null,
        status: 409,
        detail: 'Já não é possível cancelar este pedido.',
      );
      await expectLater(
        repo.cancelarPedido('1'),
        throwsA(isA<ValidacaoException>()),
      );
    });

    test('aceitarProposta aceita e volta a ler o pedido', () async {
      servidor
        ..em('POST /propostas/1/aceitar', {'ok': true})
        ..em('GET /pedidos/1', {
          ..._pedido,
          'estado': 'aceite',
          'profissional': _joaquim,
          'valor_acordado': 12500,
          'proposta_aceite_id': 1,
        });
      final p = await repo.aceitarProposta('1', '1');
      expect(servidor.pedidos.map((r) => '${r.method} ${r.url.path}'), [
        'POST /api/propostas/1/aceitar',
        'GET /api/pedidos/1',
      ]);
      expect(p.estado, EstadoPedido.emCurso);
      expect(p.valor, 12500);
      expect(p.propostaAceitaId, '1');
      expect(p.profissional!.id, '2');
    });

    test('desfazerAceitacao chama o endpoint do pedido', () async {
      servidor.em('POST /pedidos/1/desfazer-aceitacao', _pedido);
      await repo.desfazerAceitacao('1');
      expect(servidor.ultimo.url.path, '/api/pedidos/1/desfazer-aceitacao');
    });

    test('servicoEmCurso: null quando a API devolve data null', () async {
      servidor.em('GET /pedidos/em-curso', null);
      expect(await repo.servicoEmCurso(), isNull);
      servidor.em('GET /pedidos/em-curso', {..._pedido, 'estado': 'em_curso'});
      expect((await repo.servicoEmCurso())!.estado, EstadoPedido.emCurso);
    });

    test('codigoConfirmacao lê token, código e validade', () async {
      servidor.em('GET /pedidos/1/qr', {
        'pedido_id': 1,
        'token': 'kx_qr_teste',
        'codigo': '482173',
        'valido_ate': '2026-10-20T15:10:00Z',
        'valor_acordado': 12500,
      });
      final c = await repo.codigoConfirmacao('1');
      expect(c.pedidoId, '1');
      expect(c.token, 'kx_qr_teste');
      expect(c.codigo, '482173');
      expect(c.validoAte, DateTime.utc(2026, 10, 20, 15, 10).toLocal());
    });

    test(
      'codigoConfirmacao sem pedido em curso → NaoEncontradoException',
      () async {
        await expectLater(
          repo.codigoConfirmacao('1'),
          throwsA(isA<NaoEncontradoException>()),
        );
      },
    );

    test('reportarProblema envia tipo "outro" e a descrição', () async {
      servidor.em('POST /pedidos/1/reclamacoes', {'id': 9});
      await repo.reportarProblema('1', 'Continua a pingar.');
      expect(servidor.corpo(), {
        'tipo': 'outro',
        'descricao': 'Continua a pingar.',
      });
    });

    test('comprovativo converte ComprovativoJSON', () async {
      servidor.em('GET /pedidos/1/comprovativo', _comprovativo);
      final c = (await repo.comprovativo('1'))!;
      expect(c.referencia, 'KX-2026-000001');
      expect(c.servico, 'Fuga de água na cozinha');
      expect(c.valor, 12500);
      expect(c.pagamento, MeioPagamento.multicaixaExpress);
      expect(c.profissional.nome, 'Joaquim Manuel');
    });

    test('meio de pagamento desconhecido → dinheiro', () {
      expect(
        MeioPagamento.daChave('transferencia'),
        MeioPagamento.transferencia,
      );
      expect(MeioPagamento.daChave('cheque'), MeioPagamento.dinheiro);
      expect(MeioPagamento.daChave(null), MeioPagamento.dinheiro);
    });

    test('enviarAvaliacao manda as chaves das etiquetas', () async {
      servidor.em('POST /pedidos/1/avaliacao', {'id': 1});
      await repo.enviarAvaliacao(
        '1',
        const NovaAvaliacao(
          estrelas: 4,
          etiquetas: [EtiquetaAvaliacao.precoJusto, EtiquetaAvaliacao.rapido],
          comentario: 'Bom trabalho.',
        ),
      );
      expect(servidor.corpo(), {
        'estrelas': 4,
        'etiquetas': ['preco_justo', 'rapido'],
        'comentario': 'Bom trabalho.',
      });
    });

    test('historico pede limit=100 e ordena do mais recente', () async {
      servidor.em('GET /pedidos', [
        {..._pedido, 'id': 1, 'criado_em': '2026-10-01T10:00:00Z'},
        {
          ..._pedido,
          'id': 2,
          'estado': 'concluido',
          'criado_em': '2026-10-19T10:00:00Z',
          'cliente_curto': 'Maria K.',
        },
      ]);
      final lista = await repo.historico();
      expect(servidor.ultimo.url.queryParameters, {'limit': '100'});
      expect(lista.map((p) => p.id), ['2', '1']);
      expect(lista.first.estado, EstadoPedido.concluido);
      expect(lista.first.cliente, 'Maria K.');
    });

    test('resposta que não é lista → ServidorException', () async {
      servidor.em('GET /pedidos', {'erro': 'inesperado'});
      await expectLater(repo.historico(), throwsA(isA<ServidorException>()));
    });

    test(
      'verificarLigacao chama /saude; sem rede lança SemRedeException',
      () async {
        servidor.em('GET /saude', {'ok': true});
        await repo.verificarLigacao();
        final semRede = RestKisaluRepository(
          ApiClient(
            baseUrl: _base,
            cliente: MockClient((_) => throw http.ClientException('x')),
          ),
        );
        await expectLater(
          semRede.verificarLigacao(),
          throwsA(isA<SemRedeException>()),
        );
      },
    );

    test('publicarPedido envia o corpo do contrato e lê a resposta', () async {
      servidor.em('POST /pedidos', {
        'id': 1,
        'estado': 'publicado',
        'pedido': {..._pedido, 'estado': 'publicado', 'propostas': []},
        'profissionais_avisados': 8,
        'categoria_plural': 'canalizadores',
      });
      final quando = DateTime.utc(2026, 10, 21, 9);
      final r = await repo.publicarPedido(
        NovoPedido(
          categoriaId: 'canalizador',
          titulo: 'Fuga de água na cozinha',
          descricao: 'Cano a pingar.',
          zona: 'Talatona',
          pontoReferencia: 'perto da cantina',
          quando: quando,
        ),
      );
      expect(servidor.corpo(), {
        'categoria_chave': 'canalizador',
        'titulo': 'Fuga de água na cozinha',
        'descricao': 'Cano a pingar.',
        'zona': 'Talatona',
        'ponto_referencia': 'perto da cantina',
        'quando': '2026-10-21T09:00:00.000Z',
        'publicar': true,
      });
      expect(r.pedido.id, '1');
      expect(r.profissionaisAvisados, 8);
      expect(r.categoriaPlural, 'canalizadores');
    });
  });

  group('profissional', () {
    test('rascunhoRegistoProfissional deriva de GET /eu', () async {
      servidor.em('GET /eu', {
        ..._eu,
        'nome': 'Joaquim Manuel',
        'profissional': {
          'categorias': ['canalizador', 'eletricista'],
          'anos_experiencia': 10,
          'zona': 'Viana, Luanda',
          'raio_atuacao_km': 12,
          'registo_completo': true,
        },
      });
      final r = (await repo.rascunhoRegistoProfissional())!;
      expect(r.nomeCompleto, 'Joaquim Manuel');
      expect(r.categoriaIds, ['canalizador', 'eletricista']);
      expect(r.anosExperiencia, 10);
      expect(r.zona, 'Viana, Luanda');
      expect(r.raioKm, 12);
    });

    test(
      'conta nova sem nome nem perfil profissional → sem rascunho',
      () async {
        servidor.em('GET /eu', {..._eu, 'nome': null});
        expect(await repo.rascunhoRegistoProfissional(), isNull);
      },
    );

    test(
      'guardarRegistoProfissional envia PUT e passa a profissional',
      () async {
        servidor.em('PUT /profissionais/eu', {
          'perfil_ativo': 'profissional',
          'utilizador': _eu,
        });
        await repo.guardarRegistoProfissional(
          const RegistoProfissional(
            nomeCompleto: 'Joaquim Manuel',
            categoriaIds: ['canalizador'],
            anosExperiencia: 6,
            zona: 'Viana, Luanda',
            raioKm: 10,
          ),
        );
        expect(servidor.ultimo.method, 'PUT');
        expect(servidor.corpo(), {
          'nome_completo': 'Joaquim Manuel',
          'categorias': ['canalizador'],
          'anos_experiencia': 6,
          'zona': 'Viana, Luanda',
          'raio_atuacao_km': 10,
        });
        expect(repo.perfilAtivo, PerfilUtilizador.profissional);
      },
    );

    test('verificação: estado, documento, rosto e envio', () async {
      servidor
        ..em('GET /profissionais/eu/verificacao', {
          'estado': 'rascunho',
          'documento_enviado': 1,
          'rosto_enviado': 0,
          'motivo_rejeicao': null,
        })
        ..em('PUT /profissionais/eu/verificacao/documento', null)
        ..em('PUT /profissionais/eu/verificacao/rosto', null)
        ..em('POST /profissionais/eu/verificacao/enviar', null);
      final v = await repo.verificacaoIdentidade();
      expect(v.documentoEnviado, isTrue);
      expect(v.rostoEnviado, isFalse);
      await repo.adicionarDocumento();
      expect(servidor.ultimo.url.path, endsWith('/verificacao/documento'));
      await repo.adicionarFotoRosto();
      expect(servidor.ultimo.url.path, endsWith('/verificacao/rosto'));
      await repo.enviarParaVerificacao();
      expect(servidor.ultimo.url.path, endsWith('/verificacao/enviar'));
    });

    test('painelProfissional converte o painel e os pedidos perto', () async {
      servidor.em('GET /profissionais/eu/painel', {
        'nome': 'Joaquim Manuel',
        'zona': 'Viana',
        'raio_km': 10,
        'pedidos_novos': 3,
        'rating': 4.8,
        'servicos': 126,
        'disponivel': 1,
        'pedidos': [
          {
            'id': 7,
            'titulo': 'Reparar muro do quintal',
            'descricao': 'Muro rachado.',
            'categoria_chave': 'pedreiro',
            'zona': 'Viana',
            'distancia_km': 1.8,
            'data_pretendida': null,
            'publicado_em': '2026-10-20T14:38:00Z',
            'novo': true,
          },
        ],
      });
      final p = await repo.painelProfissional();
      expect(p.nome, 'Joaquim');
      expect(p.raioKm, 10);
      expect(p.disponivel, isTrue);
      final perto = p.pedidos.single;
      expect(perto.id, '7');
      expect(perto.quando, isNull);
      expect(perto.novo, isTrue);
      expect(perto.distanciaKm, 1.8);
    });

    test('definirDisponibilidade envia {disponivel}', () async {
      servidor.em('PUT /profissionais/eu', null);
      await repo.definirDisponibilidade(false);
      expect(servidor.corpo(), {'disponivel': false});
    });

    test(
      'pedidoPerto lê GET /pedidos/:id (criado_em como publicação)',
      () async {
        servidor.em('GET /pedidos/1', {
          ..._pedido,
          'distancia_km': 2.5,
          'data_pretendida': '2026-10-20T15:00:00Z',
        });
        final p = (await repo.pedidoPerto('1'))!;
        expect(p.distanciaKm, 2.5);
        expect(p.zona, 'Talatona');
        expect(p.quando, DateTime.utc(2026, 10, 20, 15).toLocal());
        expect(p.publicadoEm, DateTime.utc(2026, 10, 20, 13).toLocal());
      },
    );

    test('enviarProposta: tempo de chegada ou hora pedida', () async {
      servidor.em('POST /pedidos/7/propostas', _proposta);
      await repo.enviarProposta(
        const NovaProposta(
          pedidoId: '7',
          maoDeObra: 8000,
          material: 3500,
          deslocacao: 1000,
          chegada: ChegadaProposta.quarentaMinutos,
        ),
      );
      expect(servidor.corpo(), {
        'valor_mao_obra': 8000,
        'valor_material': 3500,
        'valor_deslocacao': 1000,
        'tempo_chegada_min': 40,
      });
      await repo.enviarProposta(
        const NovaProposta(
          pedidoId: '7',
          maoDeObra: 8000,
          material: 0,
          deslocacao: 0,
          chegada: ChegadaProposta.horaPedida,
        ),
      );
      expect(servidor.corpo()['na_hora_pedida'], isTrue);
      expect(servidor.corpo().containsKey('tempo_chegada_min'), isFalse);
    });

    test(
      'enviarProposta para pedido inexistente → NaoEncontradoException',
      () async {
        await expectLater(
          repo.enviarProposta(
            const NovaProposta(
              pedidoId: '99',
              maoDeObra: 1,
              material: 0,
              deslocacao: 0,
              chegada: ChegadaProposta.umaHora,
            ),
          ),
          throwsA(isA<NaoEncontradoException>()),
        );
      },
    );

    test('trabalhoPorConfirmar: objeto ou null', () async {
      servidor.em('GET /pedidos/por-confirmar', null);
      expect(await repo.trabalhoPorConfirmar(), isNull);
      servidor.em('GET /pedidos/por-confirmar', {
        'pedido_id': 1,
        'servico': 'Fuga de água na cozinha',
        'cliente': 'Maria K.',
        'valor': 12500,
      });
      final t = (await repo.trabalhoPorConfirmar())!;
      expect(t.pedidoId, '1');
      expect(t.cliente, 'Maria K.');
      expect(t.valor, 12500);
    });

    test('confirmarServicoComCodigo usa POST /pedidos/confirmar', () async {
      servidor.em('POST /pedidos/confirmar', _comprovativo);
      final s = await repo.confirmarServicoComCodigo('482 173');
      expect(servidor.ultimo.url.path, '/api/pedidos/confirmar');
      expect(servidor.corpo(), {
        'codigo': '482173',
        'metodo_pagamento': 'dinheiro',
      });
      expect(s.pedidoId, '1');
      expect(s.cliente, 'Maria K.');
      expect(s.valor, 12500);
      expect(s.servico, 'Fuga de água na cozinha');
    });

    test('código que não confere → ValidacaoException', () async {
      servidor.em(
        'POST /pedidos/confirmar',
        null,
        status: 400,
        detail: 'O código não está certo.',
      );
      await expectLater(
        repo.confirmarServicoComCodigo('482173'),
        throwsA(isA<ValidacaoException>()),
      );
    });

    test('servicoConfirmado lê o comprovativo', () async {
      servidor.em('GET /pedidos/1/comprovativo', _comprovativo);
      final s = (await repo.servicoConfirmado('1'))!;
      expect(s.data, DateTime.utc(2026, 10, 20, 15, 10).toLocal());
    });
  });

  group('conversas e mapa', () {
    final mensagem = {
      'id': 3,
      'texto': 'Chego às 15h.',
      'foto_url': null,
      'minha': 0,
      'enviada_em': '2026-10-20T13:51:00Z',
      'lida': 0,
    };

    test('conversas aceita interlocutor profissional ou cliente', () async {
      servidor.em('GET /conversas', [
        {
          'id': 1,
          'pedido_id': 1,
          'pedido_titulo': 'Fuga de água na cozinha',
          'categoria_chave': 'canalizador',
          'valor': 12500,
          'nao_lidas': 2,
          'interlocutor': _joaquim,
          'mensagens': [mensagem],
        },
        {
          'id': 2,
          'pedido_id': 1,
          'pedido_titulo': 'Fuga de água na cozinha',
          'categoria_chave': 'canalizador',
          'valor': 12500,
          'nao_lidas': 0,
          'interlocutor': {
            'id': 1,
            'nome': 'Maria K.',
            'foto_url': null,
            'e_cliente': true,
          },
          'mensagens': [],
        },
      ]);
      final lista = await repo.conversas();
      expect(lista.first.interlocutor.nome, 'Joaquim Manuel');
      expect(lista.first.naoLidas, 2);
      expect(lista.first.ultima!.texto, 'Chego às 15h.');
      expect(lista.first.ultima!.minha, isFalse);
      expect(lista.last.interlocutor.nome, 'Maria K.');
      expect(lista.last.interlocutor.rating, 0);
      expect(lista.last.ultima, isNull);
    });

    test('enviarMensagem envia o texto e devolve a mensagem', () async {
      servidor.em('POST /conversas/1/mensagens', {
        ...mensagem,
        'id': 4,
        'texto': 'Obrigada!',
        'minha': true,
        'lida': false,
      });
      final m = await repo.enviarMensagem('1', '  Obrigada!  ');
      expect(servidor.corpo(), {'texto': 'Obrigada!'});
      expect(m.id, '4');
      expect(m.minha, isTrue);
    });

    test(
      'enviarMensagem para conversa inexistente → NaoEncontradoException',
      () async {
        await expectLater(
          repo.enviarMensagem('99', 'Olá'),
          throwsA(isA<NaoEncontradoException>()),
        );
      },
    );

    test('marcarConversaLida chama POST /conversas/:id/lida', () async {
      servidor.em('POST /conversas/1/lida', null);
      await repo.marcarConversaLida('1');
      expect(servidor.ultimo.url.path, '/api/conversas/1/lida');
    });

    test('pinsMapa pede raio_km=5', () async {
      servidor.em('GET /profissionais/mapa', [
        {'x': 0.42, 'y': 0.3, 'profissional': _joaquim},
      ]);
      final pin = (await repo.pinsMapa()).single;
      expect(servidor.ultimo.url.queryParameters, {'raio_km': '5'});
      expect(pin.x, 0.42);
      expect(pin.profissional.id, '2');
    });
  });

  group('só na app', () {
    test('rascunhos não chamam a API', () async {
      expect(await repo.rascunhoAvaliacao('1'), isNull);
      expect(await repo.rascunhoPedido(), isNull);
      expect(await repo.rascunhoProposta('1'), isNull);
      expect(servidor.pedidos, isEmpty);
      expect(repo.modoDemonstracao, isFalse);
    });

    test('rascunho do novo pedido fica no armazenamento local', () async {
      final guardado = ValorEmMemoria();
      final r = RestKisaluRepository(api, rascunhos: guardado);
      await r.guardarRascunhoPedido(
        const NovoPedido(
          categoriaId: 'canalizador',
          titulo: 'Fuga de água',
          descricao: 'Cano a pingar.',
          zona: 'Talatona',
          pontoReferencia: 'perto da cantina',
        ),
      );
      expect(guardado.valor, contains('Fuga de água'));
      final lido = (await r.rascunhoPedido())!;
      expect(lido.titulo, 'Fuga de água');
      expect(lido.pontoReferencia, 'perto da cantina');
      await r.apagarRascunhoPedido();
      expect(await r.rascunhoPedido(), isNull);
      expect(servidor.pedidos, isEmpty);
    });

    test('rascunho ilegível é ignorado', () async {
      final r = RestKisaluRepository(api, rascunhos: ValorEmMemoria('{x'));
      expect(await r.rascunhoPedido(), isNull);
    });
  });

  group('sessão guardada (RF01)', () {
    test('o token fica guardado e terminar sessão apaga-o', () async {
      final tokens = ValorEmMemoria();
      repo = RestKisaluRepository(api, tokens: tokens);
      await entrar();
      expect(tokens.valor, 'tok-abc');
      servidor.em('POST /auth/sair', null);
      await repo.terminarSessao();
      expect(tokens.valor, isNull);
    });

    test('retomarSessao com token válido lê /eu e fica com sessão', () async {
      final r = RestKisaluRepository(api, tokens: ValorEmMemoria('tok-1'));
      servidor.em('GET /eu', {..._eu, 'perfil_ativo': 'profissional'});
      expect(await r.retomarSessao(), isTrue);
      expect(r.temSessao, isTrue);
      expect(r.perfilAtivo, PerfilUtilizador.profissional);
      expect(servidor.ultimo.headers['Authorization'], 'Bearer tok-1');
    });

    test('retomarSessao sem token não chama a API', () async {
      final r = RestKisaluRepository(api, tokens: ValorEmMemoria());
      expect(await r.retomarSessao(), isFalse);
      expect(servidor.pedidos, isEmpty);
    });

    test('retomarSessao com token expirado (401) apaga-o', () async {
      final tokens = ValorEmMemoria('velho');
      final r = RestKisaluRepository(api, tokens: tokens);
      servidor.em('GET /eu', null, status: 401);
      expect(await r.retomarSessao(), isFalse);
      expect(tokens.valor, isNull);
      expect(r.temSessao, isFalse);
    });
  });

  group('Entrega 2b (QA)', () {
    setUp(() async {
      await entrar();
    });

    test('contacto_cliente (profissional escolhido) tem prioridade', () {
      final p = Pedido.fromJson({
        ..._pedido,
        'estado': 'aceite',
        'contacto_cliente': {
          'nome': 'Maria Kiala',
          'telemovel': '+244923000000',
          'morada': 'Rua 21, Casa 14',
          'ponto_referencia': 'Perto da cantina do Sr. Zé',
        },
        'morada': {'bairro': 'Talatona'},
      });
      expect(p.morada, 'Rua 21, Casa 14');
      expect(p.pontoReferencia, 'Perto da cantina do Sr. Zé');
      expect(p.clienteNome, 'Maria Kiala');
      expect(p.clienteTelemovel, '+244923000000');
      expect(p.etapa, EtapaServico.aceite);
    });

    test('PedidoJSON lê avaliado, pode_reclamar, morada e contacto', () {
      final p = Pedido.fromJson({
        ..._pedido,
        'estado': 'a_caminho',
        'avaliado': true,
        'pode_reclamar': true,
        'morada': {'endereco': 'Rua 21', 'ponto_referencia': 'cantina'},
        'cliente': {'nome': 'Maria Kiala', 'telemovel': '+244923000000'},
        'conversa_id': 7,
        'acordo': {'aceite_em': '2026-10-20T14:00:00Z'},
      });
      expect(p.avaliado, isTrue);
      expect(p.podeReclamar, isTrue);
      expect(p.etapa, EtapaServico.aCaminho);
      expect(p.estado, EstadoPedido.emCurso);
      expect(p.morada, 'Rua 21');
      expect(p.pontoReferencia, 'cantina');
      expect(p.clienteTelemovel, '+244923000000');
      expect(p.conversaId, '7');
      expect(p.aceiteEm, isNotNull);
    });

    test('sem pode_reclamar usa a garantia do detalhe', () {
      final p = Pedido.fromJson({
        ..._pedido,
        'estado': 'concluido',
        'garantia': {'ativa': true},
      });
      expect(p.podeReclamar, isTrue);
    });

    test('recusarProposta → POST /propostas/:id/recusar', () async {
      servidor.em('POST /propostas/3/recusar', {'id': 3, 'estado': 'recusada'});
      await repo.recusarProposta('1', '3');
      expect(servidor.ultimo.url.path, '/api/propostas/3/recusar');
    });

    test('editarPedido → PATCH /pedidos/:id no formato da app', () async {
      servidor.em('PATCH /pedidos/1', {..._pedido, 'titulo': 'Fuga maior'});
      final p = await repo.editarPedido(
        '1',
        const NovoPedido(
          categoriaId: 'canalizador',
          titulo: 'Fuga maior',
          descricao: 'Cano a pingar muito.',
          zona: 'Talatona',
          pontoReferencia: 'Portão verde',
        ),
      );
      expect(p.titulo, 'Fuga maior');
      // Só o PATCH: não relê nem cria outro pedido.
      expect(
        servidor.pedidos.where((r) => r.url.path.startsWith('/api/pedidos')),
        hasLength(1),
      );
      final corpo = jsonDecode(servidor.ultimo.body) as Map<String, dynamic>;
      expect(corpo, {
        'categoria_chave': 'canalizador',
        'titulo': 'Fuga maior',
        'descricao': 'Cano a pingar muito.',
        'zona': 'Talatona',
        'ponto_referencia': 'Portão verde',
        'quando': null,
      });
    });

    test('pedirDeNovo cria o rascunho e publicar publica-o', () async {
      servidor
        ..em('POST /pedidos/1/pedir-de-novo', {'id': 9, 'estado': 'rascunho'})
        ..em('GET /pedidos/9', {
          ..._pedido,
          'id': 9,
          'estado': 'rascunho',
          'morada': {'ponto_referencia': 'cantina'},
        });
      final novo = await repo.pedirDeNovo('1');
      expect(novo.rascunhoId, '9');
      expect(novo.titulo, 'Fuga de água na cozinha');
      expect(novo.pontoReferencia, 'cantina');

      servidor
        ..em('PATCH /pedidos/9', {'id': 9})
        ..em('POST /pedidos/9/publicar', {
          'id': 9,
          'estado': 'publicado',
          'profissionais_avisados': 5,
        });
      final publicado = await repo.publicarPedido(novo);
      expect(publicado.profissionaisAvisados, 5);
      expect(
        servidor.pedidos.where((r) => r.url.path == '/api/pedidos'),
        isEmpty,
      );
    });

    test('reportarProblema devolve o contacto do profissional', () async {
      servidor.em('POST /pedidos/1/reclamacoes', {
        'id': 1,
        'estado': 'aberta',
        'mensagem': 'Recebemos o seu problema.',
        'contacto_profissional': {
          'nome': 'Joaquim Manuel',
          'telemovel': '+244923111222',
        },
      });
      final r = await repo.reportarProblema('1', 'A torneira pinga.');
      expect(r.mensagem, 'Recebemos o seu problema.');
      expect(r.contactoNome, 'Joaquim Manuel');
      expect(r.contactoTelemovel, '+244923111222');
    });

    test('reportar fora da garantia (422) → ValidacaoException', () async {
      servidor.em(
        'POST /pedidos/1/reclamacoes',
        null,
        status: 422,
        detail: 'Já passaram 7 dias.',
      );
      await expectLater(
        repo.reportarProblema('1', 'A torneira pinga.'),
        throwsA(
          isA<ValidacaoException>().having(
            (e) => e.mensagem,
            'mensagem',
            'Já passaram 7 dias.',
          ),
        ),
      );
    });

    test('trabalhosPorConfirmar lê a lista', () async {
      servidor.em('GET /pedidos/por-confirmar/lista', [
        {'pedido_id': 1, 'servico': 'Fuga', 'cliente': 'Maria K.', 'valor': 1},
        {'pedido_id': 2, 'servico': 'Muro', 'cliente': 'Rui B.', 'valor': 2},
      ]);
      final lista = await repo.trabalhosPorConfirmar();
      expect(lista.map((t) => t.pedidoId), ['1', '2']);
    });

    test('mudarEtapaServico → PATCH /pedidos/:id/estado', () async {
      servidor.em('PATCH /pedidos/1/estado', {'id': 1, 'estado': 'a_caminho'});
      await repo.mudarEtapaServico('1', EtapaServico.aCaminho);
      expect(jsonDecode(servidor.ultimo.body), {'estado': 'a_caminho'});
    });

    test('notificações: lista, total por ler e marcar lidas', () async {
      servidor.em('GET /notificacoes', {
        'nao_lidas': 1,
        'notificacoes': [
          {
            'id': 1,
            'titulo': 'Nova proposta',
            'corpo': 'Recebeu 1 proposta.',
            'lida': 0,
            'criado_em': '2026-10-20T14:00:00Z',
          },
        ],
      });
      final caixa = await repo.notificacoes();
      expect(caixa.naoLidas, 1);
      expect(caixa.lista.single.lida, isFalse);
      expect(await repo.notificacoesPorLer(), 1);
      expect(servidor.ultimo.url.queryParameters['so_nao_lidas'], 'true');
      servidor.em('POST /notificacoes/lidas', null);
      await repo.marcarNotificacoesLidas();
      expect(servidor.ultimo.url.path, '/api/notificacoes/lidas');
    });

    test('perguntasAjuda lê /ajuda/perguntas', () async {
      servidor.em('GET /ajuda/perguntas', [
        {'id': 1, 'tema': 'pedidos', 'pergunta': 'Como?', 'resposta': 'Assim.'},
      ]);
      final p = await repo.perguntasAjuda();
      expect(p.single.pergunta, 'Como?');
    });

    test('Utilizador lê registo_completo do profissional', () {
      final sem = Utilizador.fromJson({..._eu});
      final com = Utilizador.fromJson({
        ..._eu,
        'profissional': {'registo_completo': 1},
      });
      expect(sem.registoProfissionalCompleto, isFalse);
      expect(com.registoProfissionalCompleto, isTrue);
    });

    test('Conversa sem valor fica null (nunca "0 Kz")', () {
      final c = Conversa.fromJson({
        'id': 1,
        'interlocutor': _joaquim,
        'pedido_titulo': 'Fuga',
        'categoria_chave': 'canalizador',
        'valor': null,
        'mensagens': const [],
      });
      expect(c.valor, isNull);
    });
  });

  group('Matemática (estatística e Monte Carlo)', () {
    test(
      'estatisticasAvaliacoes lê GET /profissionais/:id/estatisticas',
      () async {
        servidor.em('GET /profissionais/2/estatisticas', {
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
        final e = (await repo.estatisticasAvaliacoes('2'))!;
        expect(e.n, 126);
        expect(e.desvioPadrao, 0.6);
        expect(e.ic95!.metodo, 'z');
        expect(e.distribuicao[5], 108);
        expect(e.maiorContagem, 108);
        expect(await repo.estatisticasAvaliacoes('999'), isNull); // 404
      },
    );

    test('PropostaJSON com e sem estimativa_chegada', () {
      final com = Proposta.fromJson({
        ..._proposta,
        'estimativa_chegada': {
          'simulacoes': 10000,
          'media_min': 19,
          'p50_min': 16.6,
          'p90_min': 32.8,
          'prob_cumprir': 0.84,
        },
      });
      expect(com.estimativaChegada!.p50Min, 16.6);
      expect(com.estimativaChegada!.percentagemCumprir, 85);
      final sem = Proposta.fromJson({..._proposta, 'estimativa_chegada': null});
      expect(sem.estimativaChegada, isNull);
    });
  });
}
