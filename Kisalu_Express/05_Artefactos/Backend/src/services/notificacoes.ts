import { Db, execute, pool, query } from '../config/db';
import { env } from '../config/env';

export type TipoNotificacao =
  | 'novo_pedido'
  | 'nova_proposta'
  | 'proposta_aceite'
  | 'estado_pedido'
  | 'alteracao_preco'
  | 'nova_mensagem'
  | 'lembrete_avaliacao'
  | 'reclamacao'
  | 'sistema';

interface Notificacao {
  tipo: TipoNotificacao;
  titulo: string;
  corpo: string;
  pedido_id?: number | null;
  /** Ação direta aberta ao tocar (RM06), ex.: "ver_propostas" */
  acao?: string;
}

/**
 * Grava a notificação (aparece na app) e envia push para as sessões com push_token.
 * O envio real (Firebase Cloud Messaging) fica em enviarPush().
 */
export async function notificar(utilizadorId: number, n: Notificacao, db: Db = pool) {
  await execute(
    `INSERT INTO notificacao (utilizador_id, pedido_id, tipo, titulo, corpo, acao) VALUES (?,?,?,?,?,?)`,
    [utilizadorId, n.pedido_id ?? null, n.tipo, n.titulo.slice(0, 80), n.corpo.slice(0, 200), n.acao ?? null],
    db,
  );
  const tokens = await query<{ push_token: string }>(
    `SELECT push_token FROM sessao WHERE utilizador_id = ? AND push_token IS NOT NULL AND revogada = FALSE AND expira_em > NOW()`,
    [utilizadorId],
    db,
  );
  for (const t of tokens) enviarPush(t.push_token, n);
}

function enviarPush(token: string, n: Notificacao) {
  // Ponto de integração com o FCM (firebase-admin). Em desenvolvimento só regista no terminal.
  if (env.nodeEnv === 'development') console.log(`[push] ${token.slice(0, 12)}… → ${n.titulo}`);
}
