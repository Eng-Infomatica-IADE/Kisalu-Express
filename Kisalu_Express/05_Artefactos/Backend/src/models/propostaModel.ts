/**
 * Model das propostas e das alterações de preço.
 */
import { Db, execute, pool, query, queryOne } from '../config/db';

/** Acordo fechado (proposta aceite + valor combinado), para quem pode ver os contactos */
export async function acordo(propostaId: number, db: Db = pool) {
  const a = await queryOne(
    `SELECT pr.id AS proposta_id, pr.profissional_id, u.nome AS profissional, u.telemovel AS profissional_telemovel, u.foto_url AS profissional_foto,
            p.verificado, p.media_avaliacao, pr.valor_total AS valor_proposto, cs.valor_acordado, pr.inclui_descricao,
            pr.tempo_chegada_min, pr.na_hora_pedida, pr.respondida_em AS aceite_em
       FROM proposta pr JOIN utilizador u ON u.id = pr.profissional_id JOIN profissional p ON p.utilizador_id = pr.profissional_id
       LEFT JOIN confirmacao_servico cs ON cs.pedido_id = pr.pedido_id
      WHERE pr.id = ?`,
    [propostaId],
    db,
  );
  if (a) a.alteracoes_preco = await alteracoesDePreco(propostaId, db);
  return a;
}

export async function alteracoesDePreco(propostaId: number, db: Db = pool) {
  return query(
    `SELECT id, valor_anterior, valor_novo, motivo, estado, pedida_em, respondida_em FROM alteracao_preco WHERE proposta_id = ? ORDER BY id`,
    [propostaId],
    db,
  );
}

export async function alteracaoPendente(propostaId: number | null, db: Db = pool) {
  if (!propostaId) return null;
  return queryOne(`SELECT id FROM alteracao_preco WHERE proposta_id = ? AND estado = 'pendente'`, [propostaId], db);
}

export async function profissionalJaPropos(pedidoId: number, profissionalId: number, db: Db = pool): Promise<boolean> {
  return !!(await queryOne(`SELECT 1 ok FROM proposta WHERE pedido_id = ? AND profissional_id = ?`, [pedidoId, profissionalId], db));
}

/** Proposta aceite com os segundos passados desde a aceitação (para o "Desfazer") */
export async function aceiteComIdade(propostaId: number, db: Db) {
  return queryOne(
    `SELECT id, profissional_id, respondida_em, TIMESTAMPDIFF(SECOND, respondida_em, NOW()) AS segundos FROM proposta WHERE id = ?`,
    [propostaId],
    db,
  );
}

/** A proposta aceite e as recusadas automaticamente na mesma aceitação voltam a "enviada" */
export async function reativarDepoisDeDesfazer(pedidoId: number, propostaId: number, aceiteEm: Date, db: Db) {
  await execute(
    `UPDATE proposta SET estado = 'enviada', respondida_em = NULL
      WHERE pedido_id = ? AND (id = ? OR (estado = 'recusada' AND respondida_em >= ?))`,
    [pedidoId, propostaId, aceiteEm],
    db,
  );
}

export async function expirarEnviadas(pedidoId: number, db: Db) {
  await execute(`UPDATE proposta SET estado = 'expirada' WHERE pedido_id = ? AND estado = 'enviada'`, [pedidoId], db);
}

export async function autoresDoPedido(pedidoId: number, db: Db = pool): Promise<number[]> {
  const rows = await query<{ profissional_id: number }>(`SELECT profissional_id FROM proposta WHERE pedido_id = ?`, [pedidoId], db);
  return rows.map((r) => r.profissional_id);
}

/** Dados para simular a chegada: quem pode ver, minutos prometidos e as duas pontas da viagem */
export async function paraEstimativa(propostaId: number, db: Db = pool) {
  return queryOne<{
    id: number; profissional_id: number; cliente_id: number; tempo_chegada_min: number | null; na_hora_pedida: number;
    p_lat: number | null; p_lng: number | null; m_lat: number | null; m_lng: number | null;
  }>(
    `SELECT pr.id, pr.profissional_id, pe.cliente_id, pr.tempo_chegada_min, pr.na_hora_pedida,
            p.latitude AS p_lat, p.longitude AS p_lng, m.latitude AS m_lat, m.longitude AS m_lng
       FROM proposta pr
       JOIN pedido pe ON pe.id = pr.pedido_id
       JOIN morada m ON m.id = pe.morada_id
       JOIN profissional p ON p.utilizador_id = pr.profissional_id
      WHERE pr.id = ?`,
    [propostaId],
    db,
  );
}
