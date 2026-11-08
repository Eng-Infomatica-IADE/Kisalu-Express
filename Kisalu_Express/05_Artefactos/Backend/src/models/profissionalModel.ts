/**
 * Model dos profissionais: pesquisa, perfil, painel, registo, verificação e galeria.
 */
import { Db, execute, pool, query, queryOne } from '../config/db';
import { distanciaKmSql, geoParams } from '../utils/geo';
import { Distribuicao, PRIOR_M } from '../services/estatistica';

/** Soma das estrelas e número de avaliações a partir das colunas avaliacoes_1..5 */
const SOMA_SQL = (p: string) =>
  `(${p}.avaliacoes_1 + 2 * ${p}.avaliacoes_2 + 3 * ${p}.avaliacoes_3 + 4 * ${p}.avaliacoes_4 + 5 * ${p}.avaliacoes_5)`;
const N_SQL = (p: string) => `(${p}.avaliacoes_1 + ${p}.avaliacoes_2 + ${p}.avaliacoes_3 + ${p}.avaliacoes_4 + ${p}.avaliacoes_5)`;

/** Categoria principal (a de menor ordem) do profissional `p` */
const CATEGORIA_PRINCIPAL_SQL = `(SELECT pc.categoria_id FROM profissional_categoria pc JOIN categoria c ON c.id = pc.categoria_id
   WHERE pc.profissional_id = p.utilizador_id ORDER BY c.ordem, c.id LIMIT 1)`;

// ---------------------------------------------------------------------
// Pesquisa
// ---------------------------------------------------------------------

/** Ids dos profissionais ativos e disponíveis (opcionalmente de uma categoria) */
export async function idsDisponiveis(f: { categoriaId?: number; excluir?: number }, db: Db = pool): Promise<number[]> {
  const rows = await query<{ id: number }>(
    `SELECT p.utilizador_id AS id FROM profissional p JOIN utilizador u ON u.id = p.utilizador_id
      WHERE u.ativo = TRUE AND p.disponivel = TRUE AND p.utilizador_id <> ?
        ${f.categoriaId ? 'AND EXISTS (SELECT 1 FROM profissional_categoria x WHERE x.profissional_id = p.utilizador_id AND x.categoria_id = ?)' : ''}`,
    [f.excluir ?? 0, ...(f.categoriaId ? [f.categoriaId] : [])],
    db,
  );
  return rows.map((r) => r.id);
}

export interface FiltrosPesquisa {
  q?: string;
  categoriaId?: number;
  verificado?: boolean;
  lat?: number;
  lng?: number;
  raioKm: number;
  ordenar: 'distancia' | 'avaliacao' | 'servicos';
  limit: number;
  offset: number;
}

/** GET /profissionais (RF02) */
export async function pesquisar(f: FiltrosPesquisa, db: Db = pool) {
  const temGeo = f.lat !== undefined && f.lng !== undefined;
  const where = ['u.ativo = TRUE', 'p.disponivel = TRUE'];
  const params: unknown[] = [];
  const distSql = temGeo ? distanciaKmSql('p.latitude', 'p.longitude') : 'NULL';
  const distParams = temGeo ? geoParams(f.lat!, f.lng!) : [];

  if (f.categoriaId) {
    where.push('EXISTS (SELECT 1 FROM profissional_categoria x WHERE x.profissional_id = p.utilizador_id AND x.categoria_id = ?)');
    params.push(f.categoriaId);
  }
  if (f.verificado !== undefined) { where.push('p.verificado = ?'); params.push(f.verificado); }
  if (f.q) {
    where.push(`(u.nome LIKE ? OR p.bio LIKE ? OR EXISTS (SELECT 1 FROM profissional_categoria y JOIN categoria cy ON cy.id = y.categoria_id
                  WHERE y.profissional_id = p.utilizador_id AND cy.nome LIKE ?))`);
    params.push(`%${f.q}%`, `%${f.q}%`, `%${f.q}%`);
  }
  const having = temGeo ? 'HAVING distancia_km IS NOT NULL AND distancia_km <= ?' : '';
  // "avaliacao" ordena pela média bayesiana (services/estatistica.ts): 5,0 em 2 avaliações vale ~4,82
  // e uma nota fraca pesa pouco a quem tem 126. O prior é a média da categoria pesquisada
  // (ou da categoria principal de cada um) e, sem avaliações na categoria, a média global.
  const ordem =
    f.ordenar === 'distancia' && temGeo ? 'distancia_km ASC'
    : f.ordenar === 'servicos' ? 'p.total_servicos DESC, p.media_avaliacao DESC'
    : 'p.verificado DESC, media_bayesiana DESC, p.total_avaliacoes DESC';
  const priorSql = `COALESCE((SELECT vm.media FROM vw_media_categoria vm WHERE vm.categoria_id = COALESCE(?, ${CATEGORIA_PRINCIPAL_SQL})),
                             (SELECT SUM(${SOMA_SQL('g')}) / NULLIF(SUM(${N_SQL('g')}), 0) FROM profissional g), 0)`;

  return query(
    `SELECT p.utilizador_id AS id, u.nome, u.foto_url, p.zona, p.verificado, p.media_avaliacao, p.total_avaliacoes, p.total_servicos,
            (SELECT GROUP_CONCAT(c.nome ORDER BY c.ordem SEPARATOR ', ') FROM profissional_categoria pc
               JOIN categoria c ON c.id = pc.categoria_id WHERE pc.profissional_id = p.utilizador_id) AS categorias,
            ROUND(${distSql}, 1) AS distancia_km,
            ROUND((? * ${priorSql} + ${SOMA_SQL('p')}) / (? + ${N_SQL('p')}), 2) AS media_bayesiana
       FROM profissional p JOIN utilizador u ON u.id = p.utilizador_id
      WHERE ${where.join(' AND ')}
      ${having}
      ORDER BY ${ordem}
      LIMIT ? OFFSET ?`,
    [...distParams, PRIOR_M, f.categoriaId ?? null, PRIOR_M, ...params, ...(temGeo ? [f.raioKm] : []), f.limit, f.offset],
    db,
  );
}

