import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import request from 'supertest';
import sharp from 'sharp';
import fs from 'node:fs';
import path from 'node:path';
import { pool } from '../src/config/db';
import { app, auth, login, EMAIL, TEL } from './helpers';

afterAll(() => pool.end());

/** Imagem de teste grande (3000×2000) para confirmar a compressão */
const imagem = () => sharp({ create: { width: 3000, height: 2000, channels: 3, background: '#C8460A' } }).png().toBuffer();

describe('Upload de fotos (RM03, RM04)', () => {
  let maria: string, joaquim: string, admin: string, pedidoId: number;

  beforeAll(async () => {
    [maria, joaquim, admin] = await Promise.all([login(EMAIL.maria), login(EMAIL.joaquim), login(EMAIL.admin)]);
    const p = await request(app)
      .post('/api/pedidos')
      .set(auth(maria))
      .send({ categoria_id: 2, morada_id: 1, titulo: 'Esquentador avariado', descricao: 'Não aquece a água.', publicar: false })
      .expect(201);
    pedidoId = p.body.data.id;
  });

  it('junta foto ao pedido, redimensionada para 1280 px em JPEG', async () => {
    const res = await request(app)
      .post(`/api/pedidos/${pedidoId}/fotos`)
      .set(auth(maria))
      .attach('fotos', await imagem(), 'cano.png')
      .expect(201);
    const url: string = res.body.data[0].url;
    expect(url).toMatch(/^\/uploads\/pedidos\/.+\.jpg$/);

    const ficheiro = path.join('tests/.uploads', url.replace('/uploads/', ''));
    const meta = await sharp(ficheiro).metadata();
    expect(meta.width).toBe(1280);
    expect(meta.format).toBe('jpeg');

    // e fica acessível por HTTP
    await request(app).get(url).expect(200).expect('Content-Type', /image\/jpeg/);
  });

  it('recusa ficheiros que não são imagens', async () => {
    const res = await request(app)
      .post(`/api/pedidos/${pedidoId}/fotos`)
      .set(auth(maria))
      .attach('fotos', Buffer.from('%PDF-1.4 falso'), { filename: 'doc.pdf', contentType: 'application/pdf' })
      .expect(400);
    expect(res.body.data.codigo).toBe('UPLOAD_INVALIDO');
  });

  it('rascunho → publicar (RM03)', async () => {
    const res = await request(app).post(`/api/pedidos/${pedidoId}/publicar`).set(auth(maria)).expect(200);
    expect(res.body.data.estado).toBe('publicado');
  });

  it('RF07 · verificação com documento + selfie e decisão do admin', async () => {
    const token = await login('pedro@exemplo.com', {
      nome: 'Pedro Eletricista', telemovel: '+244944556677', tipo_perfil: 'profissional', aceita_privacidade: true,
    });
    const v = await request(app)
      .post('/api/profissionais/eu/verificacao')
      .set(auth(token))
      .field('tipo_documento', 'bilhete_identidade')
      .field('numero_documento', '009988776LA042')
      .attach('documento', await imagem(), 'bi.png')
      .attach('selfie', await imagem(), 'selfie.png')
      .expect(201);

    await request(app).post(`/api/admin/verificacoes/${v.body.data.id}/decidir`).set(auth(joaquim)).send({ aprovar: true }).expect(403);
    await request(app).post(`/api/admin/verificacoes/${v.body.data.id}/decidir`).set(auth(admin)).send({ aprovar: true }).expect(200);

    const eu = await request(app).get('/api/eu').set(auth(token)).expect(200);
    expect(eu.body.data.profissional.verificado).toBe(true);
  });

  it('RF06 · galeria de trabalhos feitos no perfil público', async () => {
    await request(app).post('/api/profissionais/eu/trabalhos').set(auth(joaquim)).field('legenda', 'Casa de banho nova').attach('fotos', await imagem(), 'obra.png').expect(201);
    const perfil = await request(app).get('/api/profissionais/2').expect(200);
    expect(perfil.body.data.trabalhos_feitos.some((t: any) => t.legenda === 'Casa de banho nova')).toBe(true);
  });
});

describe('Pesquisa e documentação', () => {
  it('RF02 · pesquisa por categoria, ordenada por distância', async () => {
    const res = await request(app).get('/api/profissionais?categoria_id=2&lat=-8.92&lng=13.185&ordenar=distancia').expect(200);
    expect(res.body.data.length).toBeGreaterThanOrEqual(2);
    expect(res.body.data[0].distancia_km).toBeLessThanOrEqual(res.body.data[1].distancia_km);
  });

  it('Swagger publica todos os endpoints em /docs.json', async () => {
    const res = await request(app).get('/docs.json').expect(200);
    expect(res.body.openapi).toBe('3.0.3');
    expect(Object.keys(res.body.paths)).toEqual(expect.arrayContaining(['/pedidos', '/pedidos/{id}/confirmar', '/propostas/{id}/aceitar']));
    await request(app).get('/docs/').expect(200);
  });

  it('endpoint inexistente devolve erro em JSON', async () => {
    const res = await request(app).get('/api/nao-existe').expect(404);
    expect(res.body.data.codigo).toBe('ROTA_INEXISTENTE');
  });
});
