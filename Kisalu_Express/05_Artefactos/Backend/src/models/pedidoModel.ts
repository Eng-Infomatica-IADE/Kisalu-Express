/**
 * Model dos pedidos: todo o SQL sobre pedido, morada do pedido, fotos e histórico.
 * Os controllers chamam estas funções; não escrevem SQL.
 */
import { Db, execute, pool, query, queryOne } from '../config/db';
import { distanciaKmSql, geoParams } from '../utils/geo';

export { carregarPedido, ESTADOS_ABERTOS, ESTADOS_ATIVOS } from '../services/pedidos';
export type { EstadoPedido, PedidoBase } from '../services/pedidos';

/** Grupos do ecrã 07 (Pedidos) */
export const GRUPOS: Record<string, string[]> = {
  ativos: ['publicado', 'com_propostas', 'aceite', 'a_caminho', 'em_curso'],
  rascunhos: ['rascunho'],
  concluidos: ['concluido'],
  cancelados: ['cancelado'],
};

// ---------------------------------------------------------------------
// Moradas usadas nos pedidos
// ---------------------------------------------------------------------

export async function moradaDoUtilizador(moradaId: number, utilizadorId: number, db: Db = pool) {
  return queryOne(`SELECT id FROM morada WHERE id = ? AND utilizador_id = ?`, [moradaId, utilizadorId], db);
}

export async function moradaDoPedido(pedidoId: number, db: Db = pool) {
  return queryOne(
    `SELECT m.id, m.endereco, m.ponto_referencia, m.bairro, m.municipio, m.provincia, m.latitude, m.longitude
       FROM pedido pe JOIN morada m ON m.id = pe.morada_id WHERE pe.id = ?`,
    [pedidoId],
    db,
  );
}

/**
 * Morada para um pedido feito só com a zona e o ponto de referência (ecrã 10).
 * Reaproveita uma morada guardada com a mesma zona e referência; senão guarda uma nova,
 * com o GPS de outra morada da mesma zona quando existe.
 */
export async function moradaDaZona(utilizadorId: number, zonaTexto: string, ponto: string | undefined | null, db: Db): Promise<number> {
  const zona = zonaTexto.split(',')[0].trim();
  const igual = await queryOne(
    `SELECT id FROM morada
      WHERE utilizador_id = ? AND (bairro = ? OR (bairro IS NULL AND municipio = ?)) AND COALESCE(ponto_referencia, '') = ?
      ORDER BY predefinida DESC, id LIMIT 1`,
    [utilizadorId, zona, zona, ponto ?? ''],
    db,
  );
  if (igual) return igual.id;
  const parecida = await queryOne(
    `SELECT municipio, provincia, latitude, longitude FROM morada
      WHERE utilizador_id = ? AND (bairro = ? OR municipio = ?) ORDER BY predefinida DESC, id LIMIT 1`,
    [utilizadorId, zona, zona],
    db,
  );
  const total = await queryOne<{ n: number }>(`SELECT COUNT(*) n FROM morada WHERE utilizador_id = ?`, [utilizadorId], db);
  const r = await execute(
    `INSERT INTO morada (utilizador_id, rotulo, endereco, ponto_referencia, bairro, municipio, provincia, latitude, longitude, predefinida)
     VALUES (?, 'Pedido', ?, ?, ?, ?, ?, ?, ?, ?)`,
    [utilizadorId, zona, ponto ?? null, zona, parecida?.municipio ?? zona, parecida?.provincia ?? 'Luanda',
      parecida?.latitude ?? null, parecida?.longitude ?? null, Number(total!.n) === 0],
    db,
  );
  return r.insertId;
}

// ---------------------------------------------------------------------
// Criar, editar e mudar o estado
// ---------------------------------------------------------------------

export interface NovoPedido {
  clienteId: number;
  categoriaId: number;
  moradaId: number;
  titulo: string;
  descricao: string;
  urgencia: string;
  dataPretendida: Date | null;
  publicar: boolean;
}

export async function inserirPedido(p: NovoPedido, db: Db): Promise<number> {
  const r = await execute(
    `INSERT INTO pedido (cliente_id, categoria_id, morada_id, titulo, descricao, urgencia, data_pretendida, estado, publicado_em)
     VALUES (?,?,?,?,?,?,?,?, ${p.publicar ? 'NOW()' : 'NULL'})`,
    [p.clienteId, p.categoriaId, p.moradaId, p.titulo, p.descricao, p.urgencia, p.dataPretendida, p.publicar ? 'publicado' : 'rascunho'],
    db,
  );
  if (p.publicar) await registarPublicacao(r.insertId, p.clienteId, db);
  return r.insertId;
}