// ---------------------------------------------------------------------
// Área do profissional
// ---------------------------------------------------------------------

export async function base(profissionalId: number, db: Db = pool) {
  return queryOne<{ latitude: number | null; longitude: number | null; raio_atuacao_km: number }>(
    `SELECT latitude, longitude, raio_atuacao_km FROM profissional WHERE utilizador_id = ?`,
    [profissionalId],
    db,
  );
}

export async function resumoDoPainel(profissionalId: number, db: Db = pool) {
  return queryOne(
    `SELECT u.nome, p.zona, p.raio_atuacao_km, p.media_avaliacao, p.total_servicos, p.disponivel, p.verificado
       FROM profissional p JOIN utilizador u ON u.id = p.utilizador_id WHERE p.utilizador_id = ?`,
    [profissionalId],
    db,
  );
}

/** Registo do ecrã 12: atualiza só os campos enviados (as colunas vêm do schema da rota) */
export async function atualizarPerfil(profissionalId: number, campos: [string, unknown][], db: Db) {
  if (!campos.length) return;
  await execute(
    `UPDATE profissional SET ${campos.map(([k]) => `${k} = ?`).join(', ')} WHERE utilizador_id = ?`,
    [...campos.map(([, v]) => v), profissionalId],
    db,
  );
}

export async function substituirCategorias(profissionalId: number, categoriaIds: number[], db: Db) {
  await execute(`DELETE FROM profissional_categoria WHERE profissional_id = ?`, [profissionalId], db);
  await execute(`INSERT INTO profissional_categoria (profissional_id, categoria_id) VALUES ?`, [categoriaIds.map((c) => [profissionalId, c])], db);
}

/** O nome do utilizador muda e a conta (e a sessão) passam a profissional */
export async function tornarProfissional(utilizadorId: number, sessaoId: number, nomeCompleto: string | undefined, db: Db) {
  if (nomeCompleto) await execute(`UPDATE utilizador SET nome = ? WHERE id = ?`, [nomeCompleto, utilizadorId], db);
  await execute(`UPDATE utilizador SET tipo_perfil = 'profissional' WHERE id = ? AND tipo_perfil = 'cliente'`, [utilizadorId], db);
  await execute(`UPDATE sessao SET perfil_ativo = 'profissional' WHERE id = ?`, [sessaoId], db);
}

export async function substituirHorario(profissionalId: number, horarios: { dia_semana: number; hora_inicio: string; hora_fim: string }[], db: Db) {
  await execute(`DELETE FROM disponibilidade WHERE profissional_id = ?`, [profissionalId], db);
  if (horarios.length) {
    await execute(
      `INSERT INTO disponibilidade (profissional_id, dia_semana, hora_inicio, hora_fim) VALUES ?`,
      [horarios.map((h) => [profissionalId, h.dia_semana, h.hora_inicio, h.hora_fim])],
      db,
    );
  }
}

