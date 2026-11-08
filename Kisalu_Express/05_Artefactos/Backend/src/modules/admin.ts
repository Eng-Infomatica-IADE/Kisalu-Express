import { Router } from 'express';
import { z } from 'zod';
import { execute, query, queryOne, transaction } from '../config/db';
import { badRequest, conflict, notFound } from '../utils/errors';
import { idParam, paginacao, route } from '../utils/route';
import { notificar } from '../services/notificacoes';
import { caminhoPrivado, enviarImagemPrivada } from '../middlewares/upload';

/** URL da API por onde o admin vê uma imagem privada (null se não houver ficheiro real) */
const urlPrivada = (guardado: string | null, url: string) => (guardado && !guardado.startsWith('simulado://') ? url : null);

const router = Router();
const TAG = 'Administração';
const ADMIN = ['admin'] as const;

route(
  router,
  {
    method: 'get',
    path: '/admin/verificacoes',
    tag: TAG,
    summary: 'Pedidos de verificação de identidade',
    access: [...ADMIN],
    query: paginacao.extend({ estado: z.enum(['pendente', 'aprovada', 'rejeitada']).default('pendente') }),
  },
  async (req, res) => {
    const { estado, limit, offset } = req.valid.query;
    const rows = await query(
      `SELECT v.id, v.profissional_id, u.nome, u.telemovel, v.tipo_documento, v.numero_documento, v.documento_url, v.selfie_url,
              v.estado, v.motivo_rejeicao, v.submetido_em, v.revisto_em
         FROM verificacao_identidade v JOIN utilizador u ON u.id = v.profissional_id
        WHERE v.estado = ? ORDER BY v.submetido_em LIMIT ? OFFSET ?`,
      [estado, limit, offset],
    );
    // Os ficheiros não são públicos: em vez do caminho no disco, o URL do endpoint de admin
    res.json(
      rows.map((v) => ({
        ...v,
        documento_url: urlPrivada(v.documento_url, `/api/admin/verificacoes/${v.id}/documento`),
        selfie_url: urlPrivada(v.selfie_url, `/api/admin/verificacoes/${v.id}/selfie`),
        simulada: String(v.documento_url ?? '').startsWith('simulado://') || String(v.selfie_url ?? '').startsWith('simulado://'),
      })),
    );
  },
);

route(
  router,
  {
    method: 'get',
    path: '/admin/verificacoes/:id/:ficheiro',
    tag: TAG,
    summary: 'Ver o documento de identidade ou a fotografia do rosto (só admin)',
    description: 'ficheiro: documento ou selfie. Devolve a imagem JPEG. Estes ficheiros não estão em /uploads.',
    access: [...ADMIN],
    params: idParam.extend({ ficheiro: z.enum(['documento', 'selfie']) }),
  },
  async (req, res) => {
    const v = await queryOne(`SELECT documento_url, selfie_url FROM verificacao_identidade WHERE id = ?`, [req.valid.params.id]);
    if (!v) throw notFound('Verificação');
    const abs = await caminhoPrivado(req.valid.params.ficheiro === 'documento' ? v.documento_url : v.selfie_url);
    await enviarImagemPrivada(res, abs);
  },
);

route(
  router,
  {
    method: 'post',
    path: '/admin/verificacoes/:id/decidir',
    tag: TAG,
    summary: 'Aprovar ou rejeitar verificação (atribui o selo Verificado)',
    access: [...ADMIN],
    params: idParam,
    body: z
      .object({ aprovar: z.boolean(), motivo_rejeicao: z.string().trim().max(255).optional() })
      .refine((b) => b.aprovar || b.motivo_rejeicao, { message: 'Explique o motivo ao profissional', path: ['motivo_rejeicao'] }),
    status: 200,
  },
  async (req, res) => {
    const { aprovar, motivo_rejeicao } = req.valid.body;
    await transaction(async (conn) => {
      const v = await queryOne(`SELECT * FROM verificacao_identidade WHERE id = ? FOR UPDATE`, [req.valid.params.id], conn);
      if (!v) throw notFound('Verificação');
      if (v.estado !== 'pendente') throw conflict('Esta verificação já foi decidida.');
      await execute(
        `UPDATE verificacao_identidade SET estado = ?, motivo_rejeicao = ?, revisto_por = ?, revisto_em = NOW() WHERE id = ?`,
        [aprovar ? 'aprovada' : 'rejeitada', aprovar ? null : motivo_rejeicao, req.user!.id, v.id],
        conn,
      );
      if (aprovar) await execute(`UPDATE profissional SET verificado = TRUE, verificado_em = NOW() WHERE utilizador_id = ?`, [v.profissional_id], conn);
      await notificar(
        v.profissional_id,
        aprovar
          ? { tipo: 'sistema', titulo: 'Já é Verificado', corpo: 'O selo Verificado aparece agora no seu perfil e nas propostas.' }
          : { tipo: 'sistema', titulo: 'Verificação não aprovada', corpo: motivo_rejeicao! },
        conn,
      );
    });
    res.json({ id: req.valid.params.id, estado: aprovar ? 'aprovada' : 'rejeitada' });
  },
);

