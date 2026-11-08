/**
 * Model dos utilizadores: nomes e contactos.
 */
import { Db, pool, queryOne } from '../config/db';

export async function nome(utilizadorId: number, db: Db = pool): Promise<string | null> {
  const u = await queryOne<{ nome: string | null }>(`SELECT nome FROM utilizador WHERE id = ?`, [utilizadorId], db);
  return u?.nome ?? null;
}

/** Nome e telemóvel do profissional de uma proposta (ex.: contacto depois de reportar um problema) */
export async function contactoDoAutorDaProposta(propostaId: number | null, db: Db = pool) {
  if (!propostaId) return null;
  return queryOne<{ nome: string; telemovel: string }>(
    `SELECT u.nome, u.telemovel FROM proposta pr JOIN utilizador u ON u.id = pr.profissional_id WHERE pr.id = ?`,
    [propostaId],
    db,
  );
}
