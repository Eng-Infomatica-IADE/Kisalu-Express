import { Router } from 'express';
import { z } from 'zod';
import { execute, query, queryOne, transaction } from '../config/db';
import { notFound } from '../utils/errors';
import { idParam, route } from '../utils/route';

const router = Router();
const TAG = 'Moradas e favoritos';

const moradaBody = z.object({
  rotulo: z.string().trim().min(1).max(40).default('Casa'),
  endereco: z.string().trim().min(3).max(200),
  ponto_referencia: z.string().trim().max(200).nullable().optional().openapi({ example: 'Perto da cantina do Sr. Zé' }),
  bairro: z.string().trim().max(80).nullable().optional(),
  municipio: z.string().trim().min(2).max(80),
  provincia: z.string().trim().max(60).default('Luanda'),
  latitude: z.number().min(-90).max(90).nullable().optional(),
  longitude: z.number().min(-180).max(180).nullable().optional(),
  predefinida: z.boolean().default(false),
});

const CAMPOS = 'id, rotulo, endereco, ponto_referencia, bairro, municipio, provincia, latitude, longitude, predefinida';

// ---------------- Moradas guardadas (RM05) ----------------

route(router, { method: 'get', path: '/moradas', tag: TAG, summary: 'As minhas moradas', access: 'auth' }, async (req, res) => {
  res.json(await query(`SELECT ${CAMPOS} FROM morada WHERE utilizador_id = ? ORDER BY predefinida DESC, id`, [req.user!.id]));
});

route(
  router,
  { method: 'post', path: '/moradas', tag: TAG, summary: 'Guardar morada (GPS + ponto de referência)', access: 'auth', body: moradaBody },
  async (req, res) => {
    const m = req.valid.body;
    const id = await transaction(async (conn) => {
      const total = await queryOne<{ n: number }>(`SELECT COUNT(*) n FROM morada WHERE utilizador_id = ?`, [req.user!.id], conn);
      const predefinida = m.predefinida || total!.n === 0; // a primeira morada fica predefinida
      if (predefinida) await execute(`UPDATE morada SET predefinida = FALSE WHERE utilizador_id = ?`, [req.user!.id], conn);
      const r = await execute(
        `INSERT INTO morada (utilizador_id, rotulo, endereco, ponto_referencia, bairro, municipio, provincia, latitude, longitude, predefinida)
         VALUES (?,?,?,?,?,?,?,?,?,?)`,
        [req.user!.id, m.rotulo, m.endereco, m.ponto_referencia ?? null, m.bairro ?? null, m.municipio, m.provincia, m.latitude ?? null, m.longitude ?? null, predefinida],
        conn,
      );
      return r.insertId;
    });
    res.status(201).json(await queryOne(`SELECT ${CAMPOS} FROM morada WHERE id = ?`, [id]));
  },
);

route(
  router,
  { method: 'put', path: '/moradas/:id', tag: TAG, summary: 'Editar morada', access: 'auth', params: idParam, body: moradaBody },
  async (req, res) => {
    const { id } = req.valid.params;
    const m = req.valid.body;
    await transaction(async (conn) => {
      const atual = await queryOne(`SELECT id FROM morada WHERE id = ? AND utilizador_id = ? FOR UPDATE`, [id, req.user!.id], conn);
      if (!atual) throw notFound('Morada');
      if (m.predefinida) await execute(`UPDATE morada SET predefinida = FALSE WHERE utilizador_id = ?`, [req.user!.id], conn);
      await execute(
        `UPDATE morada SET rotulo=?, endereco=?, ponto_referencia=?, bairro=?, municipio=?, provincia=?, latitude=?, longitude=?, predefinida=?
          WHERE id = ?`,
        [m.rotulo, m.endereco, m.ponto_referencia ?? null, m.bairro ?? null, m.municipio, m.provincia, m.latitude ?? null, m.longitude ?? null, m.predefinida, id],
        conn,
      );
    });
    res.json(await queryOne(`SELECT ${CAMPOS} FROM morada WHERE id = ?`, [id]));
  },
);

route(
  router,
  { method: 'delete', path: '/moradas/:id', tag: TAG, summary: 'Apagar morada (não usada em pedidos)', access: 'auth', params: idParam, status: 200 },
  async (req, res) => {
    const r = await execute(`DELETE FROM morada WHERE id = ? AND utilizador_id = ?`, [req.valid.params.id, req.user!.id]);
    if (!r.affectedRows) throw notFound('Morada');
    res.json(null);
  },
);

// ---------------- Favoritos (RF13) ----------------

route(router, { method: 'get', path: '/favoritos', tag: TAG, summary: 'Profissionais favoritos', access: ['cliente'] }, async (req, res) => {
  res.json(
    await query(
      `SELECT p.utilizador_id AS id, u.nome, u.foto_url, p.verificado, p.media_avaliacao, p.total_avaliacoes, p.total_servicos,
              GROUP_CONCAT(c.nome ORDER BY c.nome SEPARATOR ', ') AS categorias, f.criado_em AS favorito_desde
         FROM favorito f
         JOIN profissional p ON p.utilizador_id = f.profissional_id
         JOIN utilizador u ON u.id = p.utilizador_id
         LEFT JOIN profissional_categoria pc ON pc.profissional_id = p.utilizador_id
         LEFT JOIN categoria c ON c.id = pc.categoria_id
        WHERE f.cliente_id = ?
        GROUP BY p.utilizador_id, f.criado_em
        ORDER BY f.criado_em DESC`,
      [req.user!.id],
    ),
  );
});

const profParam = z.object({ profissionalId: z.coerce.number().int().positive() });

route(
  router,
  { method: 'put', path: '/favoritos/:profissionalId', tag: TAG, summary: 'Adicionar aos favoritos', access: ['cliente'], params: profParam, status: 200 },
  async (req, res) => {
    const prof = await queryOne(`SELECT utilizador_id FROM profissional WHERE utilizador_id = ?`, [req.valid.params.profissionalId]);
    if (!prof) throw notFound('Profissional');
    await execute(`INSERT IGNORE INTO favorito (cliente_id, profissional_id) VALUES (?, ?)`, [req.user!.id, req.valid.params.profissionalId]);
    res.json(null);
  },
);

route(
  router,
  { method: 'delete', path: '/favoritos/:profissionalId', tag: TAG, summary: 'Remover dos favoritos', access: ['cliente'], params: profParam, status: 200 },
  async (req, res) => {
    await execute(`DELETE FROM favorito WHERE cliente_id = ? AND profissional_id = ?`, [req.user!.id, req.valid.params.profissionalId]);
    res.json(null);
  },
);

export default router;
