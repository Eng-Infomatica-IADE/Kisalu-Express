import { afterAll, describe, expect, it } from 'vitest';
import request from 'supertest';
import { pool } from '../src/config/db';
import { app, auth, login, EMAIL, TEL } from './helpers';

afterAll(() => pool.end());

const pedirCodigo = (email: string) => request(app).post('/api/auth/codigo/pedir').send({ email });

describe('RF01 · Entrada com email e código', () => {
  it('pede o código e recusa um código errado', async () => {
    const pedir = await pedirCodigo(EMAIL.maria).expect(200);
    const errado = pedir.body.data.codigo_dev === '000000' ? '111111' : '000000';
    const res = await request(app).post('/api/auth/codigo/verificar').send({ email: EMAIL.maria, codigo: errado });
    expect(res.status).toBe(400);
    expect(res.body.data.codigo).toBe('CODIGO_ERRADO');
  });

  it('recusa email com formato inválido', async () => {
    const res = await pedirCodigo('maria-sem-arroba').expect(400);
    expect(res.body.data.codigo).toBe('DADOS_INVALIDOS');
  });

  it('entra com um utilizador existente (email sem distinguir maiúsculas) e mantém a sessão', async () => {
    const token = await login('  Maria@Exemplo.com ');
    const eu = await request(app).get('/api/eu').set(auth(token)).expect(200);
    expect(eu.body.data.nome).toBe('Maria Kiala');
    expect(eu.body.data.email).toBe(EMAIL.maria);
    expect(eu.body.data.tipo_perfil).toBe('cliente');
  });

  it('email novo sem dados de registo → REGISTO_INCOMPLETO, e o código continua válido', async () => {
    const email = 'ana@exemplo.com';
    const pedir = await pedirCodigo(email).expect(200);
    const sem = await request(app).post('/api/auth/codigo/verificar').send({ email, codigo: pedir.body.data.codigo_dev }).expect(400);
    expect(sem.body.data.codigo).toBe('REGISTO_INCOMPLETO');

    const com = await request(app)
      .post('/api/auth/codigo/verificar')
      .send({
        email, codigo: pedir.body.data.codigo_dev,
        nome: 'Ana Profissional', telemovel: '+244931112233', tipo_perfil: 'profissional', aceita_privacidade: true,
      })
      .expect(200);
    expect(com.body.data.novo).toBe(true);
    expect(com.body.data.utilizador).toMatchObject({ email, telemovel: '+244931112233' });
    expect(com.body.data.utilizador.profissional).toMatchObject({ verificado: false, total_servicos: 0, registo_completo: false });
  });

  it('registo com telemóvel de outra conta → TELEMOVEL_EM_USO', async () => {
    const email = 'repetido@exemplo.com';
    const pedir = await pedirCodigo(email).expect(200);
    const res = await request(app)
      .post('/api/auth/codigo/verificar')
      .send({ email, codigo: pedir.body.data.codigo_dev, nome: 'Outra Pessoa', telemovel: TEL.maria, tipo_perfil: 'cliente', aceita_privacidade: true })
      .expect(409);
    expect(res.body.data.codigo).toBe('TELEMOVEL_EM_USO');
  });

  it('terminar sessão invalida o token', async () => {
    const token = await login(EMAIL.rui);
    await request(app).post('/api/auth/sair').set(auth(token)).expect(200);
    await request(app).get('/api/eu').set(auth(token)).expect(401);
  });

  it('sem token → 401; perfil errado → 403', async () => {
    await request(app).get('/api/pedidos').expect(401);
    const cliente = await login(EMAIL.maria);
    const res = await request(app).get('/api/pedidos/proximos').set(auth(cliente)).expect(403);
    expect(res.body.data.codigo).toBe('SEM_PERMISSAO');
  });
});

describe('Formato único de resposta', () => {
  it('erros e sucessos têm sempre { title, status, detail, instance, data }', async () => {
    const erro = await request(app).get('/api/admin/verificacoes?x=1').expect(401);
    expect(Object.keys(erro.body).sort()).toEqual(['data', 'detail', 'instance', 'status', 'title']);
    expect(erro.body).toMatchObject({ status: 401, instance: '/api/admin/verificacoes', data: { codigo: 'NAO_AUTENTICADO' } });

    const ok = await request(app).get('/api/saude').expect(200);
    expect(ok.body).toMatchObject({ title: 'Sucesso', status: 200, instance: '/api/saude', data: { estado: 'ok' } });
  });
});
