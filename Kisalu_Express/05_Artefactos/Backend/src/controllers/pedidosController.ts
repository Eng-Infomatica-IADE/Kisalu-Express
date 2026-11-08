/**
 * Controller dos pedidos: regras do ciclo de vida do pedido (criar, editar, publicar,
 * cancelar, estados) e respostas no formato do contrato. O SQL está nos models.
 */
import { Request, Response } from 'express';
import { env } from '../config/env';
import { Db, pool, transaction } from '../config/db';
import { badRequest, conflict, forbidden, notFound } from '../utils/errors';
import { distanciaKm } from '../utils/geo';
import { ficheiros, guardarImagem } from '../middlewares/upload';
import { notificar } from '../services/notificacoes';
import { categoria as obterCategoria } from '../services/categorias';
import { kz, nomeCurto, pedidoJSON, pedidosJSON } from '../services/formatos';
import { papelNoPedido } from '../services/pedidos';
import { estimativaDaProposta } from '../services/monteCarlo';
import * as Pedido from '../models/pedidoModel';
import * as Proposta from '../models/propostaModel';
import * as Conversa from '../models/conversaModel';
import * as Profissional from '../models/profissionalModel';
import * as Confirmacao from '../models/confirmacaoModel';

const { ESTADOS_ABERTOS, ESTADOS_ATIVOS } = Pedido;

async function verificarMorada(moradaId: number, utilizadorId: number, db: Db = pool) {
  if (!(await Pedido.moradaDoUtilizador(moradaId, utilizadorId, db))) {
    throw badRequest('A morada indicada não é sua.', 'MORADA_INVALIDA');
  }
}

/** Avisa os profissionais da categoria, disponíveis e dentro do raio de atuação */
async function notificarProfissionaisProximos(pedidoId: number, db: Db): Promise<number> {
  const { pedido: pe, profissionais } = await Pedido.profissionaisAAvisar(pedidoId, db);
  for (const id of profissionais) {
    await notificar(
      id,
      { tipo: 'novo_pedido', titulo: 'Novo pedido perto de si', corpo: `${pe.titulo} · ${pe.bairro ?? pe.municipio}`, pedido_id: pedidoId, acao: 'ver_pedido' },
      db,
    );
  }
  return profissionais.length;
}

// ---------------- Criar e listar ----------------

export async function criar(req: Request, res: Response) {
  const b = req.valid.body;
  const cat = await obterCategoria(b.categoria_id ?? b.categoria_chave);
  const dataPretendida = b.quando ?? b.data_pretendida ?? null;
  const urgencia = b.urgencia ?? (dataPretendida ? 'agendado' : 'o_mais_cedo_possivel');
  const publicar = b.publicar;

  const out = await transaction(async (conn) => {
    let moradaId = b.morada_id;
    if (moradaId) await verificarMorada(moradaId, req.user!.id, conn);
    else moradaId = await Pedido.moradaDaZona(req.user!.id, b.zona, b.ponto_referencia, conn);

    const id = await Pedido.inserirPedido(
      { clienteId: req.user!.id, categoriaId: cat.id, moradaId: moradaId!, titulo: b.titulo, descricao: b.descricao, urgencia, dataPretendida, publicar },
      conn,
    );
    const n = publicar ? await notificarProfissionaisProximos(id, conn) : 0;
    return { id, n };
  });
  res.status(201).json({
    id: out.id,
    estado: publicar ? 'publicado' : 'rascunho',
    pedido: await pedidoJSON(out.id, req.user!),
    profissionais_avisados: out.n,
    categoria_plural: cat.plural,
  });
}

export async function listar(req: Request, res: Response) {
  const f = req.valid.query;
  const ids = await Pedido.idsDosMeusPedidos({
    utilizadorId: req.user!.id,
    comoCliente: req.user!.tipo_perfil === 'cliente',
    grupo: f.grupo,
    categoriaId: f.categoria_id,
    limit: f.limit,
    offset: f.offset,
  });
  res.json(await pedidosJSON(ids, req.user!));
}

export async function emCurso(req: Request, res: Response) {
  const [id] = await Pedido.idsEmCursoDoCliente(req.user!.id, ESTADOS_ATIVOS);
  res.json(id ? await pedidoJSON(id, req.user!) : null);
}

export async function emCursoLista(req: Request, res: Response) {
  const ids = await Pedido.idsEmCursoDoCliente(req.user!.id, ESTADOS_ATIVOS);
  res.json(await pedidosJSON(ids, req.user!));
}

const trabalhoJSON = (t: { id: number; titulo: string; cliente: string; valor_acordado: number }) => ({
  pedido_id: t.id,
  servico: t.titulo,
  cliente: nomeCurto(t.cliente),
  valor: kz(t.valor_acordado),
});

