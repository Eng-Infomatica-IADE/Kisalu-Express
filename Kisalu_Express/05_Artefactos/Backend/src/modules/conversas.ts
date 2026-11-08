import { Router } from 'express';
import { z } from 'zod';
import { execute, query, queryOne } from '../config/db';
import { badRequest, conflict, notFound } from '../utils/errors';
import { idParam, paginacao, route } from '../utils/route';
import { ficheiros, guardarImagem } from '../middlewares/upload';
import * as Utilizador from '../models/utilizadorModel';
import * as Conversa from '../models/conversaModel';
import { notificar } from '../services/notificacoes';
import { carregarPedido } from '../services/pedidos';
import { kz, Leitor, mensagemJSON, nomeCurto, resumosProfissionais, semCoordenadas } from '../services/formatos';

const router = Router();
const TAG = 'Conversas e notificações';

/** Devolve a conversa se o utilizador participa (cliente do pedido ou profissional da conversa) */
async function conversaDoUtilizador(conversaId: number, userId: number) {
  const c = await queryOne(
    `SELECT c.id, c.pedido_id, c.profissional_id, pe.cliente_id, pe.estado AS estado_pedido
       FROM conversa c JOIN pedido pe ON pe.id = c.pedido_id WHERE c.id = ?`,
    [conversaId],
  );
  if (!c || (c.cliente_id !== userId && c.profissional_id !== userId)) throw notFound('Conversa');
  return c;
}

/**
 * ConversaJSON (contrato, secção 1). O interlocutor é o profissional (ProfissionalResumo) quando quem lê é o
 * cliente, e o cliente abreviado ({id, nome: "Maria K.", e_cliente: true}) quando quem lê é o profissional.
 * valor = valor acordado, ou o da proposta desse profissional.
 */
async function conversasJSON(where: string, params: unknown[], leitor: Leitor, mensagensPorConversa: number) {
  const rows = await query(
    `SELECT c.id, c.pedido_id, c.profissional_id, c.criado_em, pe.titulo AS pedido_titulo, pe.cliente_id, pe.estado AS estado_pedido,
            cat.chave AS categoria_chave, uc.nome AS cliente_nome, uc.foto_url AS cliente_foto,
            COALESCE(IF(pe.proposta_aceite_id = pr.id, cs.valor_acordado, NULL), pr.valor_total) AS valor,
            (SELECT COUNT(*) FROM mensagem m WHERE m.conversa_id = c.id AND m.remetente_id <> ? AND m.lida_em IS NULL) AS nao_lidas,
            (SELECT MAX(m.enviada_em) FROM mensagem m WHERE m.conversa_id = c.id) AS ultima_em
       FROM conversa c
       JOIN pedido pe ON pe.id = c.pedido_id
       JOIN categoria cat ON cat.id = pe.categoria_id
       JOIN utilizador uc ON uc.id = pe.cliente_id
       LEFT JOIN proposta pr ON pr.pedido_id = c.pedido_id AND pr.profissional_id = c.profissional_id
       LEFT JOIN confirmacao_servico cs ON cs.pedido_id = c.pedido_id
      WHERE ${where}
      ORDER BY COALESCE(ultima_em, c.criado_em) DESC, c.id DESC`,
    [leitor.id, ...params],
  );
  if (!rows.length) return [];

  const resumos = await resumosProfissionais(rows.map((r) => r.profissional_id));
  const ids = rows.map((r) => r.id);
  const mensagens = await query(
    `SELECT id, conversa_id, remetente_id, texto, foto_url, enviada_em, lida_em FROM (
       SELECT m.*, ROW_NUMBER() OVER (PARTITION BY m.conversa_id ORDER BY m.id DESC) AS n
         FROM mensagem m WHERE m.conversa_id IN (?)
     ) AS ultimas
     WHERE n <= ? ORDER BY id`,
    [ids, mensagensPorConversa],
  );

  return rows.map((r) => ({
    id: r.id,
    pedido_id: r.pedido_id,
    pedido_titulo: r.pedido_titulo,
    categoria_chave: r.categoria_chave,
    estado_pedido: r.estado_pedido,
    valor: kz(r.valor),
    nao_lidas: Number(r.nao_lidas),
    ultima_em: r.ultima_em,
    interlocutor:
      r.cliente_id === leitor.id
        ? semCoordenadas(resumos.get(r.profissional_id))
        : { id: r.cliente_id, nome: nomeCurto(r.cliente_nome), foto_url: r.cliente_foto, e_cliente: true },
    mensagens: mensagens.filter((m) => m.conversa_id === r.id).map((m) => mensagemJSON(m, leitor.id)),
  }));
}

