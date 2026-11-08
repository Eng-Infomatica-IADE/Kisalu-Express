/**
 * Model da confirmação do serviço (QR Code + código de 6 dígitos, RF10).
 */
import { Db, execute, pool, query, queryOne } from '../config/db';

export interface ConfirmacaoPendente {
  id: number;
  pedido_id: number;
  cliente_id: number;
  proposta_aceite_id: number;
  token_qr: string;
  codigo_numerico: string;
  tentativas: number;
  qr_expirado: boolean | number;
}

const CAMPOS = `cs.id, cs.pedido_id, pe.cliente_id, pe.proposta_aceite_id, cs.token_qr, cs.codigo_numerico, cs.tentativas,
  cs.expira_em IS NOT NULL AND cs.expira_em <= NOW() AS qr_expirado`;

/** A confirmação pendente de um pedido (bloqueada para atualização) */
export async function pendenteDoPedido(pedidoId: number, db: Db): Promise<ConfirmacaoPendente | null> {
  return queryOne<ConfirmacaoPendente>(
    `SELECT ${CAMPOS} FROM confirmacao_servico cs JOIN pedido pe ON pe.id = cs.pedido_id
      WHERE cs.pedido_id = ? AND cs.estado = 'pendente' FOR UPDATE`,
    [pedidoId],
    db,
  );
}

/**
 * Todas as confirmações pendentes dos serviços ativos do profissional (proposta dele aceite).
 * Ordem: o QR aberto (ou renovado) pelo cliente mais recentemente primeiro. É esta ordem que
 * desempata quando, em desenvolvimento (CODIGO_QR_FIXO_DEV), vários serviços têm o mesmo código.
 */
export async function pendentesDoProfissional(profissionalId: number, estadosAtivos: string[], db: Db): Promise<ConfirmacaoPendente[]> {
  return query<ConfirmacaoPendente>(
    `SELECT ${CAMPOS}
       FROM confirmacao_servico cs
       JOIN pedido pe ON pe.id = cs.pedido_id
       JOIN proposta pr ON pr.id = pe.proposta_aceite_id
      WHERE pr.profissional_id = ? AND pe.estado IN (?) AND cs.estado = 'pendente'
      ORDER BY COALESCE(cs.qr_aberto_em, cs.gerado_em) DESC, cs.id DESC
      FOR UPDATE`,
    [profissionalId, estadosAtivos],
    db,
  );
}

export async function contarTentativa(ids: number[], db: Db) {
  if (!ids.length) return;
  await execute(`UPDATE confirmacao_servico SET tentativas = tentativas + 1 WHERE id IN (?)`, [ids], db);
}

/** O trigger trg_confirmacao_concluir passa o pedido a "concluido" e soma o serviço ao profissional */
export async function marcarConfirmado(id: number, metodo: 'qr' | 'codigo', metodoPagamento: string, numero: string, db: Db) {
  await execute(
    `UPDATE confirmacao_servico SET estado = 'confirmado', metodo_confirmacao = ?, metodo_pagamento = ?, numero_comprovativo = ?, confirmado_em = NOW() WHERE id = ?`,
    [metodo, metodoPagamento, numero, id],
    db,
  );
}

/** O cliente abriu o QR (ecrã 05): fica registado para desempatar códigos iguais */
export async function registarAbertura(id: number, db: Db = pool) {
  await execute(`UPDATE confirmacao_servico SET qr_aberto_em = NOW(3) WHERE id = ?`, [id], db);
}

/** Desfazer a aceitação anula o QR */
export async function apagarPendente(pedidoId: number, db: Db) {
  await execute(`DELETE FROM confirmacao_servico WHERE pedido_id = ? AND estado = 'pendente'`, [pedidoId], db);
}

/** Cancelar o pedido invalida o QR */
export async function expirarPendente(pedidoId: number, db: Db) {
  await execute(`UPDATE confirmacao_servico SET estado = 'expirado' WHERE pedido_id = ? AND estado = 'pendente'`, [pedidoId], db);
}