export async function porConfirmar(req: Request, res: Response) {
  const [t] = await Pedido.trabalhosPorConfirmar(req.user!.id, ESTADOS_ATIVOS);
  res.json(t ? trabalhoJSON(t) : null);
}

export async function porConfirmarLista(req: Request, res: Response) {
  res.json((await Pedido.trabalhosPorConfirmar(req.user!.id, ESTADOS_ATIVOS)).map(trabalhoJSON));
}

export async function proximos(req: Request, res: Response) {
  const { limit, offset } = req.valid.query;
  const prof = await Profissional.base(req.user!.id);
  if (!prof) throw notFound('Perfil profissional');
  const rows = await Pedido.proximosDoProfissional(req.user!.id, prof, limit, offset);
  res.json(rows.map((r) => ({ ...r, ja_propus: !!r.ja_propus })));
}

// ---------------- Detalhe ----------------

export async function detalhe(req: Request, res: Response) {
  const base = await Pedido.carregarPedido(req.valid.params.id);
  const papel = await papelNoPedido(base, req.user);
  const partilhaTotal = papel !== 'profissional'; // cliente, profissional aceite ou admin
  const comContacto = papel === 'profissional_aceite' || papel === 'admin';

  const pe = await Pedido.detalhe(base.id);
  const fotos = await Pedido.fotos(base.id);
  const acordo = base.proposta_aceite_id && partilhaTotal ? await Proposta.acordo(base.proposta_aceite_id) : null;

  const [historico, confirmacao, avaliacao, reclamacoes, conversaId] = partilhaTotal
    ? await Promise.all([
        Pedido.historico(base.id),
        Pedido.confirmacaoResumo(base.id),
        Pedido.avaliacaoDoPedido(base.id),
        Pedido.reclamacoesDoPedido(base.id),
        Conversa.idDaConversa(base.id, base.profissional_aceite_id),
      ])
    : [null, null, null, null, await Conversa.idDaConversa(base.id, req.user!.id)];

  // Para o profissional: distância desde a sua zona base e se é "novo" para ele
  let perto = {};
  if (req.user!.tipo_perfil === 'profissional') {
    const prof = await Profissional.base(req.user!.id);
    const jaPropos = await Proposta.profissionalJaPropos(base.id, req.user!.id);
    perto = {
      distancia_km: prof ? distanciaKm(prof.latitude, prof.longitude, pe.latitude, pe.longitude) : null,
      novo: !jaPropos && ESTADOS_ABERTOS.includes(base.estado) && !!pe.publicado_em
        && Date.now() - new Date(pe.publicado_em).getTime() < 60 * 60_000,
    };
  }

  // Garantia de 7 dias (RF11)
  const garantiaAte = pe.concluido_em ? new Date(new Date(pe.concluido_em).getTime() + 7 * 864e5) : null;

  res.json({
    ...(await pedidoJSON(base.id, req.user!)),
    ...perto,
    urgencia: pe.urgencia,
    motivo_cancelamento: pe.motivo_cancelamento,
    datas: { criado_em: pe.criado_em, publicado_em: pe.publicado_em, concluido_em: pe.concluido_em, cancelado_em: pe.cancelado_em },
    categoria: { id: pe.categoria_id, chave: pe.categoria_chave, nome: pe.categoria, icone: pe.categoria_icone },
    cliente: {
      nome: pe.cliente_nome,
      foto_url: pe.cliente_foto,
      ...(comContacto ? { telemovel: pe.cliente_telemovel } : {}),
    },
    morada: partilhaTotal
      ? { endereco: pe.endereco, ponto_referencia: pe.ponto_referencia, bairro: pe.bairro, municipio: pe.municipio, provincia: pe.provincia, latitude: pe.latitude, longitude: pe.longitude }
      : { bairro: pe.bairro, municipio: pe.municipio, provincia: pe.provincia },
    // RNF10: o que o profissional escolhido precisa para chegar e ligar ao cliente, com nomes claros.
    // null para quem ainda não tem a proposta aceite.
    contacto_cliente: comContacto
      ? {
          nome: pe.cliente_nome,
          telemovel: pe.cliente_telemovel,
          morada: pe.endereco,
          ponto_referencia: pe.ponto_referencia,
          zona: pe.bairro ?? pe.municipio,
          municipio: pe.municipio,
          provincia: pe.provincia,
          latitude: pe.latitude === null ? null : Number(pe.latitude),
          longitude: pe.longitude === null ? null : Number(pe.longitude),
        }
      : null,
    fotos,
    acordo,
    confirmacao,
    garantia: garantiaAte ? { ate: garantiaAte, ativa: garantiaAte.getTime() > Date.now() } : null,
    avaliacao,
    reclamacoes,
    historico,
    conversa_id: conversaId ?? null,
    o_meu_papel: papel,
  });
}

