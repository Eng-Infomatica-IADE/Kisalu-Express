import { env } from '../src/config/env';
import { recriarBaseDeDados } from './sql-runner';

// npm run db:reset             → create.sql + populate.sql
// npm run db:reset -- --consultas → também corre queries.sql (altera alguns dados de exemplo)
const comConsultas = process.argv.includes('--consultas');

recriarBaseDeDados(env.db, { comConsultas })
  .then(() =>
    console.log(
      `Base de dados "${env.db.database}" criada (create.sql + populate.sql${comConsultas ? ' + queries.sql' : ''}).`,
    ),
  )
  .catch((e) => { console.error(e.message); process.exit(1); });
