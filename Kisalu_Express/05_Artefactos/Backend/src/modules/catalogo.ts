import { Router } from 'express';
import { z } from 'zod';
import { query } from '../config/db';
import { route } from '../utils/route';

const router = Router();
const TAG = 'Catálogo e ajuda';

route(
  router,
  {
    method: 'get',
    path: '/categorias',
    tag: TAG,
    summary: 'Categorias de serviço com ícone e rótulo (RF02)',
    description: 'As 13 categorias da app. chave é o identificador usado pela app; em_destaque marca as 8 da grelha do Início.',
  },
  async (_req, res) => {
    const rows = await query(
      `SELECT c.id, c.chave, c.nome, c.plural, c.em_destaque, c.icone,
              (SELECT COUNT(*) FROM profissional_categoria pc
                 JOIN profissional p ON p.utilizador_id = pc.profissional_id AND p.disponivel = TRUE
                 JOIN utilizador u ON u.id = p.utilizador_id AND u.ativo = TRUE
                WHERE pc.categoria_id = c.id) AS profissionais_disponiveis
         FROM categoria c WHERE c.ativa = TRUE ORDER BY c.ordem, c.nome`,
    );
    res.json(rows.map((c) => ({ ...c, em_destaque: !!c.em_destaque, profissionais_disponiveis: Number(c.profissionais_disponiveis) })));
  },
);

route(
  router,
  {
    method: 'get',
    path: '/etiquetas',
    tag: TAG,
    summary: 'Etiquetas rápidas para avaliar (RF12)',
    description: 'A app envia a chave: pontual, preco_justo, simpatico, trabalho_limpo, rapido.',
  },
  async (_req, res) => {
    res.json(await query(`SELECT id, chave, nome FROM etiqueta ORDER BY id`));
  },
);

route(
  router,
  {
    method: 'get',
    path: '/ajuda/perguntas',
    tag: TAG,
    summary: 'Perguntas frequentes (RF16)',
    query: z.object({ tema: z.string().optional(), q: z.string().optional() }),
  },
  async (req, res) => {
    const { tema, q } = req.valid.query;
    const where = ['ativa = TRUE'];
    const params: unknown[] = [];
    if (tema) { where.push('tema = ?'); params.push(tema); }
    if (q) { where.push('(pergunta LIKE ? OR resposta LIKE ?)'); params.push(`%${q}%`, `%${q}%`); }
    res.json(
      await query(`SELECT id, tema, pergunta, resposta FROM pergunta_frequente WHERE ${where.join(' AND ')} ORDER BY ordem, id`, params),
    );
  },
);

export default router;
