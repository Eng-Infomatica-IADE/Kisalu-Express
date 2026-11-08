import { NextFunction, Request, Response } from 'express';
import { ZodError } from 'zod';
import multer from 'multer';
import { AppError } from '../utils/errors';
import { isProduction } from '../config/env';
import { enviarResposta } from '../utils/resposta';

/**
 * Resposta de erro no formato padrão (RNF07):
 * { title, status, detail: mensagem, instance, data: { codigo, detalhes? } }
 */
export function errorHandler(err: any, req: Request, res: Response, _next: NextFunction) {
  const send = (status: number, codigo: string, mensagem: string, detalhes?: unknown) =>
    enviarResposta(req, res, status, mensagem, { codigo, ...(detalhes ? { detalhes } : {}) });

  if (err instanceof AppError) return send(err.status, err.codigo, err.message, err.detalhes);

  if (err instanceof ZodError) {
    // detail traz a mensagem do primeiro problema, pronta a mostrar; detalhes traz todos
    const detalhes = err.issues.map((i) => ({ campo: i.path.join('.'), mensagem: i.message }));
    return send(400, 'DADOS_INVALIDOS', detalhes[0]?.mensagem ?? 'Alguns dados não estão corretos.', detalhes);
  }

  if (err instanceof multer.MulterError) {
    const msg = err.code === 'LIMIT_FILE_SIZE' ? 'A imagem é demasiado grande.' : 'Erro no envio do ficheiro.';
    return send(400, 'UPLOAD_INVALIDO', msg);
  }

  if (err?.type === 'entity.parse.failed') return send(400, 'JSON_INVALIDO', 'O corpo do pedido não é JSON válido.');

  // Erros do MySQL
  switch (err?.errno) {
    case 1644: // SIGNAL '45000' disparado pelos triggers (regras de negócio)
      return send(422, 'REGRA_DE_NEGOCIO', err.sqlMessage);
    case 1062:
      return send(409, 'DUPLICADO', 'Este registo já existe.');
    case 1451:
      return send(409, 'EM_USO', 'Não é possível apagar: o registo está a ser usado.');
    case 1452:
      return send(400, 'REFERENCIA_INVALIDA', 'Um dos identificadores indicados não existe.');
    case 3819: // CHECK (MySQL)
    case 4025: // CHECK (MariaDB)
      return send(400, 'DADOS_INVALIDOS', 'Um dos valores não cumpre as regras.');
  }

  console.error(err);
  return send(500, 'ERRO_INTERNO', 'Ocorreu um erro inesperado. Tente de novo.', isProduction ? undefined : String(err?.message ?? err));
}

export function notFoundHandler(req: Request, res: Response) {
  enviarResposta(req, res, 404, 'Endpoint não encontrado.', { codigo: 'ROTA_INEXISTENTE' });
}