// ---------------- Conversas (RF09, ecrãs 18 e 19) ----------------

route(
  router,
  {
    method: 'get',
    path: '/conversas',
    tag: TAG,
    summary: 'Lista de conversas, uma por pedido e profissional (RF09, ecrã 18)',
    description:
      'ConversaJSON com só a última mensagem, mais recentes primeiro. Segue o perfil ativo: como cliente, as conversas dos seus ' +
      'pedidos; como profissional, as conversas em que é o profissional.',
    access: 'auth',
  },
  async (req, res) => {
    const u = req.user!;
    const where =
      u.tipo_perfil === 'cliente' ? 'pe.cliente_id = ?'
      : u.tipo_perfil === 'profissional' ? 'c.profissional_id = ?'
      : '(pe.cliente_id = ? OR c.profissional_id = ?)';
    res.json(await conversasJSON(where, u.tipo_perfil === 'admin' ? [u.id, u.id] : [u.id], u, 1));
  },
);

route(
  router,
  {
    method: 'get',
    path: '/conversas/:id',
    tag: TAG,
    summary: 'Conversa com as últimas 50 mensagens (ecrã 19)',
    description: 'ConversaJSON com as mensagens por ordem ascendente. Não marca como lidas: use POST /conversas/{id}/lida.',
    access: 'auth',
    params: idParam,
  },
  async (req, res) => {
    const c = await conversaDoUtilizador(req.valid.params.id, req.user!.id);
    const [conversa] = await conversasJSON('c.id = ?', [c.id], req.user!, 50);
    res.json(conversa);
  },
);

route(
  router,
  {
    method: 'post',
    path: '/conversas/:id/lida',
    tag: TAG,
    summary: 'Marcar a conversa como lida (ecrã 19)',
    description: 'Marca como lidas as mensagens do outro participante. Devolve {nao_lidas: 0}.',
    access: 'auth',
    params: idParam,
    status: 200,
  },
  async (req, res) => {
    const c = await conversaDoUtilizador(req.valid.params.id, req.user!.id);
    await execute(`UPDATE mensagem SET lida_em = NOW() WHERE conversa_id = ? AND remetente_id <> ? AND lida_em IS NULL`, [c.id, req.user!.id]);
    res.json({ id: c.id, nao_lidas: 0 });
  },
);

route(
  router,
  {
    method: 'post',
    path: '/pedidos/:id/conversas',
    tag: TAG,
    summary: 'Cliente: abrir conversa com um profissional que enviou proposta',
    description: 'Útil para tirar dúvidas antes de aceitar. Devolve a conversa existente se já houver.',
    access: ['cliente'],
    params: idParam,
    body: z.object({ profissional_id: z.number().int().positive() }),
    status: 200,
  },
  async (req, res) => {
    const p = await carregarPedido(req.valid.params.id);
    if (p.cliente_id !== req.user!.id) throw notFound('Pedido');
    const proposta = await queryOne(`SELECT id FROM proposta WHERE pedido_id = ? AND profissional_id = ?`, [p.id, req.valid.body.profissional_id]);
    if (!proposta) throw badRequest('Esse profissional não respondeu a este pedido.');
    await Conversa.abrirConversa(p.id, req.valid.body.profissional_id);
    res.json(await queryOne(`SELECT id, pedido_id, profissional_id FROM conversa WHERE pedido_id = ? AND profissional_id = ?`, [p.id, req.valid.body.profissional_id]));
  },
);

route(
  router,
  {
    method: 'get',
    path: '/conversas/:id/mensagens',
    tag: TAG,
    summary: 'Mensagens da conversa, com paginação (marca como lidas)',
    description: 'Paginação para trás: passe antes_de = id da mensagem mais antiga que já tem.',
    access: 'auth',
    params: idParam,
    query: z.object({ antes_de: z.coerce.number().int().optional(), limit: paginacao.shape.limit }),
  },
  async (req, res) => {
    const c = await conversaDoUtilizador(req.valid.params.id, req.user!.id);
    const { antes_de, limit } = req.valid.query;
    const msgs = await query(
      `SELECT m.id, m.remetente_id, u.nome AS remetente, m.texto, m.foto_url, m.enviada_em, m.lida_em
         FROM mensagem m JOIN utilizador u ON u.id = m.remetente_id
        WHERE m.conversa_id = ? ${antes_de ? 'AND m.id < ?' : ''}
        ORDER BY m.id DESC LIMIT ?`,
      [c.id, ...(antes_de ? [antes_de] : []), limit],
    );
    await execute(`UPDATE mensagem SET lida_em = NOW() WHERE conversa_id = ? AND remetente_id <> ? AND lida_em IS NULL`, [c.id, req.user!.id]);
    res.json(msgs.reverse().map((m) => ({ ...mensagemJSON(m, req.user!.id), remetente_id: m.remetente_id, remetente: m.remetente })));
  },
);