export async function registarPublicacao(pedidoId: number, autorId: number, db: Db) {
  await execute(
    `INSERT INTO historico_estado_pedido (pedido_id, estado_anterior, estado_novo, alterado_por) VALUES (?, NULL, 'publicado', ?)`,
    [pedidoId, autorId],
    db,
  );
}

/** Rascunho igual a um pedido anterior ("Pedir de novo") */
export async function copiarComoRascunho(antigoId: number, clienteId: number, db: Db = pool): Promise<number | null> {
  const antigo = await queryOne(`SELECT * FROM pedido WHERE id = ? AND cliente_id = ?`, [antigoId, clienteId], db);
  if (!antigo) return null;
  const r = await execute(
    `INSERT INTO pedido (cliente_id, categoria_id, morada_id, titulo, descricao, urgencia, estado) VALUES (?,?,?,?,?, 'o_mais_cedo_possivel', 'rascunho')`,
    [clienteId, antigo.categoria_id, antigo.morada_id, antigo.titulo, antigo.descricao],
    db,
  );
  return r.insertId;
}

/** Colunas que o cliente pode mudar num pedido ainda sem proposta aceite */
export const COLUNAS_EDITAVEIS = ['categoria_id', 'morada_id', 'titulo', 'descricao', 'urgencia', 'data_pretendida'] as const;

export async function atualizarPedido(pedidoId: number, campos: Partial<Record<(typeof COLUNAS_EDITAVEIS)[number], unknown>>, db: Db = pool) {
  const entradas = Object.entries(campos).filter(([k, v]) => v !== undefined && (COLUNAS_EDITAVEIS as readonly string[]).includes(k));
  if (!entradas.length) return;
  await execute(`UPDATE pedido SET ${entradas.map(([k]) => `${k} = ?`).join(', ')} WHERE id = ?`, [...entradas.map(([, v]) => v), pedidoId], db);
}

export async function dataPretendida(pedidoId: number, db: Db = pool): Promise<Date | null> {
  const r = await queryOne(`SELECT data_pretendida FROM pedido WHERE id = ?`, [pedidoId], db);
  return r?.data_pretendida ?? null;
}

export async function publicar(pedidoId: number, db: Db) {
  await execute(`UPDATE pedido SET estado = 'publicado', publicado_em = NOW() WHERE id = ?`, [pedidoId], db);
}

export async function mudarEstado(pedidoId: number, estado: string, autorId: number, db: Db) {
  await execute(`UPDATE pedido SET estado = ? WHERE id = ?`, [estado, pedidoId], db);
  await marcarAutorDoUltimoEstado(pedidoId, autorId, db);
}

/** O trigger regista a mudança de estado; aqui só se diz quem a fez */
export async function marcarAutorDoUltimoEstado(pedidoId: number, autorId: number, db: Db) {
  await execute(`UPDATE historico_estado_pedido SET alterado_por = ? WHERE pedido_id = ? ORDER BY id DESC LIMIT 1`, [autorId, pedidoId], db);
}

export async function cancelar(pedidoId: number, motivo: string | null, db: Db) {
  await execute(`UPDATE pedido SET estado = 'cancelado', cancelado_em = NOW(), motivo_cancelamento = ? WHERE id = ?`, [motivo, pedidoId], db);
}

/** Volta a "com propostas" sem proposta aceite (desfazer a aceitação) */
export async function reabrir(pedidoId: number, db: Db) {
  await execute(`UPDATE pedido SET estado = 'com_propostas', proposta_aceite_id = NULL WHERE id = ?`, [pedidoId], db);
}

// ---------------------------------------------------------------------
// Fotos
// ---------------------------------------------------------------------

export async function contarFotos(pedidoId: number, db: Db = pool): Promise<number> {
  const r = await queryOne<{ n: number }>(`SELECT COUNT(*) n FROM pedido_foto WHERE pedido_id = ?`, [pedidoId], db);
  return Number(r!.n);
}

