import request from 'supertest';
import { createApp } from '../src/app';

export const app = createApp();

/** Utilizadores dos dados de exemplo (database/populate.sql) */
export const TEL = {
  maria: '+244923000000', // cliente, Talatona
  joaquim: '+244923000002', // canalizador e pedreiro verificado
  rui: '+244923000003', // canalizador e pedreiro
  admin: '+244923000099',
};

export const EMAIL = {
  maria: 'maria@exemplo.com',
  joaquim: 'joaquim@exemplo.com',
  rui: 'rui@exemplo.com',
  admin: 'admin@exemplo.com',
};

/** Entra pelo fluxo real do código por email e devolve o token */
export async function login(email: string, registo: Record<string, unknown> = {}): Promise<string> {
  const pedir = await request(app).post('/api/auth/codigo/pedir').send({ email }).expect(200);
  const res = await request(app)
    .post('/api/auth/codigo/verificar')
    .send({ email, codigo: pedir.body.data.codigo_dev, ...registo })
    .expect(200);
  return res.body.data.token;
}

/**
 * Entra pelo SMS (ecrãs 01 e 11) e devolve a resposta completa de /auth/sms/verificar.
 * Atenção: o mesmo número só pode pedir outro código passado 1 minuto.
 */
export async function entrarPorSms(telemovel: string, perfil: 'cliente' | 'profissional' = 'cliente', extra: Record<string, unknown> = {}) {
  const pedir = await request(app).post('/api/auth/sms/pedir').send({ telemovel, perfil }).expect(200);
  const res = await request(app)
    .post('/api/auth/sms/verificar')
    .send({ telemovel, perfil, codigo: pedir.body.data.codigo_dev, aceita_privacidade: true, ...extra })
    .expect(200);
  return res.body.data as { token: string; novo: boolean; perfil_ativo: string; precisa_registo: boolean; utilizador: any };
}

export const auth = (token: string) => ({ Authorization: `Bearer ${token}` });
