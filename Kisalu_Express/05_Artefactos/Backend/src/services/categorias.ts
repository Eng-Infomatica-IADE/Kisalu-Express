import { Db, pool, query, queryOne } from '../config/db';
import { badRequest } from '../utils/errors';

/** Uma categoria pode chegar pela chave da app ("canalizador") ou pelo id (2) */
export type RefCategoria = string | number;

/** Converte chaves e/ou ids em ids de categoria. 400 se alguma não existir. */
export async function idsDeCategorias(refs: RefCategoria[], db: Db = pool): Promise<number[]> {
  if (!refs.length) return [];
  const chaves = refs.filter((r) => typeof r === 'string') as string[];
  const ids = refs.filter((r) => typeof r === 'number') as number[];
  const rows = await query<{ id: number; chave: string }>(
    `SELECT id, chave FROM categoria WHERE ativa = TRUE AND (chave IN (?) OR id IN (?))`,
    [chaves.length ? chaves : [''], ids.length ? ids : [0]],
    db,
  );
  const desconhecidas = refs.filter((r) => !rows.some((c) => (typeof r === 'string' ? c.chave === r : c.id === r)));
  if (desconhecidas.length) {
    throw badRequest(`Categoria desconhecida: ${desconhecidas.join(', ')}.`, 'CATEGORIA_INVALIDA');
  }
  return [...new Set(refs.map((r) => rows.find((c) => (typeof r === 'string' ? c.chave === r : c.id === r))!.id))];
}

export async function categoria(ref: RefCategoria, db: Db = pool) {
  const [id] = await idsDeCategorias([ref], db);
  return (await queryOne<{ id: number; chave: string; nome: string; plural: string }>(
    `SELECT id, chave, nome, plural FROM categoria WHERE id = ?`,
    [id],
    db,
  ))!;
}
