/**
 * Formas JSON combinadas com a app Flutter (docs/CONTRATO-APP.md, secção 1).
 * Regras: ids inteiros, valores em Kz inteiros, booleanos true/false, datas ISO em UTC.
 */
import { Db, pool, query, queryOne } from '../config/db';
import { distanciaKm } from '../utils/geo';

export interface Ponto { lat: number; lng: number }
export interface Leitor { id: number; tipo_perfil: string }

/** "Maria Kiala" → "Maria K."; um só nome fica igual */
export function nomeCurto(nome: string | null | undefined): string | null {
  if (!nome) return null;
  const partes = nome.trim().split(/\s+/);
  return partes.length > 1 ? `${partes[0]} ${partes[partes.length - 1][0]}.` : partes[0];
}

/** Primeiro nome ("Joaquim Manuel" → "Joaquim") */
export const primeiroNome = (nome: string | null | undefined) => (nome ? nome.trim().split(/\s+/)[0] : null);

/** Valor em Kz como inteiro (ou null) */
export const kz = (v: unknown): number | null => (v === null || v === undefined ? null : Math.round(Number(v)));

/** 12500 → "12 500 Kz" (RNF06) */
export const fmtKz = (v: unknown) => `${String(kz(v) ?? 0).replace(/\B(?=(\d{3})+(?!\d))/g, ' ')} Kz`;

const somarMinutos = (d: Date | string, min: number) => new Date(new Date(d).getTime() + min * 60_000);

// ---------------------------------------------------------------------
// ProfissionalResumo
// ---------------------------------------------------------------------

export interface ProfissionalResumo {
  id: number;
  nome: string | null;
  foto_url: string | null;
  categoria: string | null;
  categoria_chave: string | null;
  zona: string | null;
  distancia_km: number | null;
  rating: number;
  num_avaliacoes: number;
  servicos_confirmados: number;
  anos_experiencia: number | null;
  verificado: boolean;
  mao_de_obra_desde: number | null;
}

/**
 * Carrega o ProfissionalResumo de vários profissionais de uma vez.
 * A categoria principal é a de menor ordem; a distância conta a partir de `ref`.
 */
export async function resumosProfissionais(ids: number[], ref: Ponto | null = null, db: Db = pool) {
  const mapa = new Map<number, ProfissionalResumo & { latitude: number | null; longitude: number | null }>();
  const unicos = [...new Set(ids.filter(Boolean))];
  if (!unicos.length) return mapa;
  const rows = await query(
    `SELECT p.utilizador_id AS id, u.nome, u.foto_url, p.zona, p.latitude, p.longitude, p.anos_experiencia, p.verificado,
            p.media_avaliacao, p.total_avaliacoes, p.total_servicos, p.mao_obra_desde,
            (SELECT c.nome FROM profissional_categoria pc JOIN categoria c ON c.id = pc.categoria_id
              WHERE pc.profissional_id = p.utilizador_id ORDER BY c.ordem, c.id LIMIT 1) AS categoria,
            (SELECT c.chave FROM profissional_categoria pc JOIN categoria c ON c.id = pc.categoria_id
              WHERE pc.profissional_id = p.utilizador_id ORDER BY c.ordem, c.id LIMIT 1) AS categoria_chave
       FROM profissional p JOIN utilizador u ON u.id = p.utilizador_id
      WHERE p.utilizador_id IN (?)`,
    [unicos],
    db,
  );
  for (const r of rows) {
    mapa.set(r.id, {
      id: r.id,
      nome: r.nome,
      foto_url: r.foto_url,
      categoria: r.categoria,
      categoria_chave: r.categoria_chave,
      zona: r.zona,
      distancia_km: ref ? distanciaKm(ref.lat, ref.lng, r.latitude, r.longitude) : null,
      rating: Number(r.media_avaliacao),
      num_avaliacoes: r.total_avaliacoes,
      servicos_confirmados: r.total_servicos,
      anos_experiencia: r.anos_experiencia,
      verificado: !!r.verificado,
      mao_de_obra_desde: kz(r.mao_obra_desde),
      latitude: r.latitude,
      longitude: r.longitude,
    });
  }
  return mapa;
}

/** Tira as coordenadas internas antes de enviar */
export function semCoordenadas<T extends { latitude?: unknown; longitude?: unknown }>(r: T | undefined | null) {
  if (!r) return null;
  const { latitude: _la, longitude: _lo, ...resto } = r;
  return resto;
}

