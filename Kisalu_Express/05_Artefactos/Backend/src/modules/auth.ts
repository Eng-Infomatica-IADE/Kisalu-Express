import { Router } from 'express';
import jwt from 'jsonwebtoken';
import { z } from 'zod';
import { env, isProduction } from '../config/env';
import { Db, execute, queryOne, transaction } from '../config/db';
import { codigo6, sha256, uuid } from '../utils/crypto';
import { AppError, badRequest, conflict, forbidden, tooMany } from '../utils/errors';
import { route } from '../utils/route';
import { codigoSms, telemovelAngolano } from '../utils/validacoes';
import { enviarCodigoEntrada } from '../services/email';
import { enviarCodigoSms, formatarTelemovel } from '../services/sms';
import { euJSON, garantirProfissional } from '../services/conta';
import { guardarImagem, ficheiros } from '../middlewares/upload';
import type { TipoPerfil } from '../types/express';

const router = Router();
const TAG = 'Autenticação e conta';

/** Telemóvel angolano (+244 e 9 dígitos começados por 9); aceita espaços e o indicativo */
const telemovel = telemovelAngolano;

const email = z
  .string()
  .trim()
  .toLowerCase()
  .pipe(z.string().email('Confirme o email. Exemplo: maria@exemplo.com.').max(150))
  .openapi({ example: 'maria@exemplo.com' });

const codigoSeisDigitos = codigoSms;
const perfilEscolhido = z.enum(['cliente', 'profissional']);

const hashCodigo = (destino: string, codigo: string) => sha256(`${destino}:${codigo}`);

async function garantirTelemovelLivre(tel: string, exceptoId = 0) {
  const outro = await queryOne(`SELECT id FROM utilizador WHERE telemovel = ? AND id <> ?`, [tel, exceptoId]);
  if (outro) throw conflict('Este telemóvel já está associado a outra conta.', 'TELEMOVEL_EM_USO');
}

/** Cria a sessão e devolve o JWT. O perfil ativo fica guardado na sessão. */
async function abrirSessao(
  db: Db,
  utilizadorId: number,
  perfil: TipoPerfil,
  extra: { dispositivo?: string; push_token?: string },
): Promise<string> {
  const jti = uuid();
  await execute(
    `INSERT INTO sessao (utilizador_id, token_hash, perfil_ativo, dispositivo, push_token, expira_em)
     VALUES (?, ?, ?, ?, ?, NOW() + INTERVAL ? DAY)`,
    [utilizadorId, sha256(jti), perfil, extra.dispositivo ?? null, extra.push_token ?? null, env.jwtExpiresDays],
    db,
  );
  await execute(`UPDATE utilizador SET ultimo_acesso_em = NOW() WHERE id = ?`, [utilizadorId], db);
  return jwt.sign({ sub: String(utilizadorId), jti }, env.jwtSecret, { algorithm: 'HS256', expiresIn: `${env.jwtExpiresDays}d` });
}

/** Valida o código mais recente ainda por usar (SMS ou email). Lança o erro certo para cada caso. */
async function validarCodigo(coluna: 'telemovel' | 'email', destino: string, codigo: string) {
  const pedido = await queryOne<{ id: number; codigo_hash: string; tentativas: number; expirado: number }>(
    `SELECT id, codigo_hash, tentativas, expira_em <= NOW() AS expirado FROM codigo_login
      WHERE ${coluna} = ? AND usado = FALSE
      ORDER BY id DESC LIMIT 1`,
    [destino],
  );
  if (!pedido || pedido.expirado) throw badRequest('O código expirou ou não existe. Peça um novo.', 'CODIGO_EXPIRADO');
  if (pedido.tentativas >= 5) throw tooMany('Demasiadas tentativas. Peça um novo código.');
  if (pedido.codigo_hash !== hashCodigo(destino, codigo)) {
    await execute(`UPDATE codigo_login SET tentativas = tentativas + 1 WHERE id = ?`, [pedido.id]);
    throw badRequest(
      coluna === 'telemovel'
        ? 'O código não está certo. Confirme o SMS e tente outra vez.'
        : 'Código errado. Confirme os 6 dígitos do email.',
      'CODIGO_ERRADO',
    );
  }
  return pedido.id;
}

// =====================================================================
// ENTRADA POR TELEMÓVEL (ecrãs 01 e 11)
// =====================================================================

