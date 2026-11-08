/**
 * Controller dos profissionais: recebe o pedido já validado (req.valid), aplica as regras
 * e responde. O SQL está em models/profissionalModel.ts; as formas JSON em services/formatos.ts.
 */
import { Request, Response } from 'express';
import { isProduction } from '../config/env';
import { Db, pool, transaction } from '../config/db';
import { badRequest, conflict, notFound } from '../utils/errors';
import { PONTO_PREDEFINIDO, pontoNoMapa } from '../utils/geo';
import { ficheiros, guardarImagem, guardarImagemPrivada } from '../middlewares/upload';
import { euJSON, garantirProfissional } from '../services/conta';
import { idsDeCategorias } from '../services/categorias';
import {
  nomeCurto, pedidosPerto, Ponto, pontoDoUtilizador, primeiroNome, resumosProfissionais, semCoordenadas,
} from '../services/formatos';
import { estatisticasAvaliacoes } from '../services/estatistica';
import * as Profissional from '../models/profissionalModel';

const EXPLICACAO_VERIFICADO =
  'A Kisalu Express confirmou o documento de identidade e comparou-o com uma fotografia do profissional.';

/**
 * Profissionais disponíveis ordenados pela distância a `ref` (os sem GPS ficam no fim).
 * Devolve ProfissionalResumo com as coordenadas internas (para o mapa).
 */
async function porDistancia(ref: Ponto | null, f: { categoriaId?: number; excluir?: number; raioKm?: number; limit?: number }) {
  const ids = await Profissional.idsDisponiveis({ categoriaId: f.categoriaId, excluir: f.excluir });
  const resumos = [...(await resumosProfissionais(ids, ref)).values()];
  return resumos
    .filter((r) => f.raioKm === undefined || (r.distancia_km !== null && r.distancia_km <= f.raioKm))
    .sort((a, b) => (a.distancia_km ?? Infinity) - (b.distancia_km ?? Infinity) || b.rating - a.rating)
    .slice(0, f.limit ?? 100);
}

async function pontoDeReferencia(req: Request): Promise<Ponto> {
  const { lat, lng } = req.valid.query;
  if (lat !== undefined && lng !== undefined) return { lat, lng };
  return (await pontoDoUtilizador(req.user!.id)) ?? PONTO_PREDEFINIDO;
}

// ---------------- Pesquisa ----------------

export async function pesquisar(req: Request, res: Response) {
  const f = req.valid.query;
  const categoriaId = f.categoria_id ?? (f.categoria_chave ? (await idsDeCategorias([f.categoria_chave]))[0] : undefined);
  res.json(
    await Profissional.pesquisar({
      q: f.q,
      categoriaId,
      verificado: f.verificado ? f.verificado === 'true' : undefined,
      lat: f.lat,
      lng: f.lng,
      raioKm: f.raio_km,
      ordenar: f.ordenar,
      limit: f.limit,
      offset: f.offset,
    }),
  );
}

export async function perto(req: Request, res: Response) {
  const f = req.valid.query;
  const ref = await pontoDeReferencia(req);
  const categoriaId = f.categoria_chave ? (await idsDeCategorias([f.categoria_chave]))[0] : undefined;
  const lista = await porDistancia(ref, { categoriaId, excluir: req.user!.id, raioKm: f.raio_km, limit: f.limit });
  res.json(lista.map(semCoordenadas));
}

export async function mapa(req: Request, res: Response) {
  const f = req.valid.query;
  const centro = await pontoDeReferencia(req);
  const categoriaId = f.categoria_chave ? (await idsDeCategorias([f.categoria_chave]))[0] : undefined;
  const lista = await porDistancia(centro, { categoriaId, excluir: req.user!.id });
  const pinos = [];
  for (const p of lista) {
    const pos = pontoNoMapa(centro, p.latitude, p.longitude, f.raio_km);
    if (pos) pinos.push({ ...pos, profissional: semCoordenadas(p) });
  }
  res.json(pinos);
}

// ---------------- Área do profissional ----------------

export async function painel(req: Request, res: Response) {
  const id = req.user!.id;
  const p = await Profissional.resumoDoPainel(id);
  if (!p) throw notFound('Perfil profissional');
  const pedidos = await pedidosPerto(id);
  res.json({
    nome: primeiroNome(p.nome),
    zona: p.zona,
    raio_km: p.raio_atuacao_km,
    pedidos_novos: pedidos.filter((x) => x.novo).length,
    rating: Number(p.media_avaliacao),
    servicos: p.total_servicos,
    disponivel: !!p.disponivel,
    verificado: !!p.verificado,
    pedidos,
  });
}

