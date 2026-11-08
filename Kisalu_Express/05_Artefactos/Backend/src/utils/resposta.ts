import { NextFunction, Request, Response } from 'express';

/** Formato único de todas as respostas da API (sucesso e erro) */
export interface Resposta<T = unknown> {
  title: string;
  status: number;
  detail: string;
  instance: string;
  data: T | null;
}

const TITULOS: Record<number, string> = {
  200: 'Sucesso',
  201: 'Criado com sucesso',
  400: 'Dados inválidos',
  401: 'Falha na autenticação',
  403: 'Acesso negado',
  404: 'Não encontrado',
  409: 'Conflito',
  422: 'Regra de negócio violada',
  429: 'Demasiados pedidos',
  500: 'Erro interno',
};

const DETALHES_SUCESSO: Record<number, string> = {
  200: 'Pedido processado com sucesso.',
  201: 'Recurso criado com sucesso.',
};

const tituloPara = (status: number) => TITULOS[status] ?? (status < 400 ? 'Sucesso' : 'Erro');

export function criarResposta<T>(req: Request, status: number, detail: string, data: T | null): Resposta<T> {
  return {
    title: tituloPara(status),
    status,
    detail,
    instance: req.originalUrl.split('?')[0],
    data: data ?? null,
  };
}

const JA_EMBRULHADA = Symbol('resposta-embrulhada');

/** Envia uma resposta já no formato padrão (usado pelos handlers de erro) */
export function enviarResposta(req: Request, res: Response, status: number, detail: string, data: unknown = null) {
  (res.locals as any)[JA_EMBRULHADA] = true;
  return res.status(status).json(criarResposta(req, status, detail, data));
}

/**
 * Embrulha automaticamente o res.json() dos handlers:
 * o que o handler envia passa a ser o campo "data".
 */
export function embrulharRespostas(req: Request, res: Response, next: NextFunction) {
  const json = res.json.bind(res);
  res.json = (body?: unknown) => {
    if ((res.locals as any)[JA_EMBRULHADA]) return json(body);
    (res.locals as any)[JA_EMBRULHADA] = true;
    const status = res.statusCode;
    const detail = DETALHES_SUCESSO[status] ?? 'Pedido processado.';
    return json(criarResposta(req, status, detail, body));
  };
  next();
}
