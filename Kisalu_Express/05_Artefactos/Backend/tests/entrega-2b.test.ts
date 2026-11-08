import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import request from 'supertest';
import sharp from 'sharp';
import fs from 'node:fs';
import { pool } from '../src/config/db';
import { app, auth, entrarPorSms, login, EMAIL } from './helpers';

afterAll(() => pool.end());

/*
 * Endpoints que a app passa a usar na Entrega 2b e correções do relatório de QA.
 * Usa o Paulo Neto (canalizador, id 5) para não mexer nos números do Joaquim,
 * que outros testes confirmam.
 */
const PAULO = 'paulo@exemplo.com';

/** Cliente novo só para estes testes (não mexe nas moradas nem nas notificações da Maria) */
async function clienteNovo(telemovel: string, nome: string) {
  return (await entrarPorSms(telemovel, 'cliente', { nome })).token;
}
const imagem = () => sharp({ create: { width: 800, height: 600, channels: 3, background: '#2E7D32' } }).jpeg().toBuffer();

async function pedidoAceite(maria: string, paulo: string, titulo: string) {
  const p = await request(app)
    .post('/api/pedidos')
    .set(auth(maria))
    .send({ categoria_chave: 'canalizador', titulo, descricao: 'Pinga água debaixo do lava-loiça.', zona: 'Talatona', ponto_referencia: 'Perto da cantina do Sr. Zé' })
    .expect(201);
  const pr = await request(app).post(`/api/pedidos/${p.body.data.id}/propostas`).set(auth(paulo)).send({ valor_mao_obra: 7000, tempo_chegada_min: 30 }).expect(201);
  await request(app).post(`/api/propostas/${pr.body.data.id}/aceitar`).set(auth(maria)).expect(200);
  return p.body.data.id as number;
}

