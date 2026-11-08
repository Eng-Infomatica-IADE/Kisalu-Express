import 'package:flutter_test/flutter_test.dart';
import 'package:kisalu_express/core/utils/k_format.dart';
import 'package:kisalu_express/data/repositories/kisalu_repository.dart';
import 'package:kisalu_express/data/repositories/mock_kisalu_repository.dart';
import 'package:kisalu_express/models/avaliacao.dart';
import 'package:kisalu_express/models/categoria.dart';
import 'package:kisalu_express/models/estado_pedido.dart';
import 'package:kisalu_express/models/filtro_pedidos.dart';
import 'package:kisalu_express/models/nova_proposta.dart';
import 'package:kisalu_express/models/novo_pedido.dart';
import 'package:kisalu_express/models/ordenacao_propostas.dart';
import 'package:kisalu_express/models/registo_profissional.dart';
import 'package:kisalu_express/models/utilizador.dart';

void main() {
  late MockKisaluRepository repo;
  setUp(() => repo = MockKisaluRepository());

  group('dados letra a letra', () {
    test('02 · Início', () async {
      final u = await repo.utilizador();
      expect(u.nome, 'Maria');
      expect(u.zona, 'Talatona, Luanda');
      expect(u.temNovidades, isTrue);
      expect(KFormat.saudacao(repo.agora()), 'Boa tarde');

      final cats = await repo.categorias();
      expect(cats, hasLength(13));
      expect(cats.where((c) => c.emDestaque).map((c) => c.nome), [
        'Eletricista',
        'Canalizador',
        'Mecânico',
        'Pedreiro',
        'Ar condicionado',
        'Cabeleireira',
        'Pintor',
        'Limpeza',
      ]);

      final perto = await repo.profissionaisPertoDeSi();
      expect(perto.map((p) => p.nome), ['Joaquim Manuel', 'Ana Cardoso']);
      final j = perto.first;
      expect(j.nomeCurto, 'Joaquim M.');
      expect(KFormat.km(j.distanciaKm), '1,2 km');
      expect(KFormat.decimal(j.rating), '4,8');
      expect(j.numAvaliacoes, 126);
      expect(j.verificado, isTrue);
    });

    test('03 · Perfil do profissional', () async {
      final j = (await repo.profissional('p1'))!;
      expect(j.categoria, 'Canalizador');
      expect(j.servicosConfirmados, 126);
      expect(KFormat.anos(j.anosExperiencia), '6 anos');
      expect(j.especialidades, [
        'Fugas de água',
        'Esquentadores',
        'Desentupimentos',
        'Loiças sanitárias',
      ]);
      expect(j.trabalhosFeitos.map((t) => t.legenda), [
        'Antes/depois',
        'Esquentador',
        'Loiça sanitária',
      ]);
      expect(j.totalTrabalhosFeitos, 41);
      expect(KFormat.kz(j.maoDeObraDesde), '8.000 Kz');
      expect(j.avaliacoes.first.autor, 'Maria S.');
      expect(
        j.avaliacoes.first.comentario,
        'Chegou a horas e resolveu a fuga em 40 min. Recomendo!',
      );
      expect(j.avaliacoes.last.autor, 'Pedro K.');
    });

    test('04 · Pedido e propostas', () async {
      final agora = repo.agora();
      final p = (await repo.pedido('ped1'))!;
      expect(p.titulo, 'Fuga de água na cozinha');
      expect(
        p.descricao,
        'Cano a pingar debaixo do lava-loiça. Precisa de reparação hoje.',
      );
      expect(p.estado, EstadoPedido.novo);
      expect(p.zona, 'Talatona');
      expect(KFormat.dataHora(p.quando!, agora), 'Hoje, 16:00');
      expect(p.propostas, hasLength(3));

      final ordenadas = OrdenacaoPropostas.preco.ordenar(p.propostas);
      final primeira = ordenadas.first;
      expect(primeira.profissional.nomeCurto, 'Joaquim M.');
      expect(KFormat.kz(primeira.valor), '12.500 Kz');
      expect(
        KFormat.chegadaEm(primeira.chegadaPrevista, agora),
        'chega em 40 min',
      );
      expect(
        KFormat.inclui(primeira.inclui),
        'mão de obra · material · deslocação',
      );
      expect(
        KFormat.inclui(
          primeira.inclui,
          materialDetalhe: primeira.materialDetalhe,
        ),
        'mão de obra · material (sifão e vedante) · deslocação',
      );
      expect(
        KFormat.dataHora(primeira.chegadaPrevista, agora, relogio: false),
        'Hoje, 15h40',
      );
      expect(ordenadas[1].materialIncluido, isFalse);
    });

    test('05 · QR: token opaco, sem id nem código', () async {
      final servico = (await repo.servicoEmCurso())!;
      expect(servico.profissional!.nome, 'Joaquim Manuel');
      expect(servico.profissional!.categoria, 'Canalizador');
      expect(KFormat.kz(servico.valor!), '12.500 Kz');
      final c = await repo.codigoConfirmacao(servico.id);
      expect(KFormat.codigo(c.codigo), '482 173');
      expect(c.token, isNot(contains(servico.id)));
      expect(c.token, isNot(contains(c.codigo)));
      expect(c.token, isNot(contains('kisalu://')));
      expect(c.token.length, greaterThanOrEqualTo(32));
    });

    test('06 · Avaliação', () async {
      final c = (await repo.comprovativo('ped1'))!;
      expect(c.servico, 'Fuga de água na cozinha');
      expect(c.profissional.primeiroNome, 'Joaquim');
      final r = (await repo.rascunhoAvaliacao('ped1'))!;
      expect(r.estrelas, 4);
      expect(EscalaAvaliacao.rotulo(r.estrelas), 'Muito bom');
      expect(r.etiquetas.map((e) => e.rotulo), [
        'Pontual',
        'Preço justo',
        'Trabalho limpo',
      ]);
      expect(r.comentario, 'Resolveu tudo em 40 minutos. Voltaria a chamar.');
      expect(EtiquetaAvaliacao.values.map((e) => e.rotulo), [
        'Pontual',
        'Preço justo',
        'Simpático',
        'Trabalho limpo',
        'Rápido',
      ]);
    });

    test('07 · Histórico', () async {
      final agora = repo.agora();
      final h = await repo.historico();
      String linha(int i) =>
          '${h[i].tituloNaLista} · ${h[i].profissional!.nomeCurto} · '
          '${KFormat.dataCurta(h[i].data, agora)} · ${KFormat.kz(h[i].valor!)}'
          ' · ${h[i].estado.rotulo}';
      expect(
        linha(0),
        'Fuga de água · Joaquim M. · Hoje · 12.500 Kz · Em curso',
      );
      expect(
        linha(1),
        'Tomada sem luz · Carlos D. · 24 set · 6.000 Kz · Concluído',
      );
      expect(
        linha(2),
        'Limpeza de AC · Nuno F. · 12 set · 9.500 Kz · Concluído',
      );
      expect(
        linha(3),
        'Pastilhas de travão · Hélder T. · 3 set · 15.000 Kz · Cancelado',
      );
      expect(linha(4), 'Tranças · Ana C. · 28 ago · 20.000 Kz · Concluído');
      expect(FiltroPedidos.concluidos.aplicar(h), hasLength(3));
      expect(FiltroPedidos.emCurso.aplicar(h), hasLength(1));
      expect(FiltroPedidos.cancelados.aplicar(h), hasLength(1));
      expect(FiltroPedidos.todos.aplicar(h), hasLength(5));
    });

    test('07 · Comprovativo', () async {
      final c = (await repo.comprovativo('ped2'))!;
      expect(c.referencia, startsWith('KX-'));
      expect(KFormat.kz(c.valor), '6.000 Kz');
      expect(await repo.comprovativo('ped4'), isNull);
    });

    test('10 · Rascunho', () async {
      final r = (await repo.rascunhoPedido())!;
      expect(r.titulo, 'Fuga de água na cozinha');
      expect(
        '${r.zona} · ${r.pontoReferencia}',
        'Talatona · perto da cantina do Sr. Zé',
      );
      expect(
        KFormat.quandoPedido(r.quando, repo.agora()),
        'Hoje, o mais cedo possível',
      );
      expect(r.numFotos, 1);
    });

    test('01 · Telemóvel predefinido', () async {
      expect(await repo.telemovelPredefinido(), '+244 923 000 000');
    });
  });

  group('ordenação das propostas', () {
    test('preço, avaliação e chegada', () async {
      final props = (await repo.pedido('ped1'))!.propostas;
      expect(OrdenacaoPropostas.preco.ordenar(props).map((p) => p.valor), [
        12500,
        15000,
        18500,
      ]);
      expect(
        OrdenacaoPropostas.avaliacao
            .ordenar(props)
            .map((p) => p.profissional.rating),
        [4.9, 4.8, 4.6],
      );
      expect(
        OrdenacaoPropostas.chegada
            .ordenar(props)
            .map((p) => p.profissional.nomeCurto),
        ['Paulo N.', 'Joaquim M.', 'Rui S.'],
      );
      expect(OrdenacaoPropostas.values.map((o) => o.rotulo), [
        'Preço ↑',
        'Avaliação',
        'Chegada',
      ]);
    });
  });

  group('não existe: null, não exceção', () {
    test('ids desconhecidos', () async {
      expect(await repo.profissional('zzz'), isNull);
      expect(await repo.pedido('zzz'), isNull);
      expect(await repo.comprovativo('zzz'), isNull);
      expect(await repo.rascunhoAvaliacao('zzz'), isNull);
    });
  });

  group('escritas simuladas', () {
    test('aceitar proposta leva o pedido a em curso e ao QR', () async {
      final r = MockKisaluRepository(comServicoEmCurso: false);
      expect(await r.servicoEmCurso(), isNull);
      final aceite = await r.aceitarProposta('ped1', 'pr2');
      expect(aceite.estado, EstadoPedido.emCurso);
      expect(aceite.profissional!.nome, 'Rui Santos');
      expect(aceite.valor, 15000);
      expect((await r.servicoEmCurso())!.id, 'ped1');
      expect((await r.pedido('ped1'))!.estado, EstadoPedido.emCurso);
      expect((await r.historico()).first.valor, 15000);
    });

    test('aceitar proposta inexistente ou repetida falha com a mensagem', () {
      expect(
        repo.aceitarProposta('ped1', 'xx'),
        throwsA(
          isA<ValidacaoException>().having(
            (e) => e.mensagem,
            'mensagem',
            'Esta proposta já não está disponível. Veja as outras propostas.',
          ),
        ),
      );
      expect(
        repo.aceitarProposta('zzz', 'pr1'),
        throwsA(isA<NaoEncontradoException>()),
      );
    });

    test('desfazer restaura o estado anterior', () async {
      final r = MockKisaluRepository(comServicoEmCurso: false);
      await r.aceitarProposta('ped1', 'pr1');
      await r.desfazerAceitacao('ped1');
      expect((await r.pedido('ped1'))!.estado, EstadoPedido.novo);
      expect(await r.servicoEmCurso(), isNull);
      expect(
        r.desfazerAceitacao('ped1'),
        throwsA(
          isA<ValidacaoException>().having(
            (e) => e.mensagem,
            'mensagem',
            'Já não é possível desfazer. Veja o estado em Pedidos.',
          ),
        ),
      );
    });

    test('cancelar pedido', () async {
      await repo.cancelarPedido('ped1');
      expect((await repo.pedido('ped1'))!.estado, EstadoPedido.cancelado);
      expect(
        repo.cancelarPedido('ped2'),
        throwsA(
          isA<ValidacaoException>().having(
            (e) => e.mensagem,
            'mensagem',
            'Já não é possível cancelar este pedido.',
          ),
        ),
      );
    });

    test('enviar avaliação só uma vez', () async {
      const nova = NovaAvaliacao(estrelas: 5);
      await repo.enviarAvaliacao('ped1', nova);
      expect(repo.avaliacoesEnviadas['ped1']!.estrelas, 5);
      expect(
        repo.enviarAvaliacao('ped1', nova),
        throwsA(
          isA<ValidacaoException>().having(
            (e) => e.mensagem,
            'mensagem',
            'Este serviço já foi avaliado.',
          ),
        ),
      );
      expect(
        repo.enviarAvaliacao('ped4', nova),
        throwsA(isA<NaoEncontradoException>()),
      );
    });

    test('reportar problema', () async {
      await repo.reportarProblema('ped1', 'A fuga voltou no dia seguinte.');
      expect(repo.reportes.single.pedidoId, 'ped1');
      expect(
        repo.reportarProblema('zzz', 'x'),
        throwsA(isA<NaoEncontradoException>()),
      );
    });

    test('código SMS: 000000 falha, o resto passa', () async {
      await repo.pedirCodigoSms('+244923000000', PerfilUtilizador.cliente);
      expect(await repo.validarCodigoSms('+244923000000', '123456'), isFalse);
      expect(
        repo.validarCodigoSms('+244923000000', '000000'),
        throwsA(isA<ValidacaoException>()),
      );
    });

    test('só o profissional que cria conta segue para o registo', () async {
      await repo.pedirCodigoSms('+244923000002', PerfilUtilizador.profissional);
      expect(await repo.validarCodigoSms('+244923000002', '123456'), isFalse);
      await repo.pedirCodigoSms(
        '+244923000002',
        PerfilUtilizador.profissional,
        criarConta: true,
      );
      expect(await repo.validarCodigoSms('+244923000002', '123456'), isTrue);
    });
  });

  group('ecrã 10: rede', () {
    const novo = NovoPedido(
      categoriaId: CategoriaId.canalizador,
      titulo: 'Fuga de água na cozinha',
      descricao: 'Cano a pingar debaixo do lava-loiça.',
      zona: 'Talatona',
      pontoReferencia: 'perto da cantina do Sr. Zé',
    );

    test('por omissão está sem rede (estado do Figma)', () {
      expect(repo.verificarLigacao(), throwsA(isA<SemRedeException>()));
      expect(repo.publicarPedido(novo), throwsA(isA<SemRedeException>()));
    });

    test('com rede publica e avisa 8 canalizadores', () async {
      repo.semRede = false;
      await repo.verificarLigacao();
      final r = await repo.publicarPedido(novo);
      expect(r.pedido.id, 'ped1');
      expect(r.profissionaisAvisados, 8);
      expect(r.categoriaPlural, 'canalizadores');
    });
  });

  test('mensagens das exceções vêm do catálogo', () {
    expect(
      const SemRedeException().mensagem,
      'Sem ligação. Confirme a sua rede e tente outra vez.',
    );
    expect(
      const SessaoExpiradaException().mensagem,
      'A sua sessão terminou. Entre outra vez com o seu telemóvel.',
    );
    expect(
      const SemPermissaoException().mensagem,
      'Não tem acesso a esta informação.',
    );
    expect(
      const NaoEncontradoException().mensagem,
      'Não encontrámos o que procura.',
    );
    expect(
      const ServidorException().mensagem,
      'Algo correu mal do nosso lado. Tente outra vez daqui a pouco.',
    );
  });

  test('a repositório trocável: tipo do contrato', () {
    expect(repo, isA<KisaluRepository>());
  });

  group('perfil ativo e sessão (ecrãs 11 e 20)', () {
    test('arranca como cliente e avisa quando muda', () async {
      expect(repo.perfilAtivo, PerfilUtilizador.cliente);
      var avisos = 0;
      repo.alteracoes.addListener(() => avisos++);
      await repo.mudarPerfil(PerfilUtilizador.profissional);
      expect(repo.perfilAtivo, PerfilUtilizador.profissional);
      expect(avisos, 1);
      await repo.mudarPerfil(PerfilUtilizador.profissional); // sem mudança
      expect(avisos, 1);
    });

    test('o utilizador segue o perfil ativo', () async {
      expect((await repo.utilizador()).nomeCompleto, 'Maria Kiala');
      await repo.mudarPerfil(PerfilUtilizador.profissional);
      expect((await repo.utilizador()).nomeCompleto, 'Joaquim Manuel');
    });

    test('o histórico muda para os trabalhos do profissional', () async {
      expect((await repo.historico()).first.id, 'ped1');
      await repo.mudarPerfil(PerfilUtilizador.profissional);
      final trabalhos = await repo.historico();
      expect(trabalhos.map((p) => p.id), ['tp1', 'tp2', 'tp3', 'tp4']);
      expect(trabalhos.every((p) => p.cliente != null), isTrue);
      expect((await repo.pedido('tp1'))!.cliente, 'Maria K.');
    });

    test('o código SMS pendente guarda número, perfil e criar conta', () async {
      final omissao = await repo.codigoSmsPendente();
      expect(omissao.telemovel, '+244923000000');
      expect(omissao.criarConta, isFalse);
      await repo.pedirCodigoSms(
        '+244912345678',
        PerfilUtilizador.profissional,
        criarConta: true,
      );
      final pendente = await repo.codigoSmsPendente();
      expect(pendente.telemovel, '+244912345678');
      expect(pendente.perfil, PerfilUtilizador.profissional);
      expect(pendente.criarConta, isTrue);
      expect(await repo.codigoSmsPredefinido(), '48217');
    });
  });

  group('registo e verificação do profissional (12 e 13)', () {
    test('rascunho do Figma', () async {
      final r = (await repo.rascunhoRegistoProfissional())!;
      expect(r.nomeCompleto, 'Joaquim Manuel');
      expect(r.categoriaIds, [CategoriaId.canalizador, CategoriaId.pedreiro]);
      expect(r.anosExperiencia, 10);
      expect(r.zona, 'Viana, Luanda');
      expect(r.raioKm, 10);
    });

    test('guardar o registo passa a sessão a profissional', () async {
      final r = (await repo.rascunhoRegistoProfissional())!;
      await repo.guardarRegistoProfissional(r);
      expect(repo.perfilAtivo, PerfilUtilizador.profissional);
    });

    test('registo sem serviços é recusado', () async {
      expect(
        repo.guardarRegistoProfissional(
          const RegistoProfissional(
            nomeCompleto: 'Joaquim Manuel',
            categoriaIds: [],
            anosExperiencia: 10,
            zona: 'Viana',
            raioKm: 10,
          ),
        ),
        throwsA(isA<ValidacaoException>()),
      );
    });

    test('documento enviado, rosto em falta, e só envia com os dois', () async {
      final v = await repo.verificacaoIdentidade();
      expect(v.documentoEnviado, isTrue);
      expect(v.rostoEnviado, isFalse);
      expect(repo.enviarParaVerificacao(), throwsA(isA<ValidacaoException>()));
      await repo.adicionarFotoRosto();
      expect((await repo.verificacaoIdentidade()).completa, isTrue);
      await repo.enviarParaVerificacao();
      await repo.adicionarDocumento();
      expect((await repo.verificacaoIdentidade()).documentoEnviado, isTrue);
    });
  });

  group('ecrãs 14 e 15: lado do profissional', () {
    test('painel do Figma e interruptor em memória', () async {
      final p = await repo.painelProfissional();
      expect(p.nome, 'Joaquim');
      expect(p.zona, 'Viana');
      expect(p.raioKm, 10);
      expect(p.pedidosNovos, 3);
      expect(p.rating, 4.8);
      expect(p.servicos, 126);
      expect(p.disponivel, isTrue);
      expect(p.pedidos.map((x) => x.titulo), [
        'Fuga de água na cozinha',
        'Reparar muro do quintal',
      ]);
      await repo.definirDisponibilidade(false);
      expect((await repo.painelProfissional()).disponivel, isFalse);
    });

    test(
      'o pedido do profissional não tem morada nem contacto (RNF10)',
      () async {
        final p = (await repo.pedidoPerto('pp1'))!;
        expect(p.zona, 'Talatona');
        expect(p.distanciaKm, 3.4);
        expect(p.descricao, contains('lava-loiça'));
        expect(await repo.pedidoPerto('zzz'), isNull);
      },
    );

    test('rascunho e envio da proposta', () async {
      final r = (await repo.rascunhoProposta('pp1'))!;
      expect(r.valorFechado, 12500);
      expect(await repo.rascunhoProposta('pp2'), isNull);
      await repo.enviarProposta(r);
      expect(repo.propostasEnviadas, hasLength(1));
      expect(
        repo.enviarProposta(
          const NovaProposta(
            pedidoId: 'zzz',
            maoDeObra: 1000,
            material: 0,
            deslocacao: 0,
            chegada: ChegadaProposta.umaHora,
          ),
        ),
        throwsA(isA<NaoEncontradoException>()),
      );
      expect(
        repo.enviarProposta(
          const NovaProposta(
            pedidoId: 'pp1',
            maoDeObra: 0,
            material: 0,
            deslocacao: 0,
            chegada: ChegadaProposta.umaHora,
          ),
        ),
        throwsA(isA<ValidacaoException>()),
      );
    });
  });

  group('ecrãs 16 e 17: confirmar o serviço', () {
    test('qualquer código de 6 dígitos confirma, exceto 000000', () async {
      expect(await repo.codigoClientePredefinido(), '482173');
      final s = await repo.confirmarServicoComCodigo('482 173');
      expect(s.pedidoId, 'tp1');
      expect(s.servico, 'Fuga de água na cozinha');
      expect(s.cliente, 'Maria K.');
      expect(s.valor, 12500);
      expect(
        repo.confirmarServicoComCodigo('000000'),
        throwsA(isA<ValidacaoException>()),
      );
      expect(
        repo.confirmarServicoComCodigo('12345'),
        throwsA(isA<ValidacaoException>()),
      );
      expect(
        repo.confirmarServicoComCodigo('12a456'),
        throwsA(isA<ValidacaoException>()),
      );
    });

    test('confirmar conclui o trabalho do profissional e avisa', () async {
      await repo.mudarPerfil(PerfilUtilizador.profissional);
      var avisos = 0;
      repo.alteracoes.addListener(() => avisos++);
      await repo.confirmarServicoComCodigo('482173');
      expect(avisos, 1);
      expect((await repo.historico()).first.estado, EstadoPedido.concluido);
    });

    test('o serviço confirmado tp1 existe sempre; outros não', () async {
      expect((await repo.servicoConfirmado('tp1'))!.valor, 12500);
      expect(await repo.servicoConfirmado('zzz'), isNull);
    });
  });

  group('ecrãs 18 e 19: conversas', () {
    test('3 conversas, a mais recente primeiro', () async {
      final c = await repo.conversas();
      expect(c.map((x) => x.id), ['c1', 'c2', 'c3']);
      expect(c.first.naoLidas, 2);
      expect(c.first.ultima!.texto, 'Chego às 15h40, como combinado.');
    });

    test('conversa com mensagens e contexto do pedido', () async {
      final c = (await repo.conversa('c1'))!;
      expect(c.pedidoTitulo, 'Fuga de água na cozinha');
      expect(c.valor, 12500);
      expect(c.mensagens, hasLength(3));
      expect(await repo.conversa('zzz'), isNull);
    });

    test('enviar acrescenta em memória e avisa', () async {
      var avisos = 0;
      repo.alteracoes.addListener(() => avisos++);
      final m = await repo.enviarMensagem('c1', '  Obrigada!  ');
      expect(m.texto, 'Obrigada!');
      expect(m.minha, isTrue);
      expect((await repo.conversa('c1'))!.mensagens.last.texto, 'Obrigada!');
      expect(avisos, 1);
    });

    test('vazia, longa ou para uma conversa inexistente falha', () async {
      expect(
        repo.enviarMensagem('c1', '   '),
        throwsA(isA<ValidacaoException>()),
      );
      expect(
        repo.enviarMensagem('c1', 'a' * 1001),
        throwsA(isA<ValidacaoException>()),
      );
      await repo.enviarMensagem('c1', 'a' * 1000);
      expect(
        repo.enviarMensagem('zzz', 'Olá'),
        throwsA(isA<NaoEncontradoException>()),
      );
    });

    test('marcar como lida zera o contador', () async {
      await repo.marcarConversaLida('c1');
      expect((await repo.conversa('c1'))!.naoLidas, 0);
      await repo.marcarConversaLida('zzz'); // inofensivo
    });
  });

  group('ecrã 22: mapa', () {
    test('4 pins com o Joaquim primeiro, todos dentro do mapa', () async {
      final pins = await repo.pinsMapa();
      expect(pins, hasLength(4));
      expect(pins.first.profissional.nome, 'Joaquim Manuel');
      expect(
        pins.every((p) => p.x > 0 && p.x < 1 && p.y > 0 && p.y < 1),
        isTrue,
      );
    });
  });
}
