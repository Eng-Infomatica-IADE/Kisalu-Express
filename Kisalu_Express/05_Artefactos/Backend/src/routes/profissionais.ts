/**
 * Rotas dos profissionais: cada route() declara o caminho, quem pode usar, os schemas Zod
 * (validação + Swagger) e o handler do controller. A ordem conta: as rotas literais
 * (/perto, /mapa, /eu/...) ficam antes de /profissionais/:id.
 */
import { Router } from 'express';
import { z } from 'zod';
import { idParam, paginacao, route } from '../utils/route';
import * as C from '../controllers/profissionaisController';

const router = Router();
const TAG = 'Profissionais';

/** Categoria pela chave da app ("canalizador") ou pelo id */
const refCategoria = z.union([z.string().trim().min(2).max(30), z.number().int().positive()]);
const lat = z.coerce.number().min(-90).max(90).optional();
const lng = z.coerce.number().min(-180).max(180).optional();

// =====================================================================
// PESQUISA (RF02)
// =====================================================================

route(
  router,
  {
    method: 'get',
    path: '/profissionais',
    tag: TAG,
    summary: 'Pesquisar profissionais (RF02)',
    description: 'Com lat/lng devolve a distância e filtra pelo raio. Ordenar por distância, avaliação ou serviços.',
    query: paginacao.extend({
      q: z.string().trim().max(60).optional(),
      categoria_id: z.coerce.number().int().optional(),
      categoria_chave: z.string().trim().max(30).optional(),
      lat,
      lng,
      raio_km: z.coerce.number().min(1).max(100).default(15),
      verificado: z.enum(['true', 'false']).optional(),
      ordenar: z.enum(['distancia', 'avaliacao', 'servicos']).default('avaliacao'),
    }),
  },
  C.pesquisar,
);

route(
  router,
  {
    method: 'get',
    path: '/profissionais/perto',
    tag: TAG,
    summary: 'Profissionais perto de si (ecrã 02)',
    description:
      'ProfissionalResumo ordenado pela distância à morada predefinida (ou a lat/lng indicados). ' +
      'Sem morada com GPS, usa Talatona como referência.',
    access: 'auth',
    query: z.object({
      limit: paginacao.shape.limit,
      categoria_chave: z.string().trim().max(30).optional(),
      raio_km: z.coerce.number().min(1).max(100).optional(),
      lat,
      lng,
    }),
  },
  C.perto,
);

route(
  router,
  {
    method: 'get',
    path: '/profissionais/mapa',
    tag: TAG,
    summary: 'Pinos do mapa (ecrã 22)',
    description:
      'Posição de cada profissional disponível num mapa quadrado centrado em si, com raio_km para cada lado. ' +
      'x e y vão de 0 a 1 (0,0 é o canto superior esquerdo).',
    access: 'auth',
    query: z.object({
      raio_km: z.coerce.number().min(1).max(50).default(5),
      categoria_chave: z.string().trim().max(30).optional(),
      lat,
      lng,
    }),
  },
  C.mapa,
);

// =====================================================================
// ÁREA DO PROFISSIONAL (ecrãs 12, 13 e 14; RF07, RF15)
// =====================================================================

route(
  router,
  {
    method: 'get',
    path: '/profissionais/eu/painel',
    tag: TAG,
    summary: 'Início do profissional (ecrã 14)',
    description:
      'Resumo do profissional e os pedidos abertos das suas categorias dentro do raio (PedidoPertoJSON). ' +
      'pedidos_novos conta os que ainda não têm proposta dele e foram publicados há menos de uma hora.',
    access: ['profissional'],
  },
  C.painel,
);

route(
  router,
  {
    method: 'put',
    path: '/profissionais/eu',
    tag: TAG,
    summary: 'Registo profissional e disponibilidade (ecrãs 12 e 14)',
    description:
      'Cria o perfil profissional se ainda não existir e atualiza só os campos enviados. categorias aceita as chaves da app ' +
      '(ou ids). Também serve para o interruptor "Disponível para trabalhar" ({disponivel}). A sessão passa a profissional.',
    access: 'auth',
    body: z.object({
      nome_completo: z.string().trim().min(2, 'Escreva o seu nome completo.').max(100).optional(),
      // Limites iguais aos da app (ecrã 12): até 13 serviços, 0–60 anos, raio de 1 a 30 km.
      categorias: z.array(refCategoria).min(1, 'Escolha pelo menos um serviço.').max(13).optional()
        .openapi({ example: ['canalizador', 'pedreiro'] }),
      anos_experiencia: z.number().int().min(0).max(60, 'Escreva um valor até 60 anos.').nullable().optional(),
      zona: z.string().trim().min(2, 'Diga-nos a sua zona de atuação.').max(80).optional().openapi({ example: 'Viana, Luanda' }),
      raio_atuacao_km: z.number().int().min(1).max(30).optional(),
      disponivel: z.boolean().optional(),
      bio: z.string().trim().max(500).nullable().optional(),
      latitude: z.number().min(-90).max(90).nullable().optional(),
      longitude: z.number().min(-180).max(180).nullable().optional(),
      mao_obra_desde: z.number().int().min(0).max(10_000_000).nullable().optional(),
      especialidades: z.array(z.string().trim().min(2).max(60)).max(10).optional(),
    }),
    status: 200,
  },
  C.guardarRegisto,
);