describe('QA-03/QA-05 · confirmar com dois serviços ativos', () => {
  let maria: string, paulo: string, a: number, b: number;

  beforeAll(async () => {
    [maria, paulo] = await Promise.all([clienteNovo('+244923444101', 'Helena Costa'), login(PAULO)]);
    a = await pedidoAceite(maria, paulo, 'Torneira da cozinha');
    b = await pedidoAceite(maria, paulo, 'Autoclismo a pingar');
  });

  it('lista todos os trabalhos por confirmar e mantém o singular', async () => {
    const lista = await request(app).get('/api/pedidos/por-confirmar/lista').set(auth(paulo)).expect(200);
    const ids = lista.body.data.map((t: any) => t.pedido_id);
    expect(ids).toEqual(expect.arrayContaining([a, b]));
    expect(lista.body.data.find((t: any) => t.pedido_id === a)).toEqual({ pedido_id: a, servico: 'Torneira da cozinha', cliente: 'Helena C.', valor: 7000 });

    const um = await request(app).get('/api/pedidos/por-confirmar').set(auth(paulo)).expect(200);
    expect(ids).toContain(um.body.data.pedido_id);

    const emCurso = await request(app).get('/api/pedidos/em-curso/lista').set(auth(maria)).expect(200);
    expect(emCurso.body.data.map((p: any) => p.id)).toEqual(expect.arrayContaining([a, b]));
  });

  it('o código do primeiro pedido confirma o primeiro, mesmo sendo o segundo o mais recente', async () => {
    const qrA = await request(app).get(`/api/pedidos/${a}/qr`).set(auth(maria)).expect(200);
    const qrB = await request(app).get(`/api/pedidos/${b}/qr`).set(auth(maria)).expect(200);
    expect(qrA.body.data.codigo).not.toBe(qrB.body.data.codigo);

    // Código errado: conta e diz quantas tentativas restam
    const errado = ['000000', '000001', '000002'].find((c) => c !== qrA.body.data.codigo && c !== qrB.body.data.codigo)!;
    const e = await request(app).post('/api/pedidos/confirmar').set(auth(paulo)).send({ codigo: errado }).expect(400);
    expect(e.body.data.codigo).toBe('CODIGO_ERRADO');
    expect(e.body.detail).toContain('Restam 4 tentativas');

    // Aceita o código com espaço ("482 173")
    const codigoA = `${qrA.body.data.codigo.slice(0, 3)} ${qrA.body.data.codigo.slice(3)}`;
    const ok = await request(app).post('/api/pedidos/confirmar').set(auth(paulo)).send({ codigo: codigoA, metodo_pagamento: 'dinheiro' }).expect(200);
    expect(ok.body.data).toMatchObject({ pedido_id: a, titulo: 'Torneira da cozinha', valor_kz: 7000, metodo_confirmacao: 'codigo' });

    const detB = await request(app).get(`/api/pedidos/${b}`).set(auth(maria)).expect(200);
    expect(detB.body.data.estado).toBe('aceite');

    // O segundo confirma-se lendo o QR
    const okB = await request(app).post('/api/pedidos/confirmar').set(auth(paulo)).send({ token_qr: qrB.body.data.token }).expect(200);
    expect(okB.body.data).toMatchObject({ pedido_id: b, metodo_confirmacao: 'qr' });

    const lista = await request(app).get('/api/pedidos/por-confirmar/lista').set(auth(paulo)).expect(200);
    expect(lista.body.data.map((t: any) => t.pedido_id)).not.toContain(a);
    await request(app).post('/api/pedidos/confirmar').set(auth(paulo)).send({ codigo: codigoA }).expect(404);
  });

  it('com o mesmo código em dois pedidos (CODIGO_QR_FIXO_DEV), ganha o QR aberto mais recentemente', async () => {
    const c = await pedidoAceite(maria, paulo, 'Esquentador sem chama');
    const d = await pedidoAceite(maria, paulo, 'Chuveiro entupido');
    await pool.query(`UPDATE confirmacao_servico SET codigo_numerico = '482173' WHERE pedido_id IN (?)`, [[c, d]]);

    await request(app).get(`/api/pedidos/${d}/qr`).set(auth(maria)).expect(200);
    await new Promise((r) => setTimeout(r, 20));
    await request(app).get(`/api/pedidos/${c}/qr`).set(auth(maria)).expect(200);

    const ok = await request(app).post('/api/pedidos/confirmar').set(auth(paulo)).send({ codigo: '482173' }).expect(200);
    expect(ok.body.data.pedido_id).toBe(c);
    const ok2 = await request(app).post('/api/pedidos/confirmar').set(auth(paulo)).send({ codigo: '482173' }).expect(200);
    expect(ok2.body.data.pedido_id).toBe(d);
  });

  it('valida o corpo: é preciso o código ou o QR', async () => {
    const r = await request(app).post('/api/pedidos/confirmar').set(auth(paulo)).send({}).expect(400);
    expect(r.body.detail).toBe('Escreva o código que o cliente lhe disse.');
    const curto = await request(app).post('/api/pedidos/confirmar').set(auth(paulo)).send({ codigo: '4821' }).expect(400);
    expect(curto.body.detail).toBe('Faltam 2 números. O código tem 6 dígitos.');
    await request(app).post('/api/pedidos/confirmar').set(auth(maria)).send({ codigo: '482173' }).expect(403);
  });
});

