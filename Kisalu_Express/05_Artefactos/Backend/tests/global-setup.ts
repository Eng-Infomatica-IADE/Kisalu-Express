import 'dotenv/config';
import fs from 'node:fs';
import { recriarBaseDeDados } from '../scripts/sql-runner';

/** Antes de todos os testes: base de dados limpa (kisalu_express_test) com os dados de exemplo */
export async function setup() {
  await recriarBaseDeDados({
    host: process.env.DB_HOST ?? 'localhost',
    port: Number(process.env.DB_PORT ?? 3306),
    user: process.env.DB_USER ?? 'root',
    password: process.env.DB_PASSWORD ?? '',
    database: 'kisalu_express_test',
  });
}

export async function teardown() {
  fs.rmSync('tests/.uploads', { recursive: true, force: true });
  fs.rmSync('tests/.privado', { recursive: true, force: true });
}