route(
  router,
  {
    method: 'put',
    path: '/profissionais/eu/disponibilidade',
    tag: TAG,
    summary: 'Definir o horário semanal (RF15)',
    access: ['profissional'],
    body: z.object({
      horarios: z
        .array(
          z
            .object({
              dia_semana: z.number().int().min(1).max(7).openapi({ description: '1 = segunda … 7 = domingo' }),
              hora_inicio: z.string().regex(/^\d{2}:\d{2}$/, 'Escreva a hora como 08:00.'),
              hora_fim: z.string().regex(/^\d{2}:\d{2}$/, 'Escreva a hora como 18:00.'),
            })
            .refine((h) => h.hora_fim > h.hora_inicio, 'A hora de fim tem de ser depois da hora de início.'),
        )
        .max(21),
    }),
    status: 200,
  },
  C.definirHorario,
);

// ---------------- Verificação de identidade (ecrã 13, RF07) ----------------

route(
  router,
  {
    method: 'get',
    path: '/profissionais/eu/verificacao',
    tag: TAG,
    summary: 'Estado da minha verificação (ecrã 13)',
    description: 'estado: nao_pedida, rascunho, pendente, aprovada ou rejeitada.',
    access: ['profissional'],
  },
  C.verificacao,
);

route(
  router,
  {
    method: 'put',
    path: '/profissionais/eu/verificacao/documento',
    tag: TAG,
    summary: 'Juntar a foto do documento de identidade (ecrã 13)',
    description:
      'Multipart com o campo "documento". A imagem fica fora de /uploads (só o admin a vê). ' +
      'Fora de produção, sem ficheiro, regista uma captura simulada.',
    access: ['profissional'],
    files: { documento: 1 },
    body: z.object({
      tipo_documento: z.enum(['bilhete_identidade', 'passaporte', 'cartao_residente']).default('bilhete_identidade'),
      numero_documento: z.string().trim().min(5).max(30).optional(),
    }),
    status: 200,
  },
  C.juntarDocumento,
);

route(
  router,
  {
    method: 'put',
    path: '/profissionais/eu/verificacao/rosto',
    tag: TAG,
    summary: 'Juntar a fotografia do rosto (ecrã 13)',
    description: 'Multipart com o campo "rosto". Fica fora de /uploads. Fora de produção, sem ficheiro, regista uma captura simulada.',
    access: ['profissional'],
    files: { rosto: 1 },
    status: 200,
  },
  C.juntarRosto,
);

route(
  router,
  {
    method: 'post',
    path: '/profissionais/eu/verificacao/enviar',
    tag: TAG,
    summary: 'Enviar para verificação (ecrã 13)',
    description: 'Precisa do documento e do rosto. A análise demora até 48 horas.',
    access: ['profissional'],
    status: 200,
  },
  C.enviarVerificacao,
);

route(
  router,
  {
    method: 'post',
    path: '/profissionais/eu/verificacao',
    tag: TAG,
    summary: 'Pedir o selo Verificado de uma só vez: documento + fotografia (RF07)',
    description: 'Alternativa aos três passos do ecrã 13: envia os dois ficheiros e fica logo em análise.',
    access: ['profissional'],
    files: { documento: 1, selfie: 1 },
    body: z.object({
      tipo_documento: z.enum(['bilhete_identidade', 'passaporte', 'cartao_residente']),
      numero_documento: z.string().trim().min(5).max(30),
    }),
  },
  C.pedirSelo,
);

// ---------------- Galeria de trabalhos (RF06) ----------------

route(
  router,
  {
    method: 'post',
    path: '/profissionais/eu/trabalhos',
    tag: TAG,
    summary: 'Adicionar fotos à galeria "Trabalhos feitos" (RF06)',
    description: 'pedido_id é opcional; quando indicado, tem de ser um serviço seu já confirmado por QR.',
    access: ['profissional'],
    files: { fotos: 5 },
    body: z.object({
      legenda: z.string().trim().max(150).optional(),
      pedido_id: z.coerce.number().int().positive().optional(),
    }),
  },
  C.adicionarTrabalhos,
);

route(
  router,
  { method: 'delete', path: '/profissionais/eu/trabalhos/:id', tag: TAG, summary: 'Remover foto da galeria', access: ['profissional'], params: idParam, status: 200 },
  C.removerTrabalho,
);

// =====================================================================
// PERFIL PÚBLICO (ecrã 03; RF06, RF07). Fica depois das rotas literais.
// =====================================================================

route(
  router,
  {
    method: 'get',
    path: '/profissionais/:id',
    tag: TAG,
    summary: 'Perfil do profissional com trabalhos feitos (RF06)',
    description: 'ProfissionalDetalhe: o ProfissionalResumo com especialidades, trabalhos e avaliações. Com lat/lng traz a distância.',
    params: idParam,
    query: z.object({ lat, lng }),
  },
  C.perfil,
);

route(
  router,
  {
    method: 'get',
    path: '/profissionais/:id/avaliacoes',
    tag: TAG,
    summary: 'Todas as avaliações de um profissional',
    params: idParam,
    query: paginacao,
  },
  C.listarAvaliacoes,
);

export default router;