describe('QA-07/QA-08 · telemóvel angolano e mensagens de erro', () => {
  const pedir = (telemovel: unknown) => request(app).post('/api/auth/sms/pedir').send({ telemovel, perfil: 'cliente' });

  it('recusa números que não são angolanos, com a mensagem do catálogo', async () => {
    const casos: [unknown, string][] = [
      [undefined, 'Escreva o seu número de telemóvel.'],
      ['', 'Escreva o seu número de telemóvel.'],
      ['92345', 'Faltam 4 números. Um número angolano tem 9 dígitos.'],
      ['92345678', 'Falta 1 número. Um número angolano tem 9 dígitos.'],
      ['9234567890', 'Tem 1 número a mais. Um número angolano tem 9 dígitos.'],
      ['823456789', 'O número começa por 9. Exemplo: 923 456 789.'],
      ['92a456789', 'Use só números. Exemplo: 923 456 789.'],
      ['+351912345678', 'Use um número angolano (+244). Exemplo: 923 456 789.'],
    ];
    for (const [tel, msg] of casos) {
      const r = await pedir(tel).expect(400);
      expect(r.body.detail).toBe(msg);
      expect(r.body.data).toMatchObject({ codigo: 'DADOS_INVALIDOS', detalhes: [{ campo: 'telemovel', mensagem: msg }] });
    }
  });

  it('aceita espaços e os indicativos +244, 00244 e 244', async () => {
    const r = await pedir('00244 923 222 001').expect(200);
    expect(r.body.data.mensagem).toContain('+244 923 222 001');
  });

  it('o detail traz o primeiro problema em português', async () => {
    const maria = await login(EMAIL.maria);
    const r = await request(app).post('/api/pedidos').set(auth(maria)).send({ categoria_chave: 'canalizador', zona: 'Talatona', descricao: 'Cano a pingar.' }).expect(400);
    expect(r.body.detail).toBe('Dê um título curto ao pedido. Exemplo: Fuga de água na cozinha.');
    expect(r.body.data.detalhes[0].campo).toBe('titulo');

    const e = await request(app).post('/api/pedidos/1/avaliacao').set(auth(maria)).send({ estrelas: 7 }).expect(400);
    expect(e.body.detail).toBe('Escolha de 1 a 5 estrelas.');
  });
});

