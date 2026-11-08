import { NextFunction, Request, Response } from 'express';
import jwt from 'jsonwebtoken';
import { env } from '../config/env';
import { queryOne } from '../config/db';
import { sha256 } from '../utils/crypto';
import { forbidden, unauthorized } from '../utils/errors';
import type { TipoPerfil } from '../types/express';

/** Exige "Authorization: Bearer <token>" e uma sessão ativa (RF01 sessão mantida) */
export async function authenticate(req: Request, _res: Response, next: NextFunction) {
  const header = req.headers.authorization ?? '';
  const [scheme, token] = header.split(' ');
  if (scheme !== 'Bearer' || !token) throw unauthorized('Falta o token de acesso.');

  let payload: { sub: string; jti: string };
  try {
    payload = jwt.verify(token, env.jwtSecret, { algorithms: ['HS256'] }) as any;
  } catch {
    throw unauthorized();
  }

  const sessao = await queryOne<{ id: number; utilizador_id: number; tipo_perfil: TipoPerfil; perfil_ativo: TipoPerfil | null }>(
    `SELECT s.id, s.utilizador_id, u.tipo_perfil, s.perfil_ativo
       FROM sessao s JOIN utilizador u ON u.id = s.utilizador_id
      WHERE s.token_hash = ? AND s.revogada = FALSE AND s.expira_em > NOW() AND u.ativo = TRUE`,
    [sha256(payload.jti)],
  );
  if (!sessao || String(sessao.utilizador_id) !== String(payload.sub)) throw unauthorized();

  // O perfil com que a pessoa está a usar a app vem da sessão; o admin é sempre admin
  const perfil = sessao.tipo_perfil === 'admin' ? 'admin' : (sessao.perfil_ativo ?? sessao.tipo_perfil);
  req.user = { id: sessao.utilizador_id, tipo_perfil: perfil, tipo_conta: sessao.tipo_perfil, sessao_id: sessao.id };
  next();
}

export const requireRole =
  (...roles: TipoPerfil[]) =>
  (req: Request, _res: Response, next: NextFunction) => {
    if (!req.user || !roles.includes(req.user.tipo_perfil)) {
      throw forbidden(`Ação reservada a: ${roles.join(', ')}.`);
    }
    next();
  };