route(
  router,
  {
    method: 'post',
    path: '/auth/sms/pedir',
    tag: TAG,
    summary: 'Enviar código de entrada por SMS (RF01)',
    description:
      'Envia um código de 6 dígitos por SMS (simulado: aparece no terminal da API). A resposta é igual para números novos e ' +
      'existentes. Só se pode pedir outro código passado 1 minuto. Fora de produção, o código vem também em codigo_dev.',
    body: z.object({
      telemovel,
      perfil: perfilEscolhido.default('cliente'),
      criar_conta: z.boolean().default(false).openapi({ description: 'Veio de "Criar conta" no ecrã 01' }),
    }),
    status: 200,
  },
  async (req, res) => {
    const { telemovel: tel } = req.valid.body;
    const recentes = await queryOne<{ n: number; seg: number | null }>(
      `SELECT SUM(criado_em > NOW() - INTERVAL 10 MINUTE) AS n, TIMESTAMPDIFF(SECOND, MAX(criado_em), NOW()) AS seg
         FROM codigo_login WHERE telemovel = ?`,
      [tel],
    );
    if (recentes?.seg !== null && recentes?.seg !== undefined && recentes.seg < env.sms.reenviarS) {
      throw tooMany(`Pode pedir um novo código daqui a ${env.sms.reenviarS - recentes.seg} segundos.`);
    }
    if (Number(recentes?.n ?? 0) >= env.codigoMaxPer10Min) {
      throw tooMany('Pediu demasiados códigos. Aguarde 10 minutos e tente de novo.');
    }

    const codigo = codigo6();
    await execute(
      `INSERT INTO codigo_login (telemovel, codigo_hash, expira_em) VALUES (?, ?, NOW() + INTERVAL ? MINUTE)`,
      [tel, hashCodigo(tel, codigo), env.sms.expiraMin],
    );
    await enviarCodigoSms(tel, codigo);

    res.json({
      mensagem: `Enviámos um código por SMS para ${formatarTelemovel(tel)}.`,
      expira_em_min: env.sms.expiraMin,
      reenviar_em_s: env.sms.reenviarS,
      ...(isProduction ? {} : { codigo_dev: codigo }),
    });
  },
);

route(
  router,
  {
    method: 'post',
    path: '/auth/sms/verificar',
    tag: TAG,
    summary: 'Entrar ou criar conta com o código do SMS (RF01)',
    description:
      'Se o telemóvel ainda não tem conta, cria-a (é preciso aceita_privacidade: true). Com perfil = profissional, cria também o ' +
      'perfil profissional por completar. A sessão fica com o perfil escolhido (perfil_ativo). ' +
      'precisa_registo indica se a app deve abrir o registo profissional (ecrã 12).',
    body: z.object({
      telemovel,
      codigo: codigoSeisDigitos,
      perfil: perfilEscolhido.default('cliente'),
      aceita_privacidade: z.boolean().optional().openapi({ description: 'Consentimento RGPD (RNF10), obrigatório numa conta nova' }),
      nome: z.string().trim().min(2).max(100).optional(),
      dispositivo: z.string().max(100).optional(),
      push_token: z.string().max(255).optional(),
    }),
    status: 200,
  },
  async (req, res) => {
    const b = req.valid.body;
    const codigoId = await validarCodigo('telemovel', b.telemovel, b.codigo);

    const existente = await queryOne<{ id: number; ativo: boolean; tipo_perfil: TipoPerfil }>(
      `SELECT id, ativo, tipo_perfil FROM utilizador WHERE telemovel = ?`,
      [b.telemovel],
    );
    if (existente && !existente.ativo) throw new AppError(403, 'CONTA_DESATIVADA', 'Esta conta está desativada. Contacte o apoio.');
    if (!existente && b.aceita_privacidade !== true) {
      throw badRequest('Para criar conta, aceite a política de privacidade.', 'PRIVACIDADE_EM_FALTA');
    }

    const { utilizadorId, perfil, token } = await transaction(async (conn) => {
      await execute(`UPDATE codigo_login SET usado = TRUE WHERE id = ?`, [codigoId], conn);
      let id = existente?.id;
      if (!id) {
        const r = await execute(
          `INSERT INTO utilizador (telemovel, nome, tipo_perfil, consentimento_rgpd_em) VALUES (?, ?, ?, NOW())`,
          [b.telemovel, b.nome ?? null, b.perfil],
          conn,
        );
        id = r.insertId;
      }
      const perfil: TipoPerfil = existente?.tipo_perfil === 'admin' ? 'admin' : b.perfil;
      if (perfil === 'profissional') await garantirProfissional(id!, conn);
      const token = await abrirSessao(conn, id!, perfil, b);
      return { utilizadorId: id!, perfil, token };
    });

    const utilizador = (await euJSON(utilizadorId, perfil))!;
    res.json({
      token,
      novo: !existente,
      perfil_ativo: perfil,
      precisa_registo: perfil === 'profissional' && (!existente || !utilizador.profissional?.registo_completo),
      utilizador,
    });
  },
);