// ---------------------------------------------------------------------
// Verificação de identidade (RF07)
// ---------------------------------------------------------------------

export async function ultimaVerificacao(profissionalId: number, db: Db = pool) {
  return queryOne(
    `SELECT id, estado, tipo_documento, documento_url IS NOT NULL AS documento_enviado,
            selfie_url IS NOT NULL AS rosto_enviado, motivo_rejeicao, criado_em, submetido_em, revisto_em
       FROM verificacao_identidade WHERE profissional_id = ? ORDER BY id DESC LIMIT 1`,
    [profissionalId],
    db,
  );
}

export async function ultimaVerificacaoParaAtualizar(profissionalId: number, db: Db) {
  return queryOne(
    `SELECT id, estado, documento_url, selfie_url FROM verificacao_identidade WHERE profissional_id = ? ORDER BY id DESC LIMIT 1 FOR UPDATE`,
    [profissionalId],
    db,
  );
}

export async function criarRascunhoVerificacao(profissionalId: number, db: Db): Promise<number> {
  const r = await execute(`INSERT INTO verificacao_identidade (profissional_id, estado) VALUES (?, 'rascunho')`, [profissionalId], db);
  return r.insertId;
}

export async function guardarDocumento(id: number, url: string, tipo: string, numero: string | null, db: Db) {
  await execute(
    `UPDATE verificacao_identidade SET documento_url = ?, tipo_documento = ?, numero_documento = COALESCE(?, numero_documento) WHERE id = ?`,
    [url, tipo, numero, id],
    db,
  );
}

export async function guardarRosto(id: number, url: string, db: Db) {
  await execute(`UPDATE verificacao_identidade SET selfie_url = ? WHERE id = ?`, [url, id], db);
}

export async function submeterVerificacao(id: number, db: Db) {
  await execute(`UPDATE verificacao_identidade SET estado = 'pendente', submetido_em = NOW() WHERE id = ?`, [id], db);
}

export async function verificacaoAberta(profissionalId: number, db: Db = pool) {
  return queryOne(`SELECT id, estado FROM verificacao_identidade WHERE profissional_id = ? AND estado IN ('pendente','aprovada')`, [profissionalId], db);
}

/** Pedido do selo de uma só vez: apaga o rascunho e fica logo pendente */
export async function inserirVerificacaoCompleta(
  profissionalId: number,
  v: { tipo: string; numero: string; documento: string; selfie: string },
  db: Db,
): Promise<number> {
  await execute(`DELETE FROM verificacao_identidade WHERE profissional_id = ? AND estado = 'rascunho'`, [profissionalId], db);
  const r = await execute(
    `INSERT INTO verificacao_identidade (profissional_id, tipo_documento, numero_documento, documento_url, selfie_url, estado, submetido_em)
     VALUES (?,?,?,?,?, 'pendente', NOW())`,
    [profissionalId, v.tipo, v.numero, v.documento, v.selfie],
    db,
  );
  return r.insertId;
}

// ---------------------------------------------------------------------
// Galeria de trabalhos (RF06)
// ---------------------------------------------------------------------

export async function servicoConcluidoDoProfissional(pedidoId: number, profissionalId: number, db: Db = pool): Promise<boolean> {
  const ok = await queryOne(
    `SELECT pe.id FROM pedido pe JOIN proposta pr ON pr.id = pe.proposta_aceite_id
      WHERE pe.id = ? AND pr.profissional_id = ? AND pe.estado = 'concluido'`,
    [pedidoId, profissionalId],
    db,
  );
  return !!ok;
}

export async function inserirTrabalho(profissionalId: number, pedidoId: number | null, url: string, legenda: string | null, db: Db = pool) {
  const r = await execute(`INSERT INTO trabalho_foto (profissional_id, pedido_id, url, legenda) VALUES (?,?,?,?)`, [profissionalId, pedidoId, url, legenda], db);
  return r.insertId;
}

export async function apagarTrabalho(id: number, profissionalId: number, db: Db = pool): Promise<boolean> {
  const r = await execute(`DELETE FROM trabalho_foto WHERE id = ? AND profissional_id = ?`, [id, profissionalId], db);
  return r.affectedRows > 0;
}

// ---------------------------------------------------------------------
// Perfil público (ecrã 03)
// ---------------------------------------------------------------------

