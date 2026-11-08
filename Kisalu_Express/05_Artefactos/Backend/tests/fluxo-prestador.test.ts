import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import request from 'supertest';
import sharp from 'sharp';
import { pool } from '../src/config/db';
import { app, auth, login, EMAIL } from './helpers';

afterAll(() => pool.end());

const imagem = () => sharp({ create: { width: 800, height: 600, channels: 3, background: '#2E5E4E' } }).png().toBuffer();

/**
 * Percurso do prestador, como a app o faz:
 * SMS → registo profissional → verificação → painel → proposta;
 * cliente aceita (e desfaz) → QR → profissional confirma com o código → comprovativo → avaliação;
 * e as conversas com "lida".
 */
describe('Fluxo do prestador', () => {
  const TEL = '+244912345001';
  let domingos: string, domingosId: number, maria: string, joaquim: string, admin: string;
  let pedidoId: number, dataPretendida: string, propostaDomingos: number, propostaJoaquim: number;
  let conversaId: number;

  beforeAll(async () => {
    [maria, joaquim, admin] = await Promise.all([login(EMAIL.maria), login(EMAIL.joaquim), login(EMAIL.admin)]);
  });

  it('ecrãs 01 e 11: "Criar conta" como profissional por SMS', async () => {
    const pedir = await request(app).post('/api/auth/sms/pedir').send({ telemovel: TEL, perfil: 'profissional', criar_conta: true }).expect(200);
    await request(app).post('/api/auth/sms/pedir').send({ telemovel: TEL, perfil: 'profissional' }).expect(429);

    const res = await request(app)
      .post('/api/auth/sms/verificar')
      .send({ telemovel: TEL, codigo: pedir.body.data.codigo_dev, perfil: 'profissional', aceita_privacidade: true })
      .expect(200);
    expect(res.body.data).toMatchObject({ novo: true, perfil_ativo: 'profissional', precisa_registo: true });
    expect(res.body.data.utilizador).toMatchObject({ nome: null, tipo_perfil: 'profissional', profissional: { categorias: [], registo_completo: false } });
    domingos = res.body.data.token;
    domingosId = res.body.data.utilizador.id;
  });

  it('ecrã 12: registo profissional (upsert) e disponibilidade', async () => {
    await request(app).put('/api/profissionais/eu').set(auth(domingos)).send({ categorias: ['canalizador_x'] }).expect(400);

    const res = await request(app)
      .put('/api/profissionais/eu')
      .set(auth(domingos))
      .send({ nome_completo: 'Domingos Afonso', categorias: ['pedreiro'], anos_experiencia: 10, zona: 'Viana, Luanda', raio_atuacao_km: 10 })
      .expect(200);
    expect(res.body.data.perfil_ativo).toBe('profissional');
    expect(res.body.data.utilizador).toMatchObject({
      nome: 'Domingos Afonso', zona: 'Viana, Luanda',
      profissional: { categorias: ['pedreiro'], anos_experiencia: 10, raio_atuacao_km: 10, disponivel: true, registo_completo: true },
    });

    const off = await request(app).put('/api/profissionais/eu').set(auth(domingos)).send({ disponivel: false }).expect(200);
    expect(off.body.data.utilizador.profissional.disponivel).toBe(false);
    await request(app).put('/api/profissionais/eu').set(auth(domingos)).send({ disponivel: true }).expect(200);
  });

  it('ecrã 13: documento + rosto (JSON vazio, como a app) e enviar para verificação', async () => {
    const inicio = await request(app).get('/api/profissionais/eu/verificacao').set(auth(domingos)).expect(200);
    expect(inicio.body.data).toMatchObject({ estado: 'nao_pedida', documento_enviado: false, rosto_enviado: false });

    const cedo = await request(app).post('/api/profissionais/eu/verificacao/enviar').set(auth(domingos)).expect(400);
    expect(cedo.body.data.codigo).toBe('VERIFICACAO_INCOMPLETA');

    // Documento com imagem a sério (multipart)
    const doc = await request(app)
      .put('/api/profissionais/eu/verificacao/documento')
      .set(auth(domingos))
      .attach('documento', await imagem(), 'bi.png')
      .expect(200);
    expect(doc.body.data).toMatchObject({ estado: 'rascunho', documento_enviado: true, rosto_enviado: false });

    const semRosto = await request(app).post('/api/profissionais/eu/verificacao/enviar').set(auth(domingos)).expect(400);
    expect(semRosto.body.detail).toContain('rosto');

    // Rosto com corpo JSON vazio: captura simulada fora de produção
    const rosto = await request(app).put('/api/profissionais/eu/verificacao/rosto').set(auth(domingos)).send({}).expect(200);
    expect(rosto.body.data).toMatchObject({ documento_enviado: true, rosto_enviado: true });
    // e o documento também aceita {} (substitui pela captura simulada)
    await request(app).put('/api/profissionais/eu/verificacao/documento').set(auth(domingos)).send({}).expect(200);

    const enviar = await request(app).post('/api/profissionais/eu/verificacao/enviar').set(auth(domingos)).expect(200);
    expect(enviar.body.data.estado).toBe('pendente');
    await request(app).put('/api/profissionais/eu/verificacao/rosto').set(auth(domingos)).send({}).expect(409);

    const lista = await request(app).get('/api/admin/verificacoes').set(auth(admin)).expect(200);
    expect(lista.body.data.some((v: any) => v.profissional_id === domingosId)).toBe(true);
  });

  it('ecrã 10: a Maria publica um pedido no formato da app (zona + ponto de referência)', async () => {
    dataPretendida = new Date(Date.now() + 26 * 3600_000).toISOString().replace(/\.\d{3}Z$/, '.000Z');
    const res = await request(app)
      .post('/api/pedidos')
      .set(auth(maria))
      .send({
        categoria_chave: 'pedreiro', titulo: 'Rachas na parede da sala', descricao: 'Apareceram rachas grandes depois das chuvas.',
        zona: 'Talatona', ponto_referencia: 'perto da cantina do Sr. Zé', quando: dataPretendida, publicar: true,
      })
      .expect(201);
    expect(res.body.data).toMatchObject({ estado: 'publicado', categoria_plural: 'pedreiros' });
    expect(res.body.data.pedido).toMatchObject({ categoria_chave: 'pedreiro', zona: 'Talatona', data_pretendida: dataPretendida });
    expect(res.body.data.profissionais_avisados).toBeGreaterThanOrEqual(2);
    pedidoId = res.body.data.id;

    // Reaproveitou a morada "Casa" (mesma zona e referência): continua com 2 moradas
    const moradas = await request(app).get('/api/moradas').set(auth(maria)).expect(200);
    expect(moradas.body.data).toHaveLength(2);
  });

  it('ecrã 14: o pedido aparece no painel como novo', async () => {
    const painel = await request(app).get('/api/profissionais/eu/painel').set(auth(domingos)).expect(200);
    expect(painel.body.data).toMatchObject({ nome: 'Domingos', zona: 'Viana, Luanda', raio_km: 10, rating: 0, servicos: 0 });
    const p = painel.body.data.pedidos.find((x: any) => x.id === pedidoId);
    expect(p).toMatchObject({ titulo: 'Rachas na parede da sala', categoria_chave: 'pedreiro', zona: 'Talatona', novo: true, distancia_km: null });

    const det = await request(app).get(`/api/pedidos/${pedidoId}`).set(auth(domingos)).expect(200);
    expect(det.body.data).toMatchObject({ zona: 'Talatona', categoria_chave: 'pedreiro', novo: true, cliente_curto: 'Maria K.' });
    expect(det.body.data.morada.endereco).toBeUndefined();
  });

  it('ecrã 15: proposta abaixo de 500 Kz é recusada; "na hora pedida" fica com a hora do cliente', async () => {
    const baixa = await request(app)
      .post(`/api/pedidos/${pedidoId}/propostas`)
      .set(auth(domingos))
      .send({ valor_mao_obra: 300, valor_material: 0, valor_deslocacao: 100, tempo_chegada_min: 40 })
      .expect(400);
    expect(baixa.body.data.codigo).toBe('VALOR_MINIMO');

    const ok = await request(app)
      .post(`/api/pedidos/${pedidoId}/propostas`)
      .set(auth(domingos))
      .send({ valor_mao_obra: 8000, valor_material: 3000, valor_deslocacao: 1000, material_detalhe: 'massa e tinta', na_hora_pedida: true })
      .expect(201);
    expect(ok.body.data).toMatchObject({
      valor_total: 12000, na_hora_pedida: true, tempo_chegada_min: null, chegada_prevista: dataPretendida,
      material_detalhe: 'massa e tinta', estado: 'enviada', profissional: { nome: 'Domingos Afonso', verificado: false },
    });
    propostaDomingos = ok.body.data.id;

    const j = await request(app)
      .post(`/api/pedidos/${pedidoId}/propostas`)
      .set(auth(joaquim))
      .send({ valor_mao_obra: 9000, valor_material: 3000, valor_deslocacao: 1000, tempo_chegada_min: 60 })
      .expect(201);
    propostaJoaquim = j.body.data.id;

    const painel = await request(app).get('/api/profissionais/eu/painel').set(auth(domingos)).expect(200);
    expect(painel.body.data.pedidos.find((x: any) => x.id === pedidoId).novo).toBe(false);
  });

  it('ecrã 08: a Maria aceita e desfaz; as propostas voltam a estar disponíveis', async () => {
    await request(app).post(`/api/propostas/${propostaDomingos}/aceitar`).set(auth(maria)).expect(200);
    const curso = await request(app).get('/api/pedidos/em-curso').set(auth(maria)).expect(200);
    expect(curso.body.data).toMatchObject({ id: pedidoId, estado: 'aceite', valor_acordado: 12000, proposta_aceite_id: propostaDomingos });
    expect(curso.body.data.profissional.nome).toBe('Domingos Afonso');

    const desfeito = await request(app).post(`/api/pedidos/${pedidoId}/desfazer-aceitacao`).set(auth(maria)).expect(200);
    expect(desfeito.body.data).toMatchObject({ estado: 'com_propostas', proposta_aceite_id: null, profissional: null, valor_acordado: null });
    expect(desfeito.body.data.propostas.map((p: any) => [p.id, p.estado])).toEqual([[propostaDomingos, 'enviada'], [propostaJoaquim, 'enviada']]);
    await request(app).get(`/api/pedidos/${pedidoId}/qr`).set(auth(maria)).expect(409);
    await request(app).post(`/api/pedidos/${pedidoId}/desfazer-aceitacao`).set(auth(maria)).expect(409);

    // Volta a aceitar
    await request(app).post(`/api/propostas/${propostaDomingos}/aceitar`).set(auth(maria)).expect(200);
  });

  it('ecrãs 05 e 16: QR opaco; 5 códigos errados bloqueiam; abrir de novo dá código novo', async () => {
    const porConfirmar = await request(app).get('/api/pedidos/por-confirmar').set(auth(domingos)).expect(200);
    expect(porConfirmar.body.data).toEqual({ pedido_id: pedidoId, servico: 'Rachas na parede da sala', cliente: 'Maria K.', valor: 12000 });

    const qr = await request(app).get(`/api/pedidos/${pedidoId}/qr`).set(auth(maria)).expect(200);
    expect(qr.body.data).toMatchObject({ pedido_id: pedidoId, valor_acordado: 12000, categoria_chave: 'pedreiro', profissional: { nome: 'Domingos Afonso' } });
    expect(qr.body.data.token).toMatch(/^kx_qr_[\w-]{20,}$/);
    expect(qr.body.data.codigo).toMatch(/^\d{6}$/);
    const validade = new Date(qr.body.data.valido_ate).getTime() - Date.now();
    expect(validade).toBeGreaterThan(5 * 60_000);
    expect(validade).toBeLessThanOrEqual(11 * 60_000);

    // A app manda {codigo, metodo_pagamento: 'dinheiro'}
    const errado = qr.body.data.codigo === '000000' ? '000001' : '000000';
    const tokenErrado = await request(app).post(`/api/pedidos/${pedidoId}/confirmar`).set(auth(domingos)).send({ token: 'kx_qr_nao_e_este_token_123' }).expect(400);
    expect(tokenErrado.body.data.codigo).toBe('CODIGO_ERRADO');
    for (let i = 0; i < 4; i++) {
      await request(app).post(`/api/pedidos/${pedidoId}/confirmar`).set(auth(domingos)).send({ codigo: errado, metodo_pagamento: 'dinheiro' }).expect(400);
    }
    await request(app).post(`/api/pedidos/${pedidoId}/confirmar`).set(auth(domingos)).send({ codigo: qr.body.data.codigo, metodo_pagamento: 'dinheiro' }).expect(429);

    const novo = await request(app).get(`/api/pedidos/${pedidoId}/qr`).set(auth(maria)).expect(200);
    expect(novo.body.data.token).not.toBe(qr.body.data.token);

    const ok = await request(app)
      .post(`/api/pedidos/${pedidoId}/confirmar`)
      .set(auth(domingos))
      .send({ codigo: novo.body.data.codigo, metodo_pagamento: 'dinheiro' })
      .expect(200);
    expect(ok.body.data).toMatchObject({
      pedido_id: pedidoId, titulo: 'Rachas na parede da sala', cliente: 'Maria Kiala', cliente_curto: 'Maria K.',
      valor_kz: 12000, valor_formatado: '12 000 Kz', metodo_pagamento: 'dinheiro', metodo_confirmacao: 'codigo',
      profissional: { id: domingosId, nome: 'Domingos Afonso', servicos_confirmados: 1 },
    });
    expect(ok.body.data.numero_comprovativo).toMatch(/^KX-\d{4}-\d{6}$/);
    expect(ok.body.data.partilha_whatsapp).toContain('wa.me');

    await request(app).post(`/api/pedidos/${pedidoId}/confirmar`).set(auth(domingos)).send({ codigo: novo.body.data.codigo }).expect(409);
    const nada = await request(app).get('/api/pedidos/por-confirmar').set(auth(domingos)).expect(200);
    expect(nada.body.data).toBeNull();

    // Ecrã 17: o profissional abre o comprovativo; o histórico dele traz o cliente abreviado
    const comp = await request(app).get(`/api/pedidos/${pedidoId}/comprovativo`).set(auth(domingos)).expect(200);
    expect(comp.body.data.numero_comprovativo).toBe(ok.body.data.numero_comprovativo);
    const hist = await request(app).get('/api/pedidos?limit=100').set(auth(domingos)).expect(200);
    expect(hist.body.data[0]).toMatchObject({ id: pedidoId, estado: 'concluido', cliente_curto: 'Maria K.', valor_acordado: 12000, propostas: [] });
  });

  it('ecrã 06: avaliação com as chaves das etiquetas', async () => {
    const ma = await request(app).post(`/api/pedidos/${pedidoId}/avaliacao`).set(auth(maria)).send({ estrelas: 5, etiquetas: ['pontualissimo'] }).expect(400);
    expect(ma.body.data.codigo).toBe('ETIQUETA_INVALIDA');

    await request(app)
      .post(`/api/pedidos/${pedidoId}/avaliacao`)
      .set(auth(maria))
      .send({ estrelas: 5, etiquetas: ['pontual', 'preco_justo', 'trabalho_limpo'], comentario: 'Deixou a parede como nova.' })
      .expect(201);

    const perfil = await request(app).get(`/api/profissionais/${domingosId}`).expect(200);
    expect(perfil.body.data).toMatchObject({ rating: 5, num_avaliacoes: 1, servicos_confirmados: 1 });
    expect(perfil.body.data.avaliacoes[0]).toMatchObject({ autor: 'Maria K.', estrelas: 5, etiquetas: ['pontual', 'preco_justo', 'trabalho_limpo'] });
  });

  it('ecrãs 18 e 19: conversa, mensagem e "lida"', async () => {
    const doProf = await request(app).get('/api/conversas').set(auth(domingos)).expect(200);
    const c = doProf.body.data.find((x: any) => x.pedido_id === pedidoId);
    expect(c).toMatchObject({ valor: 12000, nao_lidas: 0, interlocutor: { id: 1, nome: 'Maria K.', e_cliente: true } });
    conversaId = c.id;

    await request(app).post(`/api/conversas/${conversaId}/mensagens`).set(auth(domingos)).send({ texto: 'x'.repeat(1001) }).expect(400);
    const msg = await request(app).post(`/api/conversas/${conversaId}/mensagens`).set(auth(domingos)).send({ texto: 'Obrigado pela avaliação!' }).expect(201);
    expect(msg.body.data).toMatchObject({ texto: 'Obrigado pela avaliação!', minha: true, lida: false, foto_url: null });

    const daMaria = await request(app).get('/api/conversas').set(auth(maria)).expect(200);
    expect(daMaria.body.data.find((x: any) => x.id === conversaId)).toMatchObject({ nao_lidas: 1, interlocutor: { nome: 'Domingos Afonso' } });

    // Abrir o detalhe não marca como lida; o POST /lida sim
    await request(app).get(`/api/conversas/${conversaId}`).set(auth(maria)).expect(200);
    const ainda = await request(app).get(`/api/conversas/${conversaId}`).set(auth(maria)).expect(200);
    expect(ainda.body.data.nao_lidas).toBe(1);
    await request(app).post(`/api/conversas/${conversaId}/lida`).set(auth(maria)).expect(200);
    const depois = await request(app).get(`/api/conversas/${conversaId}`).set(auth(maria)).expect(200);
    expect(depois.body.data.nao_lidas).toBe(0);

    const prof = await request(app).get(`/api/conversas/${conversaId}`).set(auth(domingos)).expect(200);
    expect(prof.body.data.mensagens.at(-1)).toMatchObject({ minha: true, lida: true });
    await request(app).get(`/api/conversas/${conversaId}`).set(auth(joaquim)).expect(404);
  });
});