export async function guardarRegisto(req: Request, res: Response) {
  if (req.user!.tipo_conta === 'admin') throw badRequest('A conta de administração não tem perfil profissional.');
  const { categorias, nome_completo, especialidades, ...campos } = req.valid.body;
  const id = req.user!.id;
  const categoriaIds = categorias ? await idsDeCategorias(categorias) : null;

  await transaction(async (conn) => {
    await garantirProfissional(id, conn);
    const entradas: [string, unknown][] = Object.entries(campos).filter(([, v]) => v !== undefined);
    if (especialidades) entradas.push(['especialidades', JSON.stringify(especialidades)]);
    await Profissional.atualizarPerfil(id, entradas, conn);
    if (categoriaIds) await Profissional.substituirCategorias(id, categoriaIds, conn);
    await Profissional.tornarProfissional(id, req.user!.sessao_id, nome_completo, conn);
  });
  res.json({ perfil_ativo: 'profissional', utilizador: await euJSON(id, 'profissional') });
}

export async function definirHorario(req: Request, res: Response) {
  const { horarios } = req.valid.body;
  await transaction((conn) => Profissional.substituirHorario(req.user!.id, horarios, conn));
  res.json({ horarios });
}

// ---------------- Verificação de identidade (ecrã 13, RF07) ----------------

async function estadoVerificacao(profissionalId: number, db: Db = pool) {
  const v = await Profissional.ultimaVerificacao(profissionalId, db);
  if (!v) return { estado: 'nao_pedida', documento_enviado: false, rosto_enviado: false, motivo_rejeicao: null };
  return { ...v, documento_enviado: !!v.documento_enviado, rosto_enviado: !!v.rosto_enviado };
}

/** Rascunho onde se juntam o documento e o rosto. Cria um novo se não houver (ou se o último foi rejeitado). */
async function rascunhoVerificacao(profissionalId: number, db: Db): Promise<number> {
  const ultima = await Profissional.ultimaVerificacaoParaAtualizar(profissionalId, db);
  if (ultima?.estado === 'aprovada') throw conflict('Já está verificado.');
  if (ultima?.estado === 'pendente') throw conflict('Os documentos já estão em análise.');
  if (ultima?.estado === 'rascunho') return ultima.id;
  return Profissional.criarRascunhoVerificacao(profissionalId, db);
}

/**
 * Guarda a imagem enviada fora da pasta pública (só o admin a vê). Sem ficheiro e fora de
 * produção, fica registada uma captura simulada (a app de demonstração simula a câmara).
 */
async function imagemOuSimulada(req: Request, campo: string, simulado: string) {
  const [f] = ficheiros(req, campo);
  if (f) return guardarImagemPrivada(f, 'verificacoes');
  if (isProduction) throw badRequest(`Envie a imagem no campo "${campo}".`);
  return simulado;
}

export async function verificacao(req: Request, res: Response) {
  res.json(await estadoVerificacao(req.user!.id));
}

export async function juntarDocumento(req: Request, res: Response) {
  const url = await imagemOuSimulada(req, 'documento', 'simulado://documento');
  await transaction(async (conn) => {
    const id = await rascunhoVerificacao(req.user!.id, conn);
    await Profissional.guardarDocumento(id, url, req.valid.body.tipo_documento, req.valid.body.numero_documento ?? null, conn);
  });
  res.json(await estadoVerificacao(req.user!.id));
}

export async function juntarRosto(req: Request, res: Response) {
  const url = await imagemOuSimulada(req, 'rosto', 'simulado://rosto');
  await transaction(async (conn) => {
    const id = await rascunhoVerificacao(req.user!.id, conn);
    await Profissional.guardarRosto(id, url, conn);
  });
  res.json(await estadoVerificacao(req.user!.id));
}

export async function enviarVerificacao(req: Request, res: Response) {
  await transaction(async (conn) => {
    const v = await Profissional.ultimaVerificacaoParaAtualizar(req.user!.id, conn);
    if (v?.estado === 'pendente' || v?.estado === 'aprovada') {
      throw conflict(v.estado === 'aprovada' ? 'Já está verificado.' : 'Os documentos já estão em análise.');
    }
    if (v?.estado !== 'rascunho' || !v.documento_url || !v.selfie_url) {
      const falta = !v?.documento_url || v?.estado !== 'rascunho' ? 'a foto do documento' : 'a fotografia do rosto';
      throw badRequest(`Falta ${falta}.`, 'VERIFICACAO_INCOMPLETA');
    }
    await Profissional.submeterVerificacao(v.id, conn);
  });
  res.json({ ...(await estadoVerificacao(req.user!.id)), mensagem: 'Recebemos os documentos. A análise demora até 48 horas.' });
}