export async function resumoProfissional(id: number, ref: Ponto | null = null, db: Db = pool) {
  return semCoordenadas((await resumosProfissionais([id], ref, db)).get(id));
}

/** Ponto de referência do utilizador: a morada predefinida (ou a mais antiga) com GPS */
export async function pontoDoUtilizador(utilizadorId: number, db: Db = pool): Promise<Ponto | null> {
  const m = await queryOne(
    `SELECT latitude, longitude FROM morada
      WHERE utilizador_id = ? AND latitude IS NOT NULL AND longitude IS NOT NULL
      ORDER BY predefinida DESC, id LIMIT 1`,
    [utilizadorId],
    db,
  );
  return m ? { lat: Number(m.latitude), lng: Number(m.longitude) } : null;
}

// ---------------------------------------------------------------------
// PropostaJSON
// ---------------------------------------------------------------------

export const CAMPOS_PROPOSTA = `pr.id, pr.pedido_id, pr.profissional_id, pr.estado, pr.valor_mao_obra, pr.valor_material, pr.valor_deslocacao,
  pr.valor_total, pr.inclui_descricao, pr.material_detalhe, pr.tempo_chegada_min, pr.na_hora_pedida, pr.mensagem, pr.criado_em, pr.respondida_em`;

/** Hora prevista de chegada: a hora pedida, a da aceitação + tempo, ou agora + tempo */
export function chegadaPrevista(pr: any, dataPretendida: Date | string | null): Date | null {
  if (pr.na_hora_pedida) return dataPretendida ? new Date(dataPretendida) : null;
  if (pr.tempo_chegada_min === null || pr.tempo_chegada_min === undefined) return null;
  if (pr.estado === 'aceite' && pr.respondida_em) return somarMinutos(pr.respondida_em, pr.tempo_chegada_min);
  return somarMinutos(new Date(), pr.tempo_chegada_min);
}

export function propostaJSON(pr: any, dataPretendida: Date | string | null, profissional: unknown) {
  return {
    id: pr.id,
    proposta_id: pr.id,
    pedido_id: pr.pedido_id,
    estado: pr.estado,
    valor_total: kz(pr.valor_total),
    componentes: {
      mao_de_obra: kz(pr.valor_mao_obra),
      material: kz(pr.valor_material),
      deslocacao: kz(pr.valor_deslocacao),
    },
    inclui_descricao: pr.inclui_descricao,
    material_detalhe: pr.material_detalhe,
    tempo_chegada_min: pr.tempo_chegada_min,
    na_hora_pedida: !!pr.na_hora_pedida,
    chegada_prevista: chegadaPrevista(pr, dataPretendida),
    profissional,
  };
}

/** Uma proposta já no formato PropostaJSON */
export async function propostaPorId(id: number, db: Db = pool) {
  const pr = await queryOne(
    `SELECT ${CAMPOS_PROPOSTA}, pe.data_pretendida, m.latitude AS m_lat, m.longitude AS m_lng
       FROM proposta pr JOIN pedido pe ON pe.id = pr.pedido_id JOIN morada m ON m.id = pe.morada_id
      WHERE pr.id = ?`,
    [id],
    db,
  );
  if (!pr) return null;
  const ref = pr.m_lat !== null ? { lat: Number(pr.m_lat), lng: Number(pr.m_lng) } : null;
  return propostaJSON(pr, pr.data_pretendida, await resumoProfissional(pr.profissional_id, ref, db));
}

// ---------------------------------------------------------------------
// PedidoJSON
// ---------------------------------------------------------------------

/**
 * Converte pedidos em PedidoJSON, pela ordem de `ids`.
 * Com `propostas`, junta as propostas que o leitor pode ver: o cliente (ou o admin) vê
 * as enviadas e a aceite; um profissional vê só a sua.
 */