// =====================================================================
// ENTRADA POR EMAIL (alternativa, mantém-se)
// =====================================================================

route(
  router,
  {
    method: 'post',
    path: '/auth/codigo/pedir',
    tag: TAG,
    summary: 'Enviar código de entrada por email (RF01)',
    description: 'Envia um código de 6 dígitos para o email. Fora de produção, o código vem também em codigo_dev.',
    body: z.object({ email }),
    status: 200,
  },
  async (req, res) => {
    const { email: mail } = req.valid.body;
    const recentes = await queryOne<{ n: number }>(
      `SELECT COUNT(*) AS n FROM codigo_login WHERE email = ? AND criado_em > NOW() - INTERVAL 10 MINUTE`,
      [mail],
    );
    if ((recentes?.n ?? 0) >= env.codigoMaxPer10Min) {
      throw tooMany('Pediu demasiados códigos. Aguarde 10 minutos e tente de novo.');
    }

    const codigo = codigo6();
    await execute(
      `INSERT INTO codigo_login (email, codigo_hash, expira_em) VALUES (?, ?, NOW() + INTERVAL ? MINUTE)`,
      [mail, hashCodigo(mail, codigo), env.codigoExpiresMin],
    );
    await enviarCodigoEntrada(mail, codigo);

    res.json({
      mensagem: 'Enviámos um código para o seu email.',
      expira_em_min: env.codigoExpiresMin,
      ...(isProduction ? {} : { codigo_dev: codigo }),
    });
  },
);

route(
  router,
  {
    method: 'post',
    path: '/auth/codigo/verificar',
    tag: TAG,
    summary: 'Entrar ou criar conta com o código do email (RF01)',
    description:
      'Se o email ainda não tem conta, envie também nome, telemovel, tipo_perfil e aceita_privacidade para criar a conta. ' +
      'Sem esses dados devolve 400 REGISTO_INCOMPLETO (a app mostra o passo de registo). O código só é gasto quando a entrada é concluída.',
    body: z.object({
      email,
      codigo: codigoSeisDigitos,
      nome: z.string().trim().min(2).max(100).optional(),
      telemovel: telemovel.optional(),
      tipo_perfil: perfilEscolhido.optional(),
      aceita_privacidade: z.boolean().optional().openapi({ description: 'Consentimento RGPD (RNF10)' }),
      dispositivo: z.string().max(100).optional(),
      push_token: z.string().max(255).optional(),
    }),
    status: 200,
  },
  async (req, res) => {
    const b = req.valid.body;
    const codigoId = await validarCodigo('email', b.email, b.codigo);

    const existente = await queryOne<{ id: number; ativo: boolean; tipo_perfil: TipoPerfil }>(
      `SELECT id, ativo, tipo_perfil FROM utilizador WHERE email = ?`,
      [b.email],
    );
    if (existente && !existente.ativo) throw new AppError(403, 'CONTA_DESATIVADA', 'Esta conta está desativada. Contacte o apoio.');
    if (!existente) {
      if (!b.nome || !b.telemovel || !b.tipo_perfil || b.aceita_privacidade !== true) {
        throw badRequest('Email novo: indique nome, telemóvel, perfil e aceite a política de privacidade.', 'REGISTO_INCOMPLETO');
      }
      await garantirTelemovelLivre(b.telemovel);
    }

    const { utilizadorId, perfil, token } = await transaction(async (conn) => {
      await execute(`UPDATE codigo_login SET usado = TRUE WHERE id = ?`, [codigoId], conn);
      let id = existente?.id;
      if (!id) {
        const r = await execute(
          `INSERT INTO utilizador (email, telemovel, nome, tipo_perfil, consentimento_rgpd_em) VALUES (?, ?, ?, ?, NOW())`,
          [b.email, b.telemovel, b.nome, b.tipo_perfil],
          conn,
        );
        id = r.insertId;
        if (b.tipo_perfil === 'profissional') await garantirProfissional(id, conn);
      }
      // Pelo email, a sessão começa no perfil da conta
      const perfil: TipoPerfil = existente?.tipo_perfil ?? b.tipo_perfil;
      return { utilizadorId: id!, perfil, token: await abrirSessao(conn, id!, perfil, b) };
    });

    res.json({ token, novo: !existente, perfil_ativo: perfil, utilizador: await euJSON(utilizadorId, perfil) });
  },
);

