import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import request from 'supertest';
import { pool } from '../src/config/db';
import { env } from '../src/config/env';
import { recriarBaseDeDados } from '../scripts/sql-runner';
import { app, auth, entrarPorSms, login, EMAIL, TEL } from './helpers';

afterAll(() => pool.end());

const pedir = (telemovel: string, extra: Record<string, unknown> = {}) =>
  request(app).post('/api/auth/sms/pedir').send({ telemovel, ...extra });
const verificar = (telemovel: string, codigo: string, extra: Record<string, unknown> = {}) =>
  request(app).post('/api/auth/sms/verificar').send({ telemovel, codigo, ...extra });

describe('RF01 · Entrada por telemóvel (ecrãs 01 e 11)', () => {
  it('a Maria entra com o número dela e recebe o EuJSON do mock', async () => {
    const r = await entrarPorSms(TEL.maria);
    expect(r.novo).toBe(false);
    expect(r.perfil_ativo).toBe('cliente');
    expect(r.precisa_registo).toBe(false);
    expect(r.utilizador).toMatchObject({
      id: 1, nome: 'Maria Kiala', telemovel: '+244923000000', tipo_perfil: 'cliente', perfil_ativo: 'cliente',
      zona: 'Talatona, Luanda', moradas_guardadas: 2, favoritos: 3, profissional: null,
    });
    expect(typeof r.utilizador.tem_novidades).toBe('boolean');

    // Pedir outra vez logo a seguir → 429 com os segundos que faltam
    const outra = await pedir(TEL.maria).expect(429);
    expect(outra.body.detail).toMatch(/^Pode pedir um novo código daqui a \d+ segundos\.$/);
  });

  it('a resposta do pedido é igual para números novos e existentes', async () => {
    const res = await pedir('923 111 001').expect(200); // sem indicativo: passa a +244923111001
    expect(Object.keys(res.body.data).sort()).toEqual(['codigo_dev', 'expira_em_min', 'mensagem', 'reenviar_em_s']);
    expect(res.body.data).toMatchObject({ expira_em_min: 5, reenviar_em_s: 60 });
    expect(res.body.data.mensagem).toContain('+244 923 111 001');
  });

  it('código errado → CODIGO_ERRADO; à sexta tentativa → 429', async () => {
    const tel = '+244923111002';
    const { body } = await pedir(tel).expect(200);
    const errado = body.data.codigo_dev === '000000' ? '111111' : '000000';
    const r1 = await verificar(tel, errado, { aceita_privacidade: true }).expect(400);
    expect(r1.body).toMatchObject({ detail: 'O código não está certo. Confirme o SMS e tente outra vez.', data: { codigo: 'CODIGO_ERRADO' } });
    for (let i = 0; i < 4; i++) await verificar(tel, errado).expect(400);
    await verificar(tel, body.data.codigo_dev).expect(429);
  });

  it('conta nova precisa de aceitar a privacidade; criada, fica com a hora em UTC', async () => {
    const tel = '+244923111003';
    const { body } = await pedir(tel).expect(200);
    const sem = await verificar(tel, body.data.codigo_dev).expect(400);
    expect(sem.body.data.codigo).toBe('PRIVACIDADE_EM_FALTA');

    const com = await verificar(tel, body.data.codigo_dev, { aceita_privacidade: true }).expect(200);
    expect(com.body.data).toMatchObject({ novo: true, perfil_ativo: 'cliente', utilizador: { nome: null, email: null, zona: null } });
    // pool em UTC: a data de criação bate com o relógio do Node
    const criado = new Date(com.body.data.utilizador.criado_em).getTime();
    expect(Math.abs(criado - Date.now())).toBeLessThan(2 * 60_000);
  });
});

