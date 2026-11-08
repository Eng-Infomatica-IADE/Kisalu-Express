import { Db, pool, queryOne } from '../config/db';
import { forbidden, notFound } from '../utils/errors';

export type EstadoPedido =
  | 'rascunho' | 'publicado' | 'com_propostas' | 'aceite' | 'a_caminho' | 'em_curso' | 'concluido' | 'cancelado';

export const ESTADOS_ABERTOS: EstadoPedido[] = ['publicado', 'com_propostas'];
export const ESTADOS_ATIVOS: EstadoPedido[] = ['aceite', 'a_caminho', 'em_curso'];

export interface PedidoBase {
  id: number;
  cliente_id: number;
  categoria_id: number;
  morada_id: number;
  estado: EstadoPedido;
  proposta_aceite_id: number | null;
  profissional_aceite_id: number | null;
  concluido_em: Date | null;
}

/** Carrega o pedido com o profissional da proposta aceite. FOR UPDATE quando dentro de uma transação. */
export async function carregarPedido(id: number, db: Db = pool, forUpdate = false): Promise<PedidoBase> {
  const p = await queryOne<PedidoBase>(
    `SELECT pe.id, pe.cliente_id, pe.categoria_id, pe.morada_id, pe.estado, pe.proposta_aceite_id, pe.concluido_em,
            pr.profissional_id AS profissional_aceite_id
       FROM pedido pe LEFT JOIN proposta pr ON pr.id = pe.proposta_aceite_id
      WHERE pe.id = ? ${forUpdate ? 'FOR UPDATE' : ''}`,
    [id],
    db,
  );
  if (!p) throw notFound('Pedido');
  return p;
}

export type Papel = 'cliente' | 'profissional_aceite' | 'profissional' | 'admin';

/**
 * Que relação tem o utilizador com o pedido?
 * - cliente: dono do pedido
 * - profissional_aceite: autor da proposta aceite
 * - profissional: pode ver o pedido aberto (categoria dele) ou já lhe enviou proposta
 */
export async function papelNoPedido(p: PedidoBase, user: Express.Request['user'], db: Db = pool): Promise<Papel> {
  if (!user) throw forbidden();
  if (user.tipo_perfil === 'admin') return 'admin';
  if (user.id === p.cliente_id) return 'cliente';
  if (user.id === p.profissional_aceite_id) return 'profissional_aceite';
  if (user.tipo_perfil === 'profissional') {
    const ligado = await queryOne(
      `SELECT 1 AS ok FROM proposta WHERE pedido_id = ? AND profissional_id = ?
       UNION
       SELECT 1 FROM profissional_categoria WHERE profissional_id = ? AND categoria_id = ? AND ? IN ('publicado','com_propostas')`,
      [p.id, user.id, user.id, p.categoria_id, p.estado],
      db,
    );
    if (ligado) return 'profissional';
  }
  throw notFound('Pedido'); // não revela pedidos de outros
}

export function exigirPapel(papel: Papel, ...permitidos: Papel[]) {
  if (!permitidos.includes(papel)) throw forbidden();
}