export async function pedirSelo(req: Request, res: Response) {
  const id = req.user!.id;
  const [doc] = ficheiros(req, 'documento');
  const [selfie] = ficheiros(req, 'selfie');
  if (!doc || !selfie) throw badRequest('Envie a foto do documento e uma fotografia sua.');

  const aberta = await Profissional.verificacaoAberta(id);
  if (aberta) throw conflict(aberta.estado === 'aprovada' ? 'Já está verificado.' : 'Já tem um pedido de verificação em análise.');

  const [docUrl, selfieUrl] = await Promise.all([guardarImagemPrivada(doc, 'verificacoes'), guardarImagemPrivada(selfie, 'verificacoes')]);
  const novoId = await transaction((conn) =>
    Profissional.inserirVerificacaoCompleta(
      id,
      { tipo: req.valid.body.tipo_documento, numero: req.valid.body.numero_documento, documento: docUrl, selfie: selfieUrl },
      conn,
    ),
  );
  res.status(201).json({ id: novoId, estado: 'pendente', mensagem: 'Recebemos os documentos. A análise demora até 48 horas.' });
}

// ---------------- Galeria de trabalhos (RF06) ----------------

export async function adicionarTrabalhos(req: Request, res: Response) {
  const id = req.user!.id;
  const fotos = ficheiros(req, 'fotos');
  if (!fotos.length) throw badRequest('Envie pelo menos uma foto no campo "fotos".');
  const { legenda, pedido_id } = req.valid.body;
  if (pedido_id && !(await Profissional.servicoConcluidoDoProfissional(pedido_id, id))) {
    throw badRequest('Esse pedido não é um serviço seu concluído.');
  }
  const criadas = [];
  for (const f of fotos) {
    const url = await guardarImagem(f, 'trabalhos');
    const fotoId = await Profissional.inserirTrabalho(id, pedido_id ?? null, url, legenda ?? null);
    criadas.push({ id: fotoId, url, legenda: legenda ?? null });
  }
  res.status(201).json(criadas);
}

export async function removerTrabalho(req: Request, res: Response) {
  if (!(await Profissional.apagarTrabalho(req.valid.params.id, req.user!.id))) throw notFound('Foto');
  res.json(null);
}

// ---------------- Perfil público (ecrã 03; RF06, RF07) ----------------

/** Avaliações no formato da app: autor abreviado e etiquetas por chave */
async function avaliacoesDe(profissionalId: number, limit: number, offset = 0) {
  const rows = await Profissional.avaliacoes(profissionalId, limit, offset);
  return rows.map((a) => ({
    id: a.id,
    autor: nomeCurto(a.cliente),
    estrelas: a.estrelas,
    comentario: a.comentario ?? '',
    etiquetas: a.chaves ? String(a.chaves).split(',') : [],
    etiquetas_nomes: a.nomes,
    categoria: a.categoria,
    criado_em: a.criado_em,
  }));
}

export async function perfil(req: Request, res: Response) {
  const { id } = req.valid.params;
  const { lat, lng } = req.valid.query;
  const p = await Profissional.perfil(id);
  if (!p) throw notFound('Profissional');

  const ref = lat !== undefined && lng !== undefined ? { lat, lng } : null;
  const [resumos, categorias, trabalhos, totalTrabalhos, avaliacoes, etiquetas, disponibilidade] = await Promise.all([
    resumosProfissionais([id], ref),
    Profissional.categorias(id),
    Profissional.trabalhos(id),
    Profissional.totalTrabalhos(id),
    avaliacoesDe(id, 10),
    Profissional.etiquetasMaisDadas(id),
    Profissional.horario(id),
  ]);

  res.json({
    ...semCoordenadas(resumos.get(id)),
    bio: p.bio,
    disponivel: !!p.disponivel,
    verificado_em: p.verificado_em,
    media_avaliacao: Number(p.media_avaliacao),
    total_avaliacoes: p.total_avaliacoes,
    total_servicos: p.total_servicos,
    membro_desde: p.membro_desde,
    especialidades: p.especialidades ?? [],
    verificacao: p.verificado ? { selo: 'Verificado', o_que_foi_verificado: EXPLICACAO_VERIFICADO } : null,
    categorias,
    trabalhos_feitos: trabalhos,
    total_trabalhos_feitos: totalTrabalhos,
    avaliacoes,
    avaliacoes_recentes: avaliacoes, // nome antigo, mantido para quem já o usa
    etiquetas_mais_dadas: etiquetas,
    disponibilidade,
    // RF17: texto pronto a partilhar por WhatsApp
    partilha_whatsapp: `https://wa.me/?text=${encodeURIComponent(`Recomendo ${p.nome} na Kisalu Express: ${p.media_avaliacao}★ em ${p.total_avaliacoes} avaliações. kisalu://profissional/${id}`)}`,
  });
}

export async function listarAvaliacoes(req: Request, res: Response) {
  const { limit, offset } = req.valid.query;
  res.json(await avaliacoesDe(req.valid.params.id, limit, offset));
}

/** Estatística das avaliações (ecrã 03, "Avaliações em números"). Ver docs/MATEMATICA.md. */
export async function estatisticas(req: Request, res: Response) {
  const r = await Profissional.distribuicaoAvaliacoes(req.valid.params.id);
  if (!r) throw notFound('Profissional');
  res.json(estatisticasAvaliacoes(r.distribuicao, r.mediaCategoria));
}