route(
  router,
  {
    method: 'get',
    path: '/admin/reclamacoes',
    tag: TAG,
    summary: 'Reclamações para acompanhar (RF11)',
    access: [...ADMIN],
    query: paginacao.extend({ estado: z.enum(['aberta', 'em_analise', 'resolvida', 'rejeitada']).optional() }),
  },
  async (req, res) => {
    const { estado, limit, offset } = req.valid.query;
    const rows = await query(
      `SELECT r.*, pe.titulo, ua.nome AS autor, cs.valor_acordado, cs.numero_comprovativo
         FROM reclamacao r JOIN pedido pe ON pe.id = r.pedido_id JOIN utilizador ua ON ua.id = r.autor_id
         LEFT JOIN confirmacao_servico cs ON cs.pedido_id = pe.id
        ${estado ? 'WHERE r.estado = ?' : ''} ORDER BY r.criado_em LIMIT ? OFFSET ?`,
      [...(estado ? [estado] : []), limit, offset],
    );
    res.json(rows.map((r) => ({ ...r, foto_url: urlPrivada(r.foto_url, `/api/admin/reclamacoes/${r.id}/foto`) })));
  },
);

route(
  router,
  {
    method: 'get',
    path: '/admin/reclamacoes/:id/foto',
    tag: TAG,
    summary: 'Ver a foto junta a uma reclamação (só admin)',
    description: 'Devolve a imagem JPEG. As fotos das reclamações não estão em /uploads.',
    access: [...ADMIN],
    params: idParam,
  },
  async (req, res) => {
    const r = await queryOne(`SELECT foto_url FROM reclamacao WHERE id = ?`, [req.valid.params.id]);
    if (!r) throw notFound('Reclamação');
    const abs = await caminhoPrivado(r.foto_url);
    await enviarImagemPrivada(res, abs);
  },
);

route(
  router,
  {
    method: 'patch',
    path: '/admin/reclamacoes/:id',
    tag: TAG,
    summary: 'Atualizar o estado de uma reclamação',
    access: [...ADMIN],
    params: idParam,
    body: z.object({ estado: z.enum(['em_analise', 'resolvida', 'rejeitada']), resolucao: z.string().trim().max(500).optional() }),
  },
  async (req, res) => {
    const { estado, resolucao } = req.valid.body;
    if (estado !== 'em_analise' && !resolucao) throw badRequest('Escreva a resolução para o utilizador.');
    const r = await queryOne(`SELECT id, autor_id, pedido_id FROM reclamacao WHERE id = ?`, [req.valid.params.id]);
    if (!r) throw notFound('Reclamação');
    await execute(
      `UPDATE reclamacao SET estado = ?, resolucao = COALESCE(?, resolucao), resolvida_em = ${estado === 'em_analise' ? 'NULL' : 'NOW()'} WHERE id = ?`,
      [estado, resolucao ?? null, r.id],
    );
    await notificar(r.autor_id, { tipo: 'reclamacao', titulo: 'Atualização da sua reclamação', corpo: resolucao ?? 'Estamos a analisar o seu caso.', pedido_id: r.pedido_id });
    res.json(await queryOne(`SELECT id, estado, resolucao, resolvida_em FROM reclamacao WHERE id = ?`, [r.id]));
  },
);

export default router;
