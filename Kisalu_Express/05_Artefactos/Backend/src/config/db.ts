import mysql, { Pool, PoolConnection, ResultSetHeader } from 'mysql2/promise';
import { env } from './env';

export const pool: Pool = mysql.createPool({
  ...env.db,
  connectionLimit: 10,
  decimalNumbers: true, // DECIMAL (kwanzas) chega como number
  charset: 'utf8mb4',
  timezone: 'Z', // as datas da base estão em UTC e saem em ISO 8601 com "Z"
  // BOOLEAN (TINYINT(1)) chega como true/false em vez de 0/1
  typeCast(field, next) {
    if (field.type === 'TINY' && field.length === 1) {
      const v = field.string();
      return v === null ? null : v === '1';
    }
    return next();
  },
});

// Cada ligação nova trabalha em UTC: NOW() e CURRENT_TIMESTAMP batem certo com as datas devolvidas.
// O evento entrega a ligação "clássica" (com callbacks), por isso o erro chega pela callback.
pool.on('connection', (conn: any) => {
  conn.query("SET time_zone = '+00:00'", (err: Error | null) => {
    if (err) console.error('Não foi possível pôr a ligação em UTC:', err.message);
  });
});

export type Db = Pool | PoolConnection;

/** SELECT → lista de linhas */
export async function query<T = any>(sql: string, params: unknown[] = [], db: Db = pool): Promise<T[]> {
  const [rows] = await db.query(sql, params);
  return rows as T[];
}

/** SELECT → primeira linha ou null */
export async function queryOne<T = any>(sql: string, params: unknown[] = [], db: Db = pool): Promise<T | null> {
  const rows = await query<T>(sql, params, db);
  return rows[0] ?? null;
}

/** INSERT / UPDATE / DELETE */
export async function execute(sql: string, params: unknown[] = [], db: Db = pool): Promise<ResultSetHeader> {
  const [res] = await db.query(sql, params);
  return res as ResultSetHeader;
}

/** Corre fn numa transação: commit se correr bem, rollback se lançar erro */
export async function transaction<T>(fn: (conn: PoolConnection) => Promise<T>): Promise<T> {
  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();
    const result = await fn(conn);
    await conn.commit();
    return result;
  } catch (err) {
    await conn.rollback();
    throw err;
  } finally {
    conn.release();
  }
}
