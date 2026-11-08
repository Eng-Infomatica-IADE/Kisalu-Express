import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import request from 'supertest';
import { pool } from '../src/config/db';
import { app, auth, login, EMAIL, TEL } from './helpers';

afterAll(() => pool.end());

/**
 * Percurso completo dos User Flows UF1 → UF2 → UF3 do relatório:
 * pedir → comparar e aceitar → alteração de preço → QR → comprovativo → avaliar → reclamar.
 */
describe('Fluxo completo de um serviço', () => {
  let maria: string, joaquim: string, rui: string;
  let pedidoId: number, propostaJoaquim: number, propostaRui: number;

  beforeAll(async () => {
    [maria, joaquim, rui] = await Promise.all([login(EMAIL.maria), login(EMAIL.joaquim), login(EMAIL.rui)]);
  });

  it('UF1 · cliente publica o pedido e os canalizadores perto são avisados', async () => {
    const res = await request(app)
      .post('/api/pedidos')
      .set(auth(maria))
      .send({ categoria_id: 2, morada_id: 1, titulo: 'Torneira a pingar', descricao: 'A torneira da casa de banho não fecha bem.' })
      .expect(201);
    expect(res.body.data.estado).toBe('publicado');
    expect(res.body.data.profissionais_avisados).toBe(3); // Joaquim, Rui e Paulo
    expect(res.body.data.categoria_plural).toBe('canalizadores');
    expect(res.body.data.pedido).toMatchObject({ categoria_chave: 'canalizador', zona: 'Talatona', propostas: [] });
    pedidoId = res.body.data.id;
  });

  it('não aceita pedido agendado sem data', async () => {
    const res = await request(app)
      .post('/api/pedidos')
      .set(auth(maria))
      .send({ categoria_id: 2, morada_id: 1, titulo: 'Teste', descricao: 'Pedido sem data', urgencia: 'agendado' })
      .expect(400);
    expect(res.body.data.detalhes[0].campo).toBe('data_pretendida');
  });

  it('o profissional vê o pedido em "perto de si" sem a morada exata (RNF10)', async () => {
    const lista = await request(app).get('/api/pedidos/proximos').set(auth(joaquim)).expect(200);
    const p = lista.body.data.find((x: any) => x.id === pedidoId);
    expect(p).toBeTruthy();
    expect(p.bairro).toBe('Talatona');
    expect(p.distancia_km).toBeGreaterThan(0);

    const det = await request(app).get(`/api/pedidos/${pedidoId}`).set(auth(joaquim)).expect(200);
    expect(det.body.data.morada.endereco).toBeUndefined();
    expect(det.body.data.cliente.telemovel).toBeUndefined();
  });

  it('RF15 · dois profissionais enviam propostas por componentes', async () => {
    const a = await request(app)
      .post(`/api/pedidos/${pedidoId}/propostas`)
      .set(auth(joaquim))
      .send({ valor_mao_obra: 6000, valor_material: 2500, valor_deslocacao: 1500, tempo_chegada_min: 30 })
      .expect(201);
    expect(a.body.data.valor_total).toBe(10000);
    expect(a.body.data.inclui_descricao).toBe('Mão de obra · material · deslocação');
    expect(a.body.data.componentes).toEqual({ mao_de_obra: 6000, material: 2500, deslocacao: 1500 });
    expect(a.body.data.profissional).toMatchObject({ id: 2, categoria_chave: 'canalizador', verificado: true });
    propostaJoaquim = a.body.data.proposta_id;

    const b = await request(app)
      .post(`/api/pedidos/${pedidoId}/propostas`)
      .set(auth(rui))
      .send({ valor_mao_obra: 7000, tempo_chegada_min: 20 })
      .expect(201);
    propostaRui = b.body.data.proposta_id;

    // Uma proposta por profissional
    await request(app).post(`/api/pedidos/${pedidoId}/propostas`).set(auth(rui)).send({ valor_mao_obra: 5000, tempo_chegada_min: 20 }).expect(409);
  });

  it('RF04 · cliente compara e ordena as propostas', async () => {
    const preco = await request(app).get(`/api/pedidos/${pedidoId}/propostas?ordenar=preco`).set(auth(maria)).expect(200);
    expect(preco.body.data.map((p: any) => p.profissional.nome)).toEqual(['Rui Santos', 'Joaquim Manuel']);
    expect(preco.body.data[1].valor_formatado).toBe('10 000 Kz');

    const aval = await request(app).get(`/api/pedidos/${pedidoId}/propostas?ordenar=avaliacao`).set(auth(maria)).expect(200);
    expect(aval.body.data[0].profissional.nome).toBe('Joaquim Manuel');
    expect(aval.body.data[0].profissional.verificado).toBe(true);
  });

  it('RF05 · aceitar fecha o acordo, recusa a outra proposta e gera QR + conversa', async () => {
    const res = await request(app).post(`/api/propostas/${propostaJoaquim}/aceitar`).set(auth(maria)).expect(200);
    expect(res.body.data.valor_acordado).toBe(10000);
    expect(res.body.data.conversa_id).toBeTypeOf('number');

    const det = await request(app).get(`/api/pedidos/${pedidoId}`).set(auth(maria)).expect(200);
    expect(det.body.data.estado).toBe('aceite');
    expect(det.body.data.acordo.profissional_telemovel).toBe(TEL.joaquim);

    // A proposta do Rui foi recusada e ele não pode aceitar nada
    await request(app).post(`/api/propostas/${propostaRui}/aceitar`).set(auth(maria)).expect(409);

    // Depois de aceite, o profissional escolhido vê a morada exata e o contacto
    const pro = await request(app).get(`/api/pedidos/${pedidoId}`).set(auth(joaquim)).expect(200);
    expect(pro.body.data.morada.ponto_referencia).toBe('Perto da cantina do Sr. Zé');
    expect(pro.body.data.cliente.telemovel).toBe(TEL.maria);
  });

  it('RF09 · chat do pedido com notificação', async () => {
    const conversas = await request(app).get('/api/conversas').set(auth(joaquim)).expect(200);
    const c = conversas.body.data.find((x: any) => x.pedido_id === pedidoId);
    await request(app).post(`/api/conversas/${c.id}/mensagens`).set(auth(joaquim)).field('texto', 'Chego em 30 minutos.').expect(201);
    const msgs = await request(app).get(`/api/conversas/${c.id}/mensagens`).set(auth(maria)).expect(200);
    expect(msgs.body.data.at(-1).texto).toBe('Chego em 30 minutos.');
    // Rui não participa nesta conversa
    await request(app).get(`/api/conversas/${c.id}/mensagens`).set(auth(rui)).expect(404);
  });

  it('RF08 · profissional muda o estado; não pode saltar para concluído', async () => {
    await request(app).patch(`/api/pedidos/${pedidoId}/estado`).set(auth(joaquim)).send({ estado: 'a_caminho' }).expect(200);
    await request(app).patch(`/api/pedidos/${pedidoId}/estado`).set(auth(rui)).send({ estado: 'em_curso' }).expect(403);
    await request(app).patch(`/api/pedidos/${pedidoId}/estado`).set(auth(joaquim)).send({ estado: 'concluido' }).expect(400);
    await request(app).patch(`/api/pedidos/${pedidoId}/estado`).set(auth(joaquim)).send({ estado: 'em_curso' }).expect(200);
  });

  it('O4 · alteração de preço só com aprovação, e bloqueia a confirmação enquanto pendente', async () => {
    const alt = await request(app)
      .post(`/api/pedidos/${pedidoId}/alteracoes-preco`)
      .set(auth(joaquim))
      .send({ valor_novo: 12000, motivo: 'Foi preciso trocar a torneira inteira.' })
      .expect(201);

    const bloqueado = await request(app).post(`/api/pedidos/${pedidoId}/confirmar`).set(auth(joaquim)).send({ codigo: '123456', metodo_pagamento: 'dinheiro' }).expect(409);
    expect(bloqueado.body.data.codigo).toBe('ALTERACAO_PENDENTE');

    await request(app).post(`/api/alteracoes-preco/${alt.body.data.id}/responder`).set(auth(maria)).send({ aprovar: true }).expect(200);
  });

  it('RF10 · QR + código: código errado é recusado; o certo conclui e gera comprovativo', async () => {
    const qr = await request(app).get(`/api/pedidos/${pedidoId}/qr`).set(auth(maria)).expect(200);
    expect(qr.body.data.valor_acordado).toBe(12000);
    // O QR é um texto opaco: não traz o id do pedido nem o código
    expect(qr.body.data.token).toMatch(/^kx_qr_/);
    expect(qr.body.data.token).not.toContain(String(pedidoId));
    expect(qr.body.data.token).not.toContain(qr.body.data.codigo);

    const errado = qr.body.data.codigo === '000000' ? '000001' : '000000';
    await request(app).post(`/api/pedidos/${pedidoId}/confirmar`).set(auth(joaquim)).send({ codigo: errado, metodo_pagamento: 'dinheiro' }).expect(400);

    const ok = await request(app)
      .post(`/api/pedidos/${pedidoId}/confirmar`)
      .set(auth(joaquim))
      .send({ codigo: qr.body.data.codigo, metodo_pagamento: 'multicaixa_express' })
      .expect(200);
    expect(ok.body.data.numero_comprovativo).toMatch(/^KX-\d{4}-\d{6}$/);
    expect(ok.body.data.valor_kz).toBe(12000); // preço combinado = preço pago

    const det = await request(app).get(`/api/pedidos/${pedidoId}`).set(auth(maria)).expect(200);
    expect(det.body.data.estado).toBe('concluido');
    expect(det.body.data.garantia.ativa).toBe(true);
    expect(det.body.data.historico.map((h: any) => h.estado_novo)).toEqual(['publicado', 'com_propostas', 'aceite', 'a_caminho', 'em_curso', 'concluido']);

    const comp = await request(app).get(`/api/pedidos/${pedidoId}/comprovativo`).set(auth(maria)).expect(200);
    expect(comp.body.data.partilha_whatsapp).toContain('wa.me');
  });

  it('RF12 · avaliar atualiza a reputação; só uma vez', async () => {
    const res = await request(app)
      .post(`/api/pedidos/${pedidoId}/avaliacao`)
      .set(auth(maria))
      .send({ estrelas: 4, comentario: 'Bom trabalho.', etiquetas: ['pontual', 'simpatico'] })
      .expect(201);
    // A média é incremental: (4.8 × 126 + 4) / 127 = 4.79 → 4.8
    expect(res.body.data.total_avaliacoes).toBe(127);
    expect(res.body.data.nova_media_profissional).toBe(4.8);
    expect(res.body.data.etiquetas).toEqual(['pontual', 'simpatico']);

    await request(app).post(`/api/pedidos/${pedidoId}/avaliacao`).set(auth(maria)).send({ estrelas: 5 }).expect(409);

    const perfil = await request(app).get('/api/profissionais/2').expect(200);
    expect(perfil.body.data.total_servicos).toBe(127);
    expect(perfil.body.data.verificacao.selo).toBe('Verificado');
  });

  it('RF11 · reportar problema depois de concluir devolve o contacto do profissional', async () => {
    const res = await request(app)
      .post(`/api/pedidos/${pedidoId}/reclamacoes`)
      .set(auth(maria))
      .field('tipo', 'trabalho_mal_feito')
      .field('descricao', 'A torneira voltou a pingar no dia seguinte.')
      .expect(201);
    expect(res.body.data.contacto_profissional.telemovel).toBe(TEL.joaquim);
  });

  it('regras da base de dados: não se avalia um pedido não concluído (trigger → 422)', async () => {
    const novo = await request(app)
      .post('/api/pedidos')
      .set(auth(maria))
      .send({ categoria_id: 2, morada_id: 1, titulo: 'Outro pedido', descricao: 'Ainda sem serviço feito.' })
      .expect(201);
    const pr = await request(app).post(`/api/pedidos/${novo.body.data.id}/propostas`).set(auth(joaquim)).send({ valor_mao_obra: 5000, tempo_chegada_min: 30 }).expect(201);
    await request(app).post(`/api/propostas/${pr.body.data.proposta_id}/aceitar`).set(auth(maria)).expect(200);

    const res = await request(app).post(`/api/pedidos/${novo.body.data.id}/avaliacao`).set(auth(maria)).send({ estrelas: 5 }).expect(422);
    expect(res.body.detail).toContain('serviços confirmados');

    // e o cancelamento antes de começar fica registado
    await request(app).post(`/api/pedidos/${novo.body.data.id}/cancelar`).set(auth(maria)).send({ motivo: 'Já resolvi.' }).expect(200);
    await request(app).get(`/api/pedidos/${novo.body.data.id}/qr`).set(auth(maria)).expect(409);
  });

  it('RM06 · notificações com ação direta', async () => {
    const res = await request(app).get('/api/notificacoes').set(auth(maria)).expect(200);
    const tipos = res.body.data.notificacoes.map((n: any) => n.tipo);
    expect(tipos).toEqual(expect.arrayContaining(['nova_proposta', 'alteracao_preco', 'lembrete_avaliacao', 'nova_mensagem']));
    await request(app).post('/api/notificacoes/lidas').set(auth(maria)).expect(200);
    const depois = await request(app).get('/api/notificacoes').set(auth(maria)).expect(200);
    expect(depois.body.data.nao_lidas).toBe(0);
  });
});