describe('Endpoints usados na Entrega 2b', () => {
  let maria: string, paulo: string, rui: string, admin: string;

  beforeAll(async () => {
    [maria, paulo, rui, admin] = await Promise.all([
      clienteNovo('+244923444102', 'Sandra Lopes'), login(PAULO), login(EMAIL.rui), login(EMAIL.admin),
    ]);
  });

  it('editar, recusar, aceitar, estados, contacto do cliente, confirmar, reclamar e pedir de novo', async () => {
    const novo = await request(app)
      .post('/api/pedidos')
      .set(auth(maria))
      .send({ categoria_chave: 'canalizador', titulo: 'Sifão partido', descricao: 'O sifão da casa de banho rachou.', zona: 'Talatona', ponto_referencia: 'Portão verde' })
      .expect(201);
    const id = novo.body.data.id;
    expect(novo.body.data.pedido).toMatchObject({ avaliado: false, pode_reclamar: false });

    // PATCH no formato da app; devolve o PedidoJSON
    const quando = new Date(Date.now() + 2 * 864e5).toISOString();
    const ed = await request(app)
      .patch(`/api/pedidos/${id}`)
      .set(auth(maria))
      .send({ titulo: 'Sifão e torneira', descricao: 'O sifão rachou e a torneira pinga.', ponto_referencia: 'Portão verde, casa 3', quando })
      .expect(200);
    expect(ed.body.data).toMatchObject({ id, titulo: 'Sifão e torneira', categoria_chave: 'canalizador', zona: 'Talatona' });
    expect(Math.abs(new Date(ed.body.data.data_pretendida).getTime() - new Date(quando).getTime())).toBeLessThan(1000);
    await request(app).patch(`/api/pedidos/${id}`).set(auth(maria)).send({ quando: null }).expect(200);

    const pPaulo = await request(app).post(`/api/pedidos/${id}/propostas`).set(auth(paulo)).send({ valor_mao_obra: 6000, tempo_chegada_min: 20 }).expect(201);
    const pRui = await request(app).post(`/api/pedidos/${id}/propostas`).set(auth(rui)).send({ valor_mao_obra: 9000, tempo_chegada_min: 20 }).expect(201);

    // Recusar uma proposta
    const rec = await request(app).post(`/api/propostas/${pRui.body.data.id}/recusar`).set(auth(maria)).expect(200);
    expect(rec.body.data).toEqual({ id: pRui.body.data.id, estado: 'recusada' });
    await request(app).post(`/api/propostas/${pRui.body.data.id}/recusar`).set(auth(maria)).expect(409);

    await request(app).post(`/api/propostas/${pPaulo.body.data.id}/aceitar`).set(auth(maria)).expect(200);

    // Com proposta aceite já não se edita
    const bloq = await request(app).patch(`/api/pedidos/${id}`).set(auth(maria)).send({ titulo: 'Outro título' }).expect(409);
    expect(bloq.body.data.codigo).toBe('PEDIDO_NAO_EDITAVEL');

    // RNF10: o profissional escolhido vê a morada, o ponto de referência e o telemóvel
    const det = await request(app).get(`/api/pedidos/${id}`).set(auth(paulo)).expect(200);
    expect(det.body.data.contacto_cliente).toMatchObject({
      nome: 'Sandra Lopes', telemovel: '+244923444102', ponto_referencia: 'Portão verde, casa 3', zona: 'Talatona',
    });
    expect(det.body.data).toMatchObject({ avaliado: false, pode_reclamar: true });
    // Quem não foi escolhido não vê contactos
    const detRui = await request(app).get(`/api/pedidos/${id}`).set(auth(rui)).expect(200);
    expect(detRui.body.data.contacto_cliente).toBeNull();
    expect(detRui.body.data.cliente.telemovel).toBeUndefined();

    // Estados do profissional
    const est = await request(app).patch(`/api/pedidos/${id}/estado`).set(auth(paulo)).send({ estado: 'a_caminho' }).expect(200);
    expect(est.body.data).toEqual({ id, estado: 'a_caminho' });
    await request(app).patch(`/api/pedidos/${id}/estado`).set(auth(paulo)).send({ estado: 'em_curso' }).expect(200);

    const qr = await request(app).get(`/api/pedidos/${id}/qr`).set(auth(maria)).expect(200);
    await request(app).post('/api/pedidos/confirmar').set(auth(paulo)).send({ codigo: qr.body.data.codigo }).expect(200);

    // Reclamar com foto: devolve o contacto do profissional; a foto não é pública
    const recl = await request(app)
      .post(`/api/pedidos/${id}/reclamacoes`)
      .set(auth(maria))
      .field('tipo', 'trabalho_mal_feito')
      .field('descricao', 'A torneira voltou a pingar no dia seguinte.')
      .attach('foto', await imagem(), 'torneira.jpg')
      .expect(201);
    expect(recl.body.data).toMatchObject({ estado: 'aberta', contacto_profissional: { nome: 'Paulo Neto', telemovel: '+244923000005' } });

    const minhas = await request(app).get('/api/reclamacoes').set(auth(maria)).expect(200);
    const minha = minhas.body.data.find((r: any) => r.id === recl.body.data.id);
    expect(minha).toMatchObject({ tem_foto: true });
    expect(minha.foto_url).toBeUndefined();

    const lista = await request(app).get('/api/admin/reclamacoes').set(auth(admin)).expect(200);
    const daLista = lista.body.data.find((r: any) => r.id === recl.body.data.id);
    expect(daLista.foto_url).toBe(`/api/admin/reclamacoes/${recl.body.data.id}/foto`);
    await request(app).get(daLista.foto_url).set(auth(admin)).expect(200).expect('Content-Type', /image\/jpeg/);
    await request(app).get(daLista.foto_url).set(auth(maria)).expect(403);
    expect(fs.existsSync('tests/.uploads/reclamacoes')).toBe(false);

    // Concluído: ainda dentro dos 7 dias
    const fim = await request(app).get(`/api/pedidos/${id}`).set(auth(maria)).expect(200);
    expect(fim.body.data).toMatchObject({ estado: 'concluido', avaliado: false, pode_reclamar: true });

    // Pedir de novo: rascunho igual, com o PedidoJSON
    const outra = await request(app).post(`/api/pedidos/${id}/pedir-de-novo`).set(auth(maria)).expect(201);
    expect(outra.body.data).toMatchObject({ estado: 'rascunho', pedido: { titulo: 'Sifão e torneira', estado: 'rascunho', categoria_chave: 'canalizador' } });
    await request(app).post(`/api/pedidos/${outra.body.data.id}/cancelar`).set(auth(maria)).send({}).expect(200);
  });

  it('PedidoJSON: avaliado e pode_reclamar nos pedidos antigos', async () => {
    const r = await request(app).get('/api/pedidos?limit=100').set(auth(await login(EMAIL.maria))).expect(200);
    const porId = (id: number) => r.body.data.find((p: any) => p.id === id);
    expect(porId(2)).toMatchObject({ estado: 'concluido', avaliado: true, pode_reclamar: false }); // concluído há mais de 7 dias
    expect(porId(4)).toMatchObject({ estado: 'cancelado', pode_reclamar: false });
    expect(porId(1)).toMatchObject({ estado: 'com_propostas', avaliado: false, pode_reclamar: false });
  });

  it('notificações: listar, marcar uma e marcar todas', async () => {
    const r = await request(app).get('/api/notificacoes').set(auth(maria)).expect(200);
    expect(r.body.data).toMatchObject({ nao_lidas: expect.any(Number), notificacoes: expect.any(Array) });
    const n = r.body.data.notificacoes[0];
    expect(n).toMatchObject({ id: expect.any(Number), tipo: expect.any(String), titulo: expect.any(String), lida: false });
    await request(app).post(`/api/notificacoes/${n.id}/lida`).set(auth(maria)).expect(200);
    const depois = await request(app).get('/api/notificacoes?so_nao_lidas=true').set(auth(maria)).expect(200);
    expect(depois.body.data.notificacoes.map((x: any) => x.id)).not.toContain(n.id);
    await request(app).post('/api/notificacoes/lidas').set(auth(maria)).expect(200);
  });

  it('ajuda: perguntas frequentes', async () => {
    const r = await request(app).get('/api/ajuda/perguntas').expect(200);
    expect(r.body.data.length).toBeGreaterThanOrEqual(3);
    expect(r.body.data[0]).toEqual({ id: expect.any(Number), tema: 'QR Code', pergunta: expect.any(String), resposta: expect.any(String) });
  });
});