describe('Perfil ativo (ecrã 20)', () => {
  let joaquim: string;
  beforeAll(async () => {
    // O Joaquim entra como cliente: a sessão fica em modo cliente
    const r = await entrarPorSms(TEL.joaquim, 'cliente');
    joaquim = r.token;
    expect(r.utilizador).toMatchObject({ tipo_perfil: 'profissional', perfil_ativo: 'cliente', zona: null });
  });

  it('em modo cliente não acede à área do profissional', async () => {
    await request(app).get('/api/profissionais/eu/painel').set(auth(joaquim)).expect(403);
  });

  it('muda para profissional e vê o painel (ecrã 14)', async () => {
    const mudar = await request(app).put('/api/eu/perfil-ativo').set(auth(joaquim)).send({ perfil: 'profissional' }).expect(200);
    expect(mudar.body.data.perfil_ativo).toBe('profissional');
    expect(mudar.body.data.utilizador).toMatchObject({
      perfil_ativo: 'profissional', zona: 'Talatona, Luanda',
      profissional: { categorias: ['canalizador', 'pedreiro'], verificado: true, media_avaliacao: 4.8, registo_completo: true },
    });

    const painel = await request(app).get('/api/profissionais/eu/painel').set(auth(joaquim)).expect(200);
    expect(painel.body.data).toMatchObject({ nome: 'Joaquim', zona: 'Talatona, Luanda', raio_km: 10, disponivel: true });
    const muro = painel.body.data.pedidos.find((p: any) => p.id === 10);
    expect(muro).toMatchObject({ titulo: 'Reparar muro do quintal', categoria_chave: 'pedreiro', zona: 'Viana', novo: true });
    expect(muro.distancia_km).toBeGreaterThan(0);
    // No pedido 1 já enviou proposta: não é "novo"
    expect(painel.body.data.pedidos.find((p: any) => p.id === 1)).toMatchObject({ novo: false });
    expect(painel.body.data.pedidos_novos).toBeGreaterThanOrEqual(1);
  });

  it('a conta de administração não muda de perfil', async () => {
    const admin = await login(EMAIL.admin);
    await request(app).put('/api/eu/perfil-ativo').set(auth(admin)).send({ perfil: 'cliente' }).expect(403);
  });
});