export async function pedidosJSON(ids: number[], leitor: Leitor, opcoes: { propostas?: boolean } = {}, db: Db = pool) {
  if (!ids.length) return [];
  const rows = await query(
    `SELECT pe.id, pe.titulo, pe.descricao, pe.estado, pe.criado_em, pe.publicado_em, pe.concluido_em, pe.data_pretendida,
            pe.proposta_aceite_id, pe.cliente_id, c.chave AS categoria_chave, m.bairro, m.municipio,
            m.latitude AS m_lat, m.longitude AS m_lng, uc.nome AS cliente_nome,
            (SELECT COUNT(*) FROM pedido_foto f WHERE f.pedido_id = pe.id) AS num_fotos,
            (SELECT COUNT(*) FROM proposta x WHERE x.pedido_id = pe.id AND x.estado IN ('enviada','aceite')) AS total_propostas,
            EXISTS (SELECT 1 FROM avaliacao a WHERE a.pedido_id = pe.id) AS avaliado,
            pr.profissional_id AS profissional_aceite_id, COALESCE(cs.valor_acordado, pr.valor_total) AS valor_acordado
       FROM pedido pe
       JOIN categoria c ON c.id = pe.categoria_id
       JOIN morada m ON m.id = pe.morada_id
       JOIN utilizador uc ON uc.id = pe.cliente_id
       LEFT JOIN proposta pr ON pr.id = pe.proposta_aceite_id
       LEFT JOIN confirmacao_servico cs ON cs.pedido_id = pe.id
      WHERE pe.id IN (?)`,
    [ids],
    db,
  );

  let propostas: any[] = [];
  if (opcoes.propostas) {
    propostas = await query(
      `SELECT ${CAMPOS_PROPOSTA}, pe.cliente_id
         FROM proposta pr JOIN pedido pe ON pe.id = pr.pedido_id
        WHERE pr.pedido_id IN (?)
          AND ((pe.cliente_id = ? OR ? = 'admin') AND pr.estado IN ('enviada','aceite') OR pr.profissional_id = ?)
        ORDER BY pr.valor_total, pr.id`,
      [ids, leitor.id, leitor.tipo_perfil, leitor.id],
      db,
    );
  }

  // Resumos com a distância a partir da morada de cada pedido
  const resumos = new Map<number, Map<number, any>>();
  for (const r of rows) {
    const profs = [r.profissional_aceite_id, ...propostas.filter((p) => p.pedido_id === r.id).map((p) => p.profissional_id)];
    const ref = r.m_lat !== null ? { lat: Number(r.m_lat), lng: Number(r.m_lng) } : null;
    resumos.set(r.id, await resumosProfissionais(profs, ref, db));
  }

  const souProfissional = leitor.tipo_perfil === 'profissional';
  const porId = new Map(rows.map((r) => [r.id, r]));
  return ids
    .filter((id) => porId.has(id))
    .map((id) => {
      const r = porId.get(id)!;
      const doPedido = resumos.get(id)!;
      return {
        id: r.id,
        titulo: r.titulo,
        descricao: r.descricao,
        categoria_chave: r.categoria_chave,
        estado: r.estado,
        criado_em: r.criado_em,
        publicado_em: r.publicado_em,
        concluido_em: r.concluido_em,
        data_pretendida: r.data_pretendida,
        zona: r.bairro ?? r.municipio,
        num_fotos: Number(r.num_fotos),
        profissional: semCoordenadas(doPedido.get(r.profissional_aceite_id)),
        valor_acordado: r.proposta_aceite_id ? kz(r.valor_acordado) : null,
        proposta_aceite_id: r.proposta_aceite_id,
        cliente_curto: souProfissional ? nomeCurto(r.cliente_nome) : null,
        total_propostas: Number(r.total_propostas),
        avaliado: !!r.avaliado,
        pode_reclamar: podeReclamar(r),
        propostas: propostas
          .filter((p) => p.pedido_id === id)
          .map((p) => propostaJSON(p, r.data_pretendida, semCoordenadas(doPedido.get(p.profissional_id)))),
      };
    });
}

/** Garantia de 7 dias (RF11): há serviço aceite e ainda não está concluído, ou foi concluído há menos de 7 dias */
const ESTADOS_COM_SERVICO = ['aceite', 'a_caminho', 'em_curso'];
export function podeReclamar(r: { proposta_aceite_id: number | null; estado: string; concluido_em: Date | string | null }): boolean {
  if (!r.proposta_aceite_id) return false;
  if (ESTADOS_COM_SERVICO.includes(r.estado)) return true;
  if (r.estado !== 'concluido' || !r.concluido_em) return false;
  return new Date(r.concluido_em).getTime() + 7 * 864e5 > Date.now();
}

export async function pedidoJSON(id: number, leitor: Leitor, opcoes: { propostas?: boolean } = { propostas: true }, db: Db = pool) {
  const [p] = await pedidosJSON([id], leitor, opcoes, db);
  return p ?? null;
}