export async function inserirFoto(pedidoId: number, url: string, db: Db = pool): Promise<number> {
  const r = await execute(`INSERT INTO pedido_foto (pedido_id, url) VALUES (?, ?)`, [pedidoId, url], db);
  return r.insertId;
}

export async function fotos(pedidoId: number, db: Db = pool) {
  return query(`SELECT id, url FROM pedido_foto WHERE pedido_id = ? ORDER BY id`, [pedidoId], db);
}

// ---------------------------------------------------------------------
// Listas
// ---------------------------------------------------------------------

/** Ids dos pedidos do cliente (os que publicou) ou do profissional (os que lhe foram aceites) */
export async function idsDosMeusPedidos(
  f: { utilizadorId: number; comoCliente: boolean; grupo?: string; categoriaId?: number; limit: number; offset: number },
  db: Db = pool,
): Promise<number[]> {
  const where = [f.comoCliente ? 'pe.cliente_id = ?' : 'pr.profissional_id = ?'];
  const params: unknown[] = [f.utilizadorId];
  if (f.grupo) { where.push('pe.estado IN (?)'); params.push(GRUPOS[f.grupo]); }
  if (f.categoriaId) { where.push('pe.categoria_id = ?'); params.push(f.categoriaId); }
  const rows = await query<{ id: number }>(
    `SELECT pe.id FROM pedido pe LEFT JOIN proposta pr ON pr.id = pe.proposta_aceite_id
      WHERE ${where.join(' AND ')}
      ORDER BY pe.criado_em DESC, pe.id DESC
      LIMIT ? OFFSET ?`,
    [...params, f.limit, f.offset],
    db,
  );
  return rows.map((r) => r.id);
}

/** Pedidos do cliente com serviço aceite, a caminho ou em curso; o mais recente primeiro */
export async function idsEmCursoDoCliente(clienteId: number, estadosAtivos: string[], db: Db = pool): Promise<number[]> {
  const rows = await query<{ id: number }>(
    `SELECT id FROM pedido WHERE cliente_id = ? AND estado IN (?) ORDER BY atualizado_em DESC, id DESC`,
    [clienteId, estadosAtivos],
    db,
  );
  return rows.map((r) => r.id);
}

/**
 * Trabalhos do profissional à espera do código do cliente (ecrã 16): pedidos ativos com a
 * proposta dele aceite e a confirmação pendente. Mais recente primeiro.
 */
export async function trabalhosPorConfirmar(profissionalId: number, estadosAtivos: string[], db: Db = pool) {
  return query<{ id: number; titulo: string; cliente: string; valor_acordado: number }>(
    `SELECT pe.id, pe.titulo, uc.nome AS cliente, cs.valor_acordado
       FROM pedido pe
       JOIN proposta pr ON pr.id = pe.proposta_aceite_id
       JOIN utilizador uc ON uc.id = pe.cliente_id
       JOIN confirmacao_servico cs ON cs.pedido_id = pe.id AND cs.estado = 'pendente'
      WHERE pr.profissional_id = ? AND pe.estado IN (?)
      ORDER BY pe.atualizado_em DESC, pe.id DESC`,
    [profissionalId, estadosAtivos],
    db,
  );
}

/** Pedidos abertos das categorias do profissional, com bairro e distância (RNF10: sem morada exata) */
export async function proximosDoProfissional(
  profissionalId: number,
  prof: { latitude: number | null; longitude: number | null; raio_atuacao_km: number },
  limit: number,
  offset: number,
  db: Db = pool,
) {
  const temGeo = prof.latitude !== null && prof.longitude !== null;
  const dist = temGeo ? distanciaKmSql('m.latitude', 'm.longitude') : 'NULL';
  return query(
    `SELECT pe.id, pe.titulo, pe.descricao, pe.urgencia, pe.data_pretendida, pe.publicado_em, pe.estado,
            c.nome AS categoria, c.chave AS categoria_chave, m.bairro, m.municipio, ROUND(${dist}, 1) AS distancia_km,
            (SELECT COUNT(*) FROM pedido_foto f WHERE f.pedido_id = pe.id) AS total_fotos,
            (SELECT COUNT(*) FROM proposta x WHERE x.pedido_id = pe.id AND x.estado = 'enviada') AS total_propostas,
            EXISTS (SELECT 1 FROM proposta x WHERE x.pedido_id = pe.id AND x.profissional_id = ?) AS ja_propus
       FROM pedido pe
       JOIN categoria c ON c.id = pe.categoria_id
       JOIN morada m ON m.id = pe.morada_id
       JOIN profissional_categoria pc ON pc.categoria_id = pe.categoria_id AND pc.profissional_id = ?
      WHERE pe.estado IN ('publicado','com_propostas') AND pe.cliente_id <> ?
      ${temGeo ? 'HAVING distancia_km IS NULL OR distancia_km <= ?' : ''}
      ORDER BY ${temGeo ? 'distancia_km IS NULL, distancia_km,' : ''} pe.publicado_em DESC
      LIMIT ? OFFSET ?`,
    [
      ...(temGeo ? geoParams(prof.latitude!, prof.longitude!) : []),
      profissionalId, profissionalId, profissionalId,
      ...(temGeo ? [prof.raio_atuacao_km] : []),
      limit, offset,
    ],
    db,
  );
}