// =====================================================================
// SESSÃO E CONTA
// =====================================================================

route(
  router,
  { method: 'post', path: '/auth/sair', tag: TAG, summary: 'Terminar a sessão neste dispositivo', access: 'auth', status: 200 },
  async (req, res) => {
    await execute(`UPDATE sessao SET revogada = TRUE WHERE id = ?`, [req.user!.sessao_id]);
    res.json(null);
  },
);

route(
  router,
  {
    method: 'get',
    path: '/eu',
    tag: TAG,
    summary: 'Dados da minha conta (EuJSON)',
    description: 'A zona e o perfil_ativo seguem o perfil com que a sessão está a usar a app.',
    access: 'auth',
  },
  async (req, res) => {
    res.json(await euJSON(req.user!.id, req.user!.tipo_perfil));
  },
);

route(
  router,
  {
    method: 'put',
    path: '/eu/perfil-ativo',
    tag: TAG,
    summary: 'Mudar para cliente ou para profissional (ecrã 20)',
    description:
      'Muda o perfil desta sessão. Ao passar a profissional pela primeira vez, cria o perfil profissional por completar ' +
      '(a app segue para o registo, ecrã 12). A conta de administração não muda de perfil.',
    access: 'auth',
    body: z.object({ perfil: perfilEscolhido }),
    status: 200,
  },
  async (req, res) => {
    if (req.user!.tipo_conta === 'admin') throw forbidden('A conta de administração não muda de perfil.');
    const { perfil } = req.valid.body;
    await transaction(async (conn) => {
      if (perfil === 'profissional') await garantirProfissional(req.user!.id, conn);
      await execute(`UPDATE sessao SET perfil_ativo = ? WHERE id = ?`, [perfil, req.user!.sessao_id], conn);
    });
    res.json({ perfil_ativo: perfil, utilizador: await euJSON(req.user!.id, perfil) });
  },
);

route(
  router,
  {
    method: 'patch',
    path: '/eu',
    tag: TAG,
    summary: 'Atualizar nome, telemóvel, email ou token de push',
    access: 'auth',
    body: z.object({
      nome: z.string().trim().min(2).max(100).optional(),
      telemovel: telemovel.optional(),
      email: email.optional(),
      push_token: z.string().max(255).nullable().optional(),
    }),
  },
  async (req, res) => {
    const { nome, telemovel: tel, email: mail, push_token } = req.valid.body;
    if (nome !== undefined) await execute(`UPDATE utilizador SET nome = ? WHERE id = ?`, [nome, req.user!.id]);
    if (tel !== undefined) {
      await garantirTelemovelLivre(tel, req.user!.id);
      await execute(`UPDATE utilizador SET telemovel = ? WHERE id = ?`, [tel, req.user!.id]);
    }
    if (mail !== undefined) {
      const outro = await queryOne(`SELECT id FROM utilizador WHERE email = ? AND id <> ?`, [mail, req.user!.id]);
      if (outro) throw conflict('Este email já está associado a outra conta.', 'EMAIL_EM_USO');
      await execute(`UPDATE utilizador SET email = ? WHERE id = ?`, [mail, req.user!.id]);
    }
    if (push_token !== undefined) await execute(`UPDATE sessao SET push_token = ? WHERE id = ?`, [push_token, req.user!.sessao_id]);
    res.json(await euJSON(req.user!.id, req.user!.tipo_perfil));
  },
);

route(
  router,
  { method: 'put', path: '/eu/foto', tag: TAG, summary: 'Mudar a foto de perfil', access: 'auth', files: { foto: 1 } },
  async (req, res) => {
    const [foto] = ficheiros(req, 'foto');
    if (!foto) throw badRequest('Envie a imagem no campo "foto".');
    const url = await guardarImagem(foto, 'perfis');
    await execute(`UPDATE utilizador SET foto_url = ? WHERE id = ?`, [url, req.user!.id]);
    res.json({ foto_url: url });
  },
);

route(
  router,
  {
    method: 'delete',
    path: '/eu',
    tag: TAG,
    summary: 'Desativar a minha conta (RGPD)',
    description: 'Desativa a conta e termina todas as sessões. O histórico de serviços é mantido para os comprovativos.',
    access: 'auth',
    status: 200,
  },
  async (req, res) => {
    await execute(`UPDATE utilizador SET ativo = FALSE WHERE id = ?`, [req.user!.id]);
    await execute(`UPDATE sessao SET revogada = TRUE WHERE utilizador_id = ?`, [req.user!.id]);
    res.json(null);
  },
);

export default router;