export async function perfil(id: number, db: Db = pool) {
  return queryOne(
    `SELECT p.utilizador_id AS id, u.nome, u.foto_url, p.bio, p.anos_experiencia, p.disponivel, p.verificado, p.verificado_em,
            p.media_avaliacao, p.total_avaliacoes, p.total_servicos, p.especialidades, u.criado_em AS membro_desde
       FROM profissional p JOIN utilizador u ON u.id = p.utilizador_id
      WHERE p.utilizador_id = ? AND u.ativo = TRUE`,
    [id],
    db,
  );
}

/**
 * Distribuição das avaliações por estrelas e média global da categoria principal
 * (para GET /profissionais/:id/estatisticas). null se o profissional não existe.
 */
export async function distribuicaoAvaliacoes(id: number, db: Db = pool) {
  const r = await queryOne(
    `SELECT p.avaliacoes_1, p.avaliacoes_2, p.avaliacoes_3, p.avaliacoes_4, p.avaliacoes_5,
            (SELECT vm.media FROM vw_media_categoria vm WHERE vm.categoria_id = ${CATEGORIA_PRINCIPAL_SQL}) AS media_categoria
       FROM profissional p JOIN utilizador u ON u.id = p.utilizador_id
      WHERE p.utilizador_id = ? AND u.ativo = TRUE`,
    [id],
    db,
  );
  if (!r) return null;
  const distribuicao: Distribuicao = {
    1: Number(r.avaliacoes_1), 2: Number(r.avaliacoes_2), 3: Number(r.avaliacoes_3), 4: Number(r.avaliacoes_4), 5: Number(r.avaliacoes_5),
  };
  return { distribuicao, mediaCategoria: r.media_categoria === null ? null : Number(r.media_categoria) };
}

export async function categorias(id: number, db: Db = pool) {
  return query(
    `SELECT c.id, c.chave, c.nome, c.icone FROM profissional_categoria pc JOIN categoria c ON c.id = pc.categoria_id WHERE pc.profissional_id = ? ORDER BY c.ordem`,
    [id],
    db,
  );
}

export async function trabalhos(id: number, limit = 30, db: Db = pool) {
  return query(
    `SELECT id, url, legenda, pedido_id, criado_em FROM trabalho_foto WHERE profissional_id = ? AND visivel = TRUE ORDER BY criado_em DESC, id DESC LIMIT ?`,
    [id, limit],
    db,
  );
}

export async function totalTrabalhos(id: number, db: Db = pool): Promise<number> {
  const r = await queryOne<{ n: number }>(`SELECT COUNT(*) n FROM trabalho_foto WHERE profissional_id = ? AND visivel = TRUE`, [id], db);
  return Number(r!.n);
}

export async function etiquetasMaisDadas(id: number, db: Db = pool) {
  return query(
    `SELECT e.chave, e.nome, COUNT(*) AS total FROM avaliacao a JOIN avaliacao_etiqueta ae ON ae.avaliacao_id = a.id JOIN etiqueta e ON e.id = ae.etiqueta_id
      WHERE a.profissional_id = ? GROUP BY e.id, e.chave, e.nome ORDER BY total DESC LIMIT 5`,
    [id],
    db,
  );
}

export async function horario(id: number, db: Db = pool) {
  return query(
    `SELECT dia_semana, TIME_FORMAT(hora_inicio,'%H:%i') AS hora_inicio, TIME_FORMAT(hora_fim,'%H:%i') AS hora_fim
       FROM disponibilidade WHERE profissional_id = ? ORDER BY dia_semana, hora_inicio`,
    [id],
    db,
  );
}

export async function avaliacoes(profissionalId: number, limit: number, offset = 0, db: Db = pool) {
  return query(
    `SELECT a.id, a.estrelas, a.comentario, a.criado_em, u.nome AS cliente, c.nome AS categoria,
            (SELECT GROUP_CONCAT(e.chave ORDER BY e.id) FROM avaliacao_etiqueta ae JOIN etiqueta e ON e.id = ae.etiqueta_id WHERE ae.avaliacao_id = a.id) AS chaves,
            (SELECT GROUP_CONCAT(e.nome ORDER BY e.id SEPARATOR ', ') FROM avaliacao_etiqueta ae JOIN etiqueta e ON e.id = ae.etiqueta_id WHERE ae.avaliacao_id = a.id) AS nomes
       FROM avaliacao a JOIN utilizador u ON u.id = a.cliente_id JOIN pedido pe ON pe.id = a.pedido_id JOIN categoria c ON c.id = pe.categoria_id
      WHERE a.profissional_id = ? ORDER BY a.criado_em DESC, a.id DESC LIMIT ? OFFSET ?`,
    [profissionalId, limit, offset],
    db,
  );
}