// ---------------- Desfazer a aceitação (ecrã 08) ----------------

export async function desfazerAceitacao(req: Request, res: Response) {
  await transaction(async (conn) => {
    const p = await Pedido.carregarPedido(req.valid.params.id, conn, true);
    if (p.cliente_id !== req.user!.id) throw notFound('Pedido');
    if (p.estado !== 'aceite' || !p.proposta_aceite_id) {
      throw conflict('Já não é possível desfazer. Veja o estado em Pedidos.', 'DESFAZER_IMPOSSIVEL');
    }
    const pr = await Proposta.aceiteComIdade(p.proposta_aceite_id, conn);
    if (pr.segundos > env.desfazerAceitacaoMin * 60) {
      throw conflict('Já não é possível desfazer: passou o tempo permitido. Veja o estado em Pedidos.', 'DESFAZER_IMPOSSIVEL');
    }
    await Pedido.reabrir(p.id, conn);
    await Pedido.marcarAutorDoUltimoEstado(p.id, req.user!.id, conn);
    await Proposta.reativarDepoisDeDesfazer(p.id, pr.id, pr.respondida_em, conn);
    await Confirmacao.apagarPendente(p.id, conn);
    await notificar(
      pr.profissional_id,
      { tipo: 'estado_pedido', titulo: 'Aceitação desfeita', corpo: 'O cliente desfez a aceitação. A sua proposta continua de pé.', pedido_id: p.id },
      conn,
    );
  });
  res.json(await pedidoJSON(req.valid.params.id, req.user!));
}

// ---------------- Editar, publicar, fotos, cancelar ----------------

/**
 * Editar um pedido sem proposta aceite. Aceita o formato da app (o mesmo do POST /pedidos:
 * categoria_chave, titulo, descricao, zona, ponto_referencia, quando) e o formato completo
 * (categoria_id, morada_id, urgencia, data_pretendida). Devolve o PedidoJSON atualizado.
 */
export async function editar(req: Request, res: Response) {
  const p = await Pedido.carregarPedido(req.valid.params.id);
  if (p.cliente_id !== req.user!.id) throw notFound('Pedido');
  if (p.proposta_aceite_id || !['rascunho', ...ESTADOS_ABERTOS].includes(p.estado)) {
    throw conflict('Este pedido já tem uma proposta aceite e não pode ser editado. Fale com o profissional no chat.', 'PEDIDO_NAO_EDITAVEL');
  }
  const b = req.valid.body;

  await transaction(async (conn) => {
    const campos: Record<string, unknown> = {
      titulo: b.titulo,
      descricao: b.descricao,
    };
    if (b.categoria_id !== undefined || b.categoria_chave !== undefined) {
      campos.categoria_id = (await obterCategoria(b.categoria_id ?? b.categoria_chave)).id;
    }
    if (b.morada_id) {
      await verificarMorada(b.morada_id, req.user!.id, conn);
      campos.morada_id = b.morada_id;
    } else if (b.zona !== undefined || b.ponto_referencia !== undefined) {
      const atual = await Pedido.moradaDoPedido(p.id, conn);
      const zona = b.zona ?? atual?.bairro ?? atual?.municipio;
      const ponto = b.ponto_referencia !== undefined ? b.ponto_referencia : atual?.ponto_referencia;
      campos.morada_id = await Pedido.moradaDaZona(req.user!.id, zona, ponto, conn);
    }
    // "quando" (formato da app): null = o mais cedo possível; uma data = agendado
    if (b.quando !== undefined) {
      campos.data_pretendida = b.quando;
      campos.urgencia = b.quando ? 'agendado' : 'o_mais_cedo_possivel';
    }
    if (b.data_pretendida !== undefined) campos.data_pretendida = b.data_pretendida;
    if (b.urgencia !== undefined) campos.urgencia = b.urgencia;
    if (campos.urgencia === 'agendado' && !campos.data_pretendida && !(await Pedido.dataPretendida(p.id, conn))) {
      throw badRequest('Escolha quando precisa do serviço.', 'DATA_EM_FALTA');
    }
    await Pedido.atualizarPedido(p.id, campos as any, conn);
  });
  res.json(await pedidoJSON(p.id, req.user!));
}

export async function publicar(req: Request, res: Response) {
  const out = await transaction(async (conn) => {
    const p = await Pedido.carregarPedido(req.valid.params.id, conn, true);
    if (p.cliente_id !== req.user!.id) throw notFound('Pedido');
    if (p.estado !== 'rascunho') throw conflict('Só se publica um rascunho.');
    await Pedido.publicar(p.id, conn);
    return { id: p.id, estado: 'publicado', profissionais_avisados: await notificarProfissionaisProximos(p.id, conn) };
  });
  res.json(out);
}