describe('QA-06 · documentos de identidade só para o admin', () => {
  it('o documento não fica em /uploads e só o admin o vê', async () => {
    const pro = await entrarPorSms('+244923444001', 'profissional');
    const admin = await login(EMAIL.admin);
    await request(app).put('/api/profissionais/eu').set(auth(pro.token)).send({ nome_completo: 'Lurdes Pintora', categorias: ['pintor'], zona: 'Viana' }).expect(200);
    await request(app).put('/api/profissionais/eu/verificacao/documento').set(auth(pro.token)).attach('documento', await imagem(), 'bi.jpg').expect(200);
    await request(app).put('/api/profissionais/eu/verificacao/rosto').set(auth(pro.token)).attach('rosto', await imagem(), 'rosto.jpg').expect(200);
    const env = await request(app).post('/api/profissionais/eu/verificacao/enviar').set(auth(pro.token));
    expect(env.body.detail).toBe('Pedido processado com sucesso.');

    const lista = await request(app).get('/api/admin/verificacoes').set(auth(admin)).expect(200);
    const v = lista.body.data.find((x: any) => x.nome === 'Lurdes Pintora');
    expect(v.documento_url).toBe(`/api/admin/verificacoes/${v.id}/documento`);
    expect(v.selfie_url).toBe(`/api/admin/verificacoes/${v.id}/selfie`);

    await request(app).get(v.documento_url).set(auth(admin)).expect(200).expect('Content-Type', /image\/jpeg/);
    await request(app).get(v.selfie_url).set(auth(admin)).expect(200);
    await request(app).get(v.documento_url).set(auth(pro.token)).expect(403);
    expect(fs.existsSync('tests/.uploads/verificacoes')).toBe(false);
    await request(app).get('/uploads/verificacoes/exemplo-bi-2.jpg').expect(404);
  });
});
