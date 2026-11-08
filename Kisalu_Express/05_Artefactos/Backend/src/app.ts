import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import path from 'node:path';
import swaggerUi from 'swagger-ui-express';
import { env } from './config/env';
import { gerarOpenApi } from './docs/registry';
import { errorHandler, notFoundHandler } from './middlewares/error';
import { embrulharRespostas } from './utils/resposta';

import auth from './modules/auth';
import catalogo from './modules/catalogo';
import profissionais from './routes/profissionais';
import moradas from './modules/moradas';
import pedidos from './routes/pedidos';
import servico from './modules/servico';
import conversas from './modules/conversas';
import admin from './modules/admin';

export function createApp() {
  const app = express();

  app.use(helmet({ contentSecurityPolicy: false })); // CSP desligada para o Swagger UI
  // CORS_ORIGINS vazio só é aceite fora de produção (ver config/env.ts)
  app.use(cors(env.corsOrigins.length ? { origin: env.corsOrigins } : undefined));
  app.use(express.json({ limit: '100kb' }));
  // Pastas que nunca são públicas, mesmo que lá exista algum ficheiro antigo (documentos e reclamações)
  app.use(['/uploads/verificacoes', '/uploads/reclamacoes'], (_req, res) => {
    res.status(404).json({ title: 'Não encontrado', status: 404, detail: 'Ficheiro não encontrado.', instance: _req.originalUrl, data: { codigo: 'NAO_ENCONTRADO' } });
  });
  app.use('/uploads', express.static(path.resolve(env.uploadDir), { maxAge: '7d' }));

  // Todas as respostas em /api seguem { title, status, detail, instance, data }
  app.use('/api', embrulharRespostas);

  app.get('/api/saude', (_req, res) => {
    res.json({ estado: 'ok', servico: 'kisalu-express-api' });
  });

  const api = express.Router();
  for (const r of [auth, catalogo, profissionais, moradas, pedidos, servico, conversas, admin]) api.use(r);
  app.use('/api', api);

  const openapi = gerarOpenApi();
  app.get('/docs.json', (_req, res) => {
    res.json(openapi);
  });
  app.use('/docs', swaggerUi.serve, swaggerUi.setup(openapi, { customSiteTitle: 'Kisalu Express API' }));

  app.use(notFoundHandler);
  app.use(errorHandler);
  return app;
}