/** Profissionais da categoria, disponíveis e dentro do raio de atuação, a avisar de um pedido novo */
export async function profissionaisAAvisar(pedidoId: number, db: Db) {
  const pe = await queryOne(
    `SELECT pe.id, pe.titulo, pe.categoria_id, pe.cliente_id, m.latitude, m.longitude, m.bairro, m.municipio
       FROM pedido pe JOIN morada m ON m.id = pe.morada_id WHERE pe.id = ?`,
    [pedidoId],
    db,
  );
  const temGeo = pe.latitude !== null && pe.longitude !== null;
  const profs = await query<{ id: number }>(
    `SELECT p.utilizador_id AS id
       FROM profissional p
       JOIN profissional_categoria pc ON pc.profissional_id = p.utilizador_id AND pc.categoria_id = ?
       JOIN utilizador u ON u.id = p.utilizador_id AND u.ativo = TRUE
      WHERE p.disponivel = TRUE AND p.utilizador_id <> ?
        ${temGeo ? `AND (p.latitude IS NULL OR ${distanciaKmSql('p.latitude', 'p.longitude')} <= p.raio_atuacao_km)` : ''}
      LIMIT 50`,
    [pe.categoria_id, pe.cliente_id, ...(temGeo ? geoParams(pe.latitude, pe.longitude) : [])],
    db,
  );
  return { pedido: pe, profissionais: profs.map((p) => p.id) };
}

// ---------------------------------------------------------------------
// Detalhe (GET /pedidos/:id)
// ---------------------------------------------------------------------

export async function detalhe(pedidoId: number, db: Db = pool) {
  return queryOne(
    `SELECT pe.id, pe.urgencia, pe.motivo_cancelamento, pe.criado_em, pe.publicado_em, pe.concluido_em, pe.cancelado_em,
            c.id AS categoria_id, c.chave AS categoria_chave, c.nome AS categoria, c.icone AS categoria_icone,
            u.nome AS cliente_nome, u.foto_url AS cliente_foto, u.telemovel AS cliente_telemovel,
            m.endereco, m.ponto_referencia, m.bairro, m.municipio, m.provincia, m.latitude, m.longitude
       FROM pedido pe JOIN categoria c ON c.id = pe.categoria_id JOIN utilizador u ON u.id = pe.cliente_id JOIN morada m ON m.id = pe.morada_id
      WHERE pe.id = ?`,
    [pedidoId],
    db,
  );
}

export async function historico(pedidoId: number, db: Db = pool) {
  return query(`SELECT estado_anterior, estado_novo, criado_em FROM historico_estado_pedido WHERE pedido_id = ? ORDER BY id`, [pedidoId], db);
}

export async function confirmacaoResumo(pedidoId: number, db: Db = pool) {
  return queryOne(
    `SELECT estado, metodo_confirmacao, metodo_pagamento, numero_comprovativo, confirmado_em FROM confirmacao_servico WHERE pedido_id = ?`,
    [pedidoId],
    db,
  );
}

export async function avaliacaoDoPedido(pedidoId: number, db: Db = pool) {
  return queryOne(`SELECT id, estrelas, comentario, criado_em FROM avaliacao WHERE pedido_id = ?`, [pedidoId], db);
}

export async function reclamacoesDoPedido(pedidoId: number, db: Db = pool) {
  return query(`SELECT id, tipo, descricao, estado, resolucao, criado_em FROM reclamacao WHERE pedido_id = ? ORDER BY id`, [pedidoId], db);
}
