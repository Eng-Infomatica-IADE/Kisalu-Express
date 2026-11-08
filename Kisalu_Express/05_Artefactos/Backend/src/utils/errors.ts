export class AppError extends Error {
  constructor(
    public status: number,
    public codigo: string,
    message: string,
    public detalhes?: unknown,
  ) {
    super(message);
  }
}

export const badRequest = (msg: string, codigo = 'PEDIDO_INVALIDO', detalhes?: unknown) =>
  new AppError(400, codigo, msg, detalhes);
export const unauthorized = (msg = 'Sessão inválida ou expirada.') => new AppError(401, 'NAO_AUTENTICADO', msg);
export const forbidden = (msg = 'Não tem permissão para esta ação.') => new AppError(403, 'SEM_PERMISSAO', msg);
export const notFound = (what = 'Recurso') => new AppError(404, 'NAO_ENCONTRADO', `${what} não encontrado.`);
export const conflict = (msg: string, codigo = 'CONFLITO') => new AppError(409, codigo, msg);
export const tooMany = (msg: string) => new AppError(429, 'DEMASIADOS_PEDIDOS', msg);