export async function juntarFotos(req: Request, res: Response) {
  const p = await Pedido.carregarPedido(req.valid.params.id);
  if (p.cliente_id !== req.user!.id) throw notFound('Pedido');
  if (!['rascunho', ...ESTADOS_ABERTOS].includes(p.estado)) throw conflict('Já não é possível juntar fotos a este pedido.');
  const fotos = ficheiros(req, 'fotos');
  if (!fotos.length) throw badRequest('Envie as imagens no campo "fotos".');
  if ((await Pedido.contarFotos(p.id)) + fotos.length > 5) throw badRequest('Cada pedido aceita no máximo 5 fotos.');
  const criadas = [];
  for (const f of fotos) {
    const url = await guardarImagem(f, 'pedidos');
    criadas.push({ id: await Pedido.inserirFoto(p.id, url), url });
  }
  res.status(201).json(criadas);
}

export async function cancelar(req: Request, res: Response) {
  await transaction(async (conn) => {
    const p = await Pedido.carregarPedido(req.valid.params.id, conn, true);
    if (p.cliente_id !== req.user!.id) throw notFound('Pedido');
    if (!['rascunho', 'publicado', 'com_propostas', 'aceite', 'a_caminho'].includes(p.estado)) {
      throw conflict(p.estado === 'em_curso' ? 'O serviço já começou. Use "Reportar problema".' : 'Já não é possível cancelar este pedido.');
    }
    await Pedido.cancelar(p.id, req.valid.body.motivo ?? null, conn);
    await Proposta.expirarEnviadas(p.id, conn);
    await Confirmacao.expirarPendente(p.id, conn);
    for (const id of await Proposta.autoresDoPedido(p.id, conn)) {
      await notificar(id, { tipo: 'estado_pedido', titulo: 'Pedido cancelado', corpo: 'O cliente cancelou um pedido a que respondeu.', pedido_id: p.id }, conn);
    }
  });
  res.json({ id: req.valid.params.id, estado: 'cancelado' });
}

const TRANSICOES: Record<string, string[]> = { a_caminho: ['aceite'], em_curso: ['aceite', 'a_caminho'] };

export async function mudarEstado(req: Request, res: Response) {
  const novo = req.valid.body.estado;
  await transaction(async (conn) => {
    const p = await Pedido.carregarPedido(req.valid.params.id, conn, true);
    if (p.profissional_aceite_id !== req.user!.id) throw forbidden('Este serviço não está associado à sua conta.');
    if (!TRANSICOES[novo].includes(p.estado)) throw conflict(`Não é possível passar de "${p.estado}" para "${novo}".`);
    await Pedido.mudarEstado(p.id, novo, req.user!.id, conn);
    await notificar(
      p.cliente_id,
      novo === 'a_caminho'
        ? { tipo: 'estado_pedido', titulo: 'O profissional está a caminho', corpo: 'Acompanhe a hora prevista no pedido.', pedido_id: p.id, acao: 'ver_pedido' }
        : { tipo: 'estado_pedido', titulo: 'Serviço em curso', corpo: 'Quando o trabalho estiver feito, mostre o QR Code.', pedido_id: p.id, acao: 'ver_qr' },
      conn,
    );
  });
  res.json({ id: req.valid.params.id, estado: novo });
}

export async function pedirDeNovo(req: Request, res: Response) {
  const id = await Pedido.copiarComoRascunho(req.valid.params.id, req.user!.id);
  if (!id) throw notFound('Pedido');
  res.status(201).json({ id, estado: 'rascunho', mensagem: 'Reveja o pedido e publique.', pedido: await pedidoJSON(id, req.user!) });
}

// ---------------- Estimativa de chegada (Monte Carlo, ecrã 04) ----------------

/** Só o cliente do pedido ou o profissional da proposta (ou o admin). Ver docs/MATEMATICA.md. */
export async function estimativaChegada(req: Request, res: Response) {
  const pr = await Proposta.paraEstimativa(req.valid.params.id);
  const u = req.user!;
  if (!pr || (u.id !== pr.cliente_id && u.id !== pr.profissional_id && u.tipo_perfil !== 'admin')) throw notFound('Proposta');
  if (pr.na_hora_pedida || pr.tempo_chegada_min === null) {
    throw badRequest('Esta proposta chega à hora pedida: não há minutos prometidos para simular.', 'SEM_TEMPO_PROMETIDO');
  }
  const distancia = distanciaKm(pr.p_lat, pr.p_lng, pr.m_lat, pr.m_lng);
  if (distancia === null) throw badRequest('Falta a localização do profissional ou da morada.', 'SEM_DISTANCIA');
  res.json({ proposta_id: pr.id, distancia_km: distancia, tempo_prometido_min: pr.tempo_chegada_min, ...estimativaDaProposta(pr.id, distancia, pr.tempo_chegada_min) });
}
