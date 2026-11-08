import { NextFunction, Request, RequestHandler, Response, Router } from 'express';
import { AnyZodObject, z, ZodEffects, ZodTypeAny } from 'zod';
import { registry } from '../docs/registry';
import './validacoes'; // mensagens de erro do Zod em português
import { authenticate, requireRole } from '../middlewares/auth';
import { upload } from '../middlewares/upload';
import type { TipoPerfil } from '../types/express';

type Method = 'get' | 'post' | 'put' | 'patch' | 'delete';

export interface RouteDef {
  method: Method;
  /** Caminho Express, ex.: /pedidos/:id */
  path: string;
  tag: string;
  summary: string;
  description?: string;
  /** undefined = público; 'auth' = qualquer utilizador autenticado; lista = perfis permitidos */
  access?: 'auth' | TipoPerfil[];
  params?: AnyZodObject;
  query?: AnyZodObject;
  body?: AnyZodObject | ZodEffects<AnyZodObject>;
  /** Formulário multipart: campos de ficheiro (nome → máximo de ficheiros) */
  files?: Record<string, number>;
  status?: number;
}

const toOpenApiPath = (p: string) => p.replace(/:(\w+)/g, '{$1}');

/** Formato único de resposta (ver utils/resposta.ts) */
const Resposta = registry.register(
  'Resposta',
  z
    .object({
      title: z.string(),
      status: z.number().int(),
      detail: z.string(),
      instance: z.string(),
      data: z.any().nullable().openapi({ description: 'Conteúdo da resposta. Nos erros: { codigo, detalhes? }' }),
    })
    .openapi({
      example: {
        title: 'Falha na autenticação',
        status: 401,
        detail: 'Falta o token de acesso.',
        instance: '/api/admin/verificacoes',
        data: { codigo: 'NAO_AUTENTICADO' },
      },
    }),
);
const resposta = (description: string) => ({ description, content: { 'application/json': { schema: Resposta } } });

/**
 * Regista a rota no Express E no Swagger com a mesma definição,
 * para a documentação nunca ficar desatualizada.
 */
export function route(router: Router, def: RouteDef, handler: RequestHandler) {
  const chain: RequestHandler[] = [];

  if (def.access) {
    chain.push(authenticate as RequestHandler);
    if (Array.isArray(def.access)) chain.push(requireRole(...def.access));
  }
  if (def.files) {
    chain.push(upload.fields(Object.entries(def.files).map(([name, maxCount]) => ({ name, maxCount }))));
  }
  chain.push((req: Request, _res: Response, next: NextFunction) => {
    req.valid = {
      params: def.params ? def.params.parse(req.params) : req.params,
      query: def.query ? def.query.parse(req.query) : req.query,
      body: def.body ? def.body.parse(req.body ?? {}) : req.body,
    };
    next();
  });

  router[def.method](def.path, ...chain, handler);

  // ---- Swagger ----
  let requestBody: any;
  if (def.files) {
    const fileFields: Record<string, ZodTypeAny> = {};
    for (const [name, max] of Object.entries(def.files)) {
      fileFields[name] = max > 1 ? z.array(z.any().openapi({ type: 'string', format: 'binary' })) : z.any().openapi({ type: 'string', format: 'binary' });
    }
    const base = def.body instanceof ZodEffects ? def.body.innerType() : (def.body ?? z.object({}));
    const schema = base.extend(fileFields);
    requestBody = { content: { 'multipart/form-data': { schema } } };
  } else if (def.body) {
    requestBody = { content: { 'application/json': { schema: def.body } } };
  }

  const ok = def.status ?? (def.method === 'post' ? 201 : 200);
  registry.registerPath({
    method: def.method,
    path: toOpenApiPath(def.path),
    tags: [def.tag],
    summary: def.summary,
    description: def.description,
    security: def.access ? [{ bearerAuth: [] }] : undefined,
    request: { params: def.params, query: def.query, body: requestBody },
    responses: {
      [ok]: resposta('Sucesso'),
      400: resposta('Dados inválidos'),
      ...(def.access ? { 401: resposta('Sem sessão'), 403: resposta('Sem permissão') } : {}),
      404: resposta('Não encontrado'),
      ...(['post', 'patch', 'put'].includes(def.method) ? { 409: resposta('Conflito com o estado atual'), 422: resposta('Regra de negócio violada') } : {}),
    },
  });
}

/** Schemas reutilizáveis */
export const idParam = z.object({ id: z.coerce.number().int().positive() });
export const paginacao = z.object({
  limit: z.coerce.number().int().min(1).max(100).default(20),
  offset: z.coerce.number().int().min(0).default(0),
});
export const kz = z.number().min(0).max(100_000_000);