route(
  router,
  {
    method: 'post',
    path: '/conversas/:id/mensagens',
    tag: TAG,
    summary: 'Enviar mensagem com texto e/ou foto (RF09, ecrã 19)',
    description: 'JSON {texto} (até 1000 caracteres) ou multipart com texto e foto. Devolve a MensagemJSON.',
    access: 'auth',
    params: idParam,
    files: { foto: 1 },
    body: z.object({ texto: z.string().trim().max(1000, 'A mensagem tem no máximo 1000 caracteres').optional() }),
  },
  async (req, res) => {
    const c = await conversaDoUtilizador(req.valid.params.id, req.user!.id);
    if (c.estado_pedido === 'cancelado') throw conflict('Este pedido foi cancelado; a conversa está fechada.');
    const [foto] = ficheiros(req, 'foto');
    const texto = req.valid.body.texto || null;
    if (!texto && !foto) throw badRequest('Escreva uma mensagem ou junte uma foto.');
    const fotoUrl = foto ? await guardarImagem(foto, 'chat') : null;
    const r = await execute(`INSERT INTO mensagem (conversa_id, remetente_id, texto, foto_url) VALUES (?,?,?,?)`, [c.id, req.user!.id, texto, fotoUrl]);

    const destinatario = req.user!.id === c.cliente_id ? c.profissional_id : c.cliente_id;
    const remetente = await Utilizador.nome(req.user!.id);
    await notificar(destinatario, {
      tipo: 'nova_mensagem', titulo: remetente ?? 'Nova mensagem', corpo: texto ? texto.slice(0, 120) : 'Foto enviada', pedido_id: c.pedido_id, acao: 'abrir_conversa',
    });

    const m = await queryOne(`SELECT id, remetente_id, texto, foto_url, enviada_em, lida_em FROM mensagem WHERE id = ?`, [r.insertId]);
    res.status(201).json(mensagemJSON(m, req.user!.id));
  },
);

// ---------------- Notificações (RM06) ----------------

route(
  router,
  {
    method: 'get',
    path: '/notificacoes',
    tag: TAG,
    summary: 'As minhas notificações',
    access: 'auth',
    query: paginacao.extend({ so_nao_lidas: z.enum(['true', 'false']).default('false') }),
  },
  async (req, res) => {
    const { limit, offset, so_nao_lidas } = req.valid.query;
    const [lista, contagem] = await Promise.all([
      query(
        `SELECT id, tipo, titulo, corpo, pedido_id, acao, lida, criado_em FROM notificacao
          WHERE utilizador_id = ? ${so_nao_lidas === 'true' ? 'AND lida = FALSE' : ''}
          ORDER BY id DESC LIMIT ? OFFSET ?`,
        [req.user!.id, limit, offset],
      ),
      queryOne<{ n: number }>(`SELECT COUNT(*) n FROM notificacao WHERE utilizador_id = ? AND lida = FALSE`, [req.user!.id]),
    ]);
    res.json({ nao_lidas: contagem!.n, notificacoes: lista });
  },
);

route(
  router,
  { method: 'post', path: '/notificacoes/:id/lida', tag: TAG, summary: 'Marcar notificação como lida', access: 'auth', params: idParam, status: 200 },
  async (req, res) => {
    await execute(`UPDATE notificacao SET lida = TRUE WHERE id = ? AND utilizador_id = ?`, [req.valid.params.id, req.user!.id]);
    res.json(null);
  },
);

route(
  router,
  { method: 'post', path: '/notificacoes/lidas', tag: TAG, summary: 'Marcar todas como lidas', access: 'auth', status: 200 },
  async (req, res) => {
    await execute(`UPDATE notificacao SET lida = TRUE WHERE utilizador_id = ? AND lida = FALSE`, [req.user!.id]);
    res.json(null);
  },
);

export default router;
