import { createApp } from './app';
import { env } from './config/env';
import { pool } from './config/db';

async function main() {
  await pool.query('SELECT 1'); // falha cedo se o MySQL não estiver acessível
  createApp().listen(env.port, () => {
    console.log(`Kisalu Express API em http://localhost:${env.port}/api`);
    console.log(`Documentação Swagger em http://localhost:${env.port}/docs`);
  });
}

main().catch((err) => {
  console.error('Não foi possível arrancar a API:', err.message);
  process.exit(1);
});
