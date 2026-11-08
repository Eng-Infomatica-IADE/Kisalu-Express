import 'express';

export type TipoPerfil = 'cliente' | 'profissional' | 'admin';

declare global {
  namespace Express {
    interface Request {
      /** tipo_perfil é o perfil ativo da sessão; tipo_conta é o guardado em utilizador.tipo_perfil */
      user?: { id: number; tipo_perfil: TipoPerfil; tipo_conta: TipoPerfil; sessao_id: number };
      /** Dados já validados pelo Zod (body, query, params) */
      valid: { body: any; query: any; params: any };
    }
  }
}