// ---------------------------------------------------------------------
// PedidoPertoJSON (o que o profissional vê antes de propor)
// ---------------------------------------------------------------------

/** Linhas de `pedidosPerto` → PedidoPertoJSON */
export function pedidoPertoJSON(r: any, base: Ponto | null) {
  const publicado = r.publicado_em ? new Date(r.publicado_em).getTime() : 0;
  return {
    id: r.id,
    titulo: r.titulo,
    descricao: r.descricao,
    categoria_chave: r.categoria_chave,
    zona: r.bairro ?? r.municipio,
    distancia_km: base ? distanciaKm(base.lat, base.lng, r.m_lat, r.m_lng) : null,
    data_pretendida: r.data_pretendida,
    publicado_em: r.publicado_em,
    novo: !r.ja_propus && Date.now() - publicado < 60 * 60_000,
  };
}

/**
 * Pedidos abertos das categorias do profissional, dentro do raio de atuação
 * (os pedidos sem GPS aparecem sempre). Mais recentes primeiro.
 */
export async function pedidosPerto(profissionalId: number, db: Db = pool) {
  const prof = await queryOne(`SELECT latitude, longitude, raio_atuacao_km FROM profissional WHERE utilizador_id = ?`, [profissionalId], db);
  if (!prof) return [];
  const base = prof.latitude !== null ? { lat: Number(prof.latitude), lng: Number(prof.longitude) } : null;
  const rows = await query(
    `SELECT pe.id, pe.titulo, pe.descricao, pe.data_pretendida, pe.publicado_em, c.chave AS categoria_chave,
            m.bairro, m.municipio, m.latitude AS m_lat, m.longitude AS m_lng,
            EXISTS (SELECT 1 FROM proposta x WHERE x.pedido_id = pe.id AND x.profissional_id = ?) AS ja_propus
       FROM pedido pe
       JOIN categoria c ON c.id = pe.categoria_id
       JOIN morada m ON m.id = pe.morada_id
       JOIN profissional_categoria pc ON pc.categoria_id = pe.categoria_id AND pc.profissional_id = ?
      WHERE pe.estado IN ('publicado','com_propostas') AND pe.cliente_id <> ?
      ORDER BY pe.publicado_em DESC, pe.id DESC
      LIMIT 100`,
    [profissionalId, profissionalId, profissionalId],
    db,
  );
  return rows
    .map((r) => pedidoPertoJSON(r, base))
    .filter((p) => p.distancia_km === null || p.distancia_km <= prof.raio_atuacao_km);
}

// ---------------------------------------------------------------------
// ComprovativoJSON
// ---------------------------------------------------------------------

export async function comprovativoJSON(pedidoId: number, db: Db = pool) {
  const c = await queryOne(`SELECT * FROM vw_comprovativo WHERE pedido_id = ?`, [pedidoId], db);
  if (!c) return null;
  const valor = kz(c.valor_kz);
  const data = new Date(c.confirmado_em).toLocaleString('pt-PT', { timeZone: 'Africa/Luanda' });
  const texto = `Comprovativo Kisalu Express ${c.numero_comprovativo}: ${c.titulo}, ${fmtKz(valor)}, por ${c.profissional}, confirmado em ${data}.`;
  return {
    numero_comprovativo: c.numero_comprovativo,
    pedido_id: c.pedido_id,
    titulo: c.titulo,
    cliente: c.cliente,
    cliente_curto: nomeCurto(c.cliente),
    profissional: await resumoProfissional(c.profissional_id, null, db),
    valor_kz: valor,
    metodo_pagamento: c.metodo_pagamento,
    metodo_confirmacao: c.metodo_confirmacao,
    confirmado_em: c.confirmado_em,
    valor_formatado: fmtKz(valor),
    partilha_whatsapp: `https://wa.me/?text=${encodeURIComponent(texto)}`,
  };
}

// ---------------------------------------------------------------------
// MensagemJSON
// ---------------------------------------------------------------------

/** lida = é minha e o outro já a leu */
export function mensagemJSON(m: any, meuId: number) {
  const minha = m.remetente_id === meuId;
  return {
    id: Number(m.id),
    texto: m.texto,
    foto_url: m.foto_url,
    minha,
    enviada_em: m.enviada_em,
    lida: minha && m.lida_em !== null,
  };
}
