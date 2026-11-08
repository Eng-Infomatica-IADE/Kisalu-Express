/**
 * Model das conversas (chat do pedido).
 */
import { Db, execute, pool, queryOne } from '../config/db';

/** Id da conversa entre o cliente de um pedido e um profissional (ou null) */
export async function idDaConversa(pedidoId: number, profissionalId: number | null, db: Db = pool): Promise<number | null> {
  if (!profissionalId) return null;
  const c = await queryOne<{ id: number }>(`SELECT id FROM conversa WHERE pedido_id = ? AND profissional_id = ?`, [pedidoId, profissionalId], db);
  return c?.id ?? null;
}

/** Abre a conversa se ainda não existir */
export async function abrirConversa(pedidoId: number, profissionalId: number, db: Db = pool) {
  await execute(`INSERT IGNORE INTO conversa (pedido_id, profissional_id) VALUES (?, ?)`, [pedidoId, profissionalId], db);
}
