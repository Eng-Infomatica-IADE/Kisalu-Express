import fs from 'node:fs';
import path from 'node:path';
import mysql from 'mysql2/promise';

const PASTA_SQL = path.resolve(__dirname, '../database');

/** Ficheiros SQL pela ordem em que têm de correr */
export const FICHEIROS_SQL = {
  criar: 'create.sql', // tabelas, índices, triggers e vistas
  popular: 'populate.sql', // dados de exemplo
  consultas: 'queries.sql', // consultas de exemplo (opcional)
};

/**
 * Divide um ficheiro .sql em instruções, respeitando "DELIMITER $$" (triggers),
 * que é um comando do cliente mysql e não SQL.
 * Regra dos ficheiros: um comentário nunca fica na mesma linha a seguir a um ";".
 */
export function dividirSql(sql: string): string[] {
  const out: string[] = [];
  let delim = ';';
  let buf: string[] = [];
  for (const line of sql.split(/\r?\n/)) {
    const t = line.trim();
    if (!buf.length && (t === '' || t.startsWith('--'))) continue;
    const m = t.match(/^DELIMITER\s+(\S+)$/i);
    if (m) { delim = m[1]; continue; }
    buf.push(line);
    if (t.endsWith(delim)) {
      const stmt = buf.join('\n').trim();
      out.push(stmt.slice(0, stmt.length - delim.length).trim());
      buf = [];
    }
  }
  if (buf.join('').trim()) out.push(buf.join('\n').trim());
  return out;
}

interface ConfigBd { host: string; port: number; user: string; password: string; database: string }

/** Lê um ficheiro de database/ e troca o nome da base pelo indicado */
function lerSql(ficheiro: string, database: string) {
  return fs.readFileSync(path.join(PASTA_SQL, ficheiro), 'utf8').replace(/\bkisalu_express\b/g, database);
}

/**
 * Recria a base de dados `database`: corre create.sql e populate.sql
 * (e queries.sql, se `comConsultas`) numa só ligação.
 */
export async function recriarBaseDeDados(cfg: ConfigBd, opcoes: { comConsultas?: boolean } = {}) {
  const ficheiros = [FICHEIROS_SQL.criar, FICHEIROS_SQL.popular, ...(opcoes.comConsultas ? [FICHEIROS_SQL.consultas] : [])];
  const conn = await mysql.createConnection({
    host: cfg.host, port: cfg.port, user: cfg.user, password: cfg.password, charset: 'utf8mb4',
  });
  try {
    await conn.query("SET time_zone = '+00:00'");
    for (const f of ficheiros) {
      for (const stmt of dividirSql(lerSql(f, cfg.database))) {
        try {
          await conn.query(stmt);
        } catch (e: any) {
          throw new Error(`${f}: ${e.message}\n${stmt.slice(0, 300)}`);
        }
      }
    }
  } finally {
    await conn.end();
  }
}