describe('Dados de exemplo alinhados com o mock da app', () => {
  let maria: string;
  beforeAll(async () => {
    maria = await login(EMAIL.maria);
  });

  it('13 categorias com as chaves da app; 8 em destaque', async () => {
    const res = await request(app).get('/api/categorias').expect(200);
    expect(res.body.data.map((c: any) => c.chave)).toEqual([
      'eletricista', 'canalizador', 'mecanico', 'pedreiro', 'ar_cond', 'cabeleireira', 'pintor', 'limpeza',
      'carpinteiro', 'jardinagem', 'informatica', 'serralharia', 'transporte',
    ]);
    expect(res.body.data.filter((c: any) => c.em_destaque === true)).toHaveLength(8);
    expect(res.body.data[1]).toMatchObject({ id: 2, nome: 'Canalizador', plural: 'canalizadores', em_destaque: true });

    const etiquetas = await request(app).get('/api/etiquetas').expect(200);
    expect(etiquetas.body.data.map((e: any) => e.chave)).toEqual(['pontual', 'preco_justo', 'simpatico', 'trabalho_limpo', 'rapido']);
  });

  it('perfil do Joaquim (ecrã 03): ProfissionalDetalhe', async () => {
    const res = await request(app).get('/api/profissionais/2').expect(200);
    expect(res.body.data).toMatchObject({
      id: 2, nome: 'Joaquim Manuel', categoria: 'Canalizador', categoria_chave: 'canalizador', zona: 'Talatona, Luanda',
      anos_experiencia: 6, verificado: true, mao_de_obra_desde: 8000,
      especialidades: ['Fugas de água', 'Esquentadores', 'Desentupimentos', 'Loiças sanitárias'],
    });
    expect(res.body.data.num_avaliacoes).toBeGreaterThanOrEqual(126);
    expect(res.body.data.trabalhos_feitos.map((t: any) => t.legenda)).toEqual(expect.arrayContaining(['Antes/depois', 'Esquentador']));
    const mariaS = res.body.data.avaliacoes.find((a: any) => a.autor === 'Maria S.');
    expect(mariaS).toMatchObject({ estrelas: 5, etiquetas: ['pontual', 'rapido'] });
  });

  it('pedido 1 "Fuga de água na cozinha" com 3 propostas, a do Joaquim de 12 500 Kz', async () => {
    const res = await request(app).get('/api/pedidos/1').set(auth(maria)).expect(200);
    expect(res.body.data).toMatchObject({
      titulo: 'Fuga de água na cozinha', categoria_chave: 'canalizador', estado: 'com_propostas', zona: 'Talatona',
      num_fotos: 1, profissional: null, valor_acordado: null, cliente_curto: null,
    });
    const propostas = res.body.data.propostas;
    expect(propostas.map((p: any) => p.valor_total)).toEqual([12500, 15000, 18500]);
    expect(propostas[0]).toMatchObject({
      estado: 'enviada', na_hora_pedida: false, material_detalhe: 'sifão e vedante', tempo_chegada_min: 40,
      componentes: { mao_de_obra: 8000, material: 3500, deslocacao: 1000 },
      profissional: { nome: 'Joaquim Manuel', rating: 4.8, verificado: true },
    });
    const chegada = new Date(propostas[0].chegada_prevista).getTime();
    expect(Math.abs(chegada - (Date.now() + 40 * 60_000))).toBeLessThan(2 * 60_000);
  });

  it('histórico da Maria (ecrã 07): mais recentes primeiro, com profissional e valor', async () => {
    const res = await request(app).get('/api/pedidos?limit=100').set(auth(maria)).expect(200);
    const porId = (id: number) => res.body.data.find((p: any) => p.id === id);
    expect(porId(2)).toMatchObject({ titulo: 'Tomada sem luz', estado: 'concluido', valor_acordado: 6000, profissional: { nome: 'Carlos Dias' } });
    expect(porId(4)).toMatchObject({ estado: 'cancelado', valor_acordado: 15000, profissional: { nome: 'Hélder Tavares' } });
    const historicos = res.body.data.filter((p: any) => [2, 3, 4, 5].includes(p.id)).map((p: any) => p.id);
    expect(historicos).toEqual([2, 3, 4, 5]);
  });

  it('conversas da Maria (ecrã 18) e detalhe sem marcar como lida (ecrã 19)', async () => {
    const lista = await request(app).get('/api/conversas').set(auth(maria)).expect(200);
    const c1 = lista.body.data.find((c: any) => c.id === 1);
    expect(c1).toMatchObject({
      pedido_id: 1, pedido_titulo: 'Fuga de água na cozinha', categoria_chave: 'canalizador', valor: 12500, nao_lidas: 2,
      interlocutor: { id: 2, nome: 'Joaquim Manuel' },
    });
    expect(c1.mensagens).toHaveLength(1);
    expect(c1.mensagens[0]).toMatchObject({ texto: 'Chego às 15h40, como combinado.', minha: false, lida: false });

    const det = await request(app).get('/api/conversas/1').set(auth(maria)).expect(200);
    expect(det.body.data.mensagens.map((m: any) => m.minha)).toEqual([true, false, false]);
    expect(det.body.data.mensagens[0]).toMatchObject({ texto: 'Boa tarde. Já tem o sifão para a reparação?', lida: true });
    expect(det.body.data.nao_lidas).toBe(2);
  });

  it('profissionais perto de si e pinos do mapa (ecrãs 02 e 22)', async () => {
    const perto = await request(app).get('/api/profissionais/perto?limit=20').set(auth(maria)).expect(200);
    // Por distância; quem não tem GPS fica no fim
    const dist = perto.body.data.map((p: any) => p.distancia_km ?? Infinity);
    expect(dist).toEqual([...dist].sort((a, b) => a - b));
    expect(perto.body.data.find((p: any) => p.id === 2)).toMatchObject({ categoria_chave: 'canalizador', servicos_confirmados: expect.any(Number) });
    // Como no Figma: o Joaquim é o primeiro, a 1,2 km da morada predefinida da Maria
    expect(perto.body.data[0]).toMatchObject({ id: 2, nome: 'Joaquim Manuel', distancia_km: 1.2 });

    const mapa = await request(app).get('/api/profissionais/mapa?raio_km=5').set(auth(maria)).expect(200);
    for (const pin of mapa.body.data) {
      expect(pin.x).toBeGreaterThanOrEqual(0);
      expect(pin.y).toBeLessThanOrEqual(1);
    }
    // Os quatro do mock ficam à volta da casa da Maria; o Joaquim a noroeste, a 1,2 km
    const joaquim = mapa.body.data.find((p: any) => p.profissional.id === 2);
    expect(joaquim.x).toBeCloseTo(0.413, 2);
    expect(joaquim.y).toBeCloseTo(0.416, 2);
    expect(mapa.body.data.map((p: any) => p.profissional.id)).toEqual(expect.arrayContaining([2, 3, 5, 6]));
  });
});

describe('Base de dados', () => {
  it('create.sql + populate.sql + queries.sql correm sem erros', async () => {
    await recriarBaseDeDados({ ...env.db, database: 'kisalu_express_test_consultas' }, { comConsultas: true });
    const [rows] = await pool.query<any[]>(
      `SELECT estado FROM kisalu_express_test_consultas.pedido WHERE id = 10`,
    );
    expect(rows[0].estado).toBe('concluido');
    await pool.query('DROP DATABASE kisalu_express_test_consultas');
  });
});
