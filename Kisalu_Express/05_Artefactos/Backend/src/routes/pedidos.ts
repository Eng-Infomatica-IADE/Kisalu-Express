/**
 * Rotas dos pedidos: caminho, acesso e schemas Zod (validação + Swagger) de cada endpoint,
 * ligados ao handler do controller. A ordem conta: as rotas literais (/em-curso,
 * /por-confirmar, /proximos) ficam antes de /pedidos/:id.
 */
import { Router } from 'express';
import { z } from 'zod';
import { idParam, paginacao, route } from '../utils/route';
import * as C from '../controllers/pedidosController';

const router = Router();
const TAG = 'Pedidos';

// ---------------- Schemas (mensagens como no catálogo da app, VALIDACOES.md) ----------------

const titulo = z
  .string({ required_error: 'Dê um título curto ao pedido. Exemplo: Fuga de água na cozinha.' })
  .trim()
  .min(3, 'Dê um título curto ao pedido. Exemplo: Fuga de água na cozinha.')
  .max(100, 'O título pode ter até 100 caracteres.')
  .openapi({ example: 'Fuga de água na cozinha' });
const descricao = z
  .string({ required_error: 'Descreva o problema para receber propostas certas.' })
  .trim()
  .min(5, 'Escreva um pouco mais. Exemplo: Cano a pingar debaixo do lava-loiça.')
  .max(2000, 'A descrição pode ter até 2000 caracteres.')
  .openapi({ example: 'Cano a pingar debaixo do lava-loiça.' });
const categoriaChave = z.string().trim().max(30).openapi({ example: 'canalizador' });
const zona = z.string().trim().min(2, 'Diga-nos a zona onde precisa do serviço.').max(80)
  .openapi({ example: 'Talatona', description: 'Usada quando não vem morada_id' });
const pontoReferencia = z.string().trim().max(200, 'O ponto de referência pode ter até 200 caracteres.')
  .openapi({ example: 'perto da cantina do Sr. Zé' });
const quando = z.coerce.date({ invalid_type_error: 'Escolha quando precisa do serviço.' }).nullable()
  .openapi({ description: 'null = o mais cedo possível' });
const urgencia = z.enum(['o_mais_cedo_possivel', 'agendado']);

/**
 * Pedido novo. Aceita o formato da app (categoria_chave, zona, ponto_referencia, quando)
 * e o formato completo (categoria_id, morada_id, urgencia, data_pretendida).
 */
const pedidoNovo = z
  .object({
    categoria_id: z.number().int().positive().optional(),
    categoria_chave: categoriaChave.optional(),
    morada_id: z.number().int().positive().optional(),
    zona: zona.optional(),
    ponto_referencia: pontoReferencia.optional(),
    titulo,
    descricao,
    quando: quando.optional(),
    urgencia: urgencia.optional(),
    data_pretendida: z.coerce.date().nullable().optional(),
    publicar: z.boolean().default(true),
  })
  .superRefine((p, ctx) => {
    if (!p.categoria_id && !p.categoria_chave) {
      ctx.addIssue({ code: 'custom', message: 'Escolha o tipo de serviço.', path: ['categoria_chave'] });
    }
    if (!p.morada_id && !p.zona) ctx.addIssue({ code: 'custom', message: 'Diga-nos a zona onde precisa do serviço.', path: ['zona'] });
    if (p.urgencia === 'agendado' && !p.data_pretendida && !p.quando) {
      ctx.addIssue({ code: 'custom', message: 'Escolha quando precisa do serviço.', path: ['data_pretendida'] });
    }
  });

/** Edição: os mesmos campos do pedido novo, todos opcionais (só muda o que vier) */
const pedidoEdicao = z.object({
  categoria_chave: categoriaChave.optional(),
  categoria_id: z.number().int().positive().optional(),
  titulo: titulo.optional(),
  descricao: descricao.optional(),
  zona: zona.optional(),
  ponto_referencia: pontoReferencia.nullable().optional(),
  quando: quando.optional(),
  morada_id: z.number().int().positive().optional(),
  urgencia: urgencia.optional(),
  data_pretendida: z.coerce.date().nullable().optional(),
});

// ---------------- Criar e listar ----------------

route(
  router,
  {
    method: 'post',
    path: '/pedidos',
    tag: TAG,
    summary: 'Criar pedido de serviço (RF03, ecrã 10)',
    description:
      'Formato da app: {categoria_chave, titulo, descricao, zona, ponto_referencia, quando, publicar}. ' +
      'publicar=false guarda como rascunho (RM03, rede instável). Ao publicar, avisa os profissionais perto. ' +
      'Devolve {id, estado, pedido: PedidoJSON, profissionais_avisados, categoria_plural}.',
    access: ['cliente'],
    body: pedidoNovo,
  },
  C.criar,
);

route(
  router,
  {
    method: 'get',
    path: '/pedidos',
    tag: TAG,
    summary: 'Os meus pedidos: em curso, concluídos, cancelados (RF13, ecrã 07)',
    description:
      'Lista de PedidoJSON (com propostas vazias), mais recentes primeiro. Cliente: os pedidos que publicou. ' +
      'Profissional: os serviços em que a proposta dele foi aceite (com cliente_curto).',
    access: ['cliente', 'profissional'],
    query: paginacao.extend({
      grupo: z.enum(['ativos', 'rascunhos', 'concluidos', 'cancelados']).optional(),
      categoria_id: z.coerce.number().int().optional(),
    }),
  },
  C.listar,
);

route(
  router,
  {
    method: 'get',
    path: '/pedidos/em-curso',
    tag: TAG,
    summary: 'Cliente: serviço à espera de confirmação (ecrãs 05 e 09)',
    description: 'O pedido aceite, a caminho ou em curso mais recente (PedidoJSON), ou null. Para ver todos: /pedidos/em-curso/lista.',
    access: ['cliente'],
  },
  C.emCurso,
);

route(
  router,
  {
    method: 'get',
    path: '/pedidos/em-curso/lista',
    tag: TAG,
    summary: 'Cliente: todos os serviços aceites, a caminho ou em curso',
    description: 'Lista de PedidoJSON, o mais recente primeiro ([] se não houver).',
    access: ['cliente'],
  },
  C.emCursoLista,
);

route(
  router,
  {
    method: 'get',
    path: '/pedidos/por-confirmar',
    tag: TAG,
    summary: 'Profissional: trabalho à espera do código do cliente (ecrã 16)',
    description:
      'Devolve {pedido_id, servico, cliente, valor} do trabalho mais recente, ou null. Com vários serviços ativos, ' +
      'use /pedidos/por-confirmar/lista e confirme com POST /pedidos/confirmar (procura o pedido pelo código).',
    access: ['profissional'],
  },
  C.porConfirmar,
);

route(
  router,
  {
    method: 'get',
    path: '/pedidos/por-confirmar/lista',
    tag: TAG,
    summary: 'Profissional: todos os trabalhos à espera do código do cliente',
    description: 'Lista de {pedido_id, servico, cliente, valor}, o mais recente primeiro ([] se não houver).',
    access: ['profissional'],
  },
  C.porConfirmarLista,
);

route(
  router,
  {
    method: 'get',
    path: '/pedidos/proximos',
    tag: TAG,
    summary: 'Profissional: pedidos abertos perto de si (RF15)',
    description: 'Só mostra bairro e distância; a morada exata só é partilhada depois de aceitar (RNF10).',
    access: ['profissional'],
    query: paginacao,
  },
  C.proximos,
);

// ---------------- Detalhe ----------------

route(
  router,
  {
    method: 'get',
    path: '/pedidos/:id',
    tag: TAG,
    summary: 'Detalhe do pedido: estado, propostas, acordo, chat, comprovativo (RF08)',
    description:
      'PedidoJSON com propostas, mais o detalhe completo (morada, acordo, histórico…). O que se vê depende de quem pede: ' +
      'contactos e morada exata só depois de aceitar (RNF10). O profissional escolhido recebe contacto_cliente ' +
      '{nome, telemovel, morada, ponto_referencia, zona, …}. Para o profissional traz também distancia_km e novo.',
    access: 'auth',
    params: idParam,
  },
  C.detalhe,
);

// ---------------- Desfazer a aceitação (ecrã 08, "Desfazer") ----------------

route(
  router,
  {
    method: 'post',
    path: '/pedidos/:id/desfazer-aceitacao',
    tag: TAG,
    summary: 'Cliente: desfazer a aceitação de uma proposta (ecrã 08)',
    description:
      'Só enquanto o pedido está "aceite" e nos primeiros minutos (DESFAZER_ACEITACAO_MIN, 5 por omissão). ' +
      'As propostas voltam a estar disponíveis e o QR é anulado. Devolve o PedidoJSON.',
    access: ['cliente'],
    params: idParam,
    status: 200,
  },
  C.desfazerAceitacao,
);

// ---------------- Editar, publicar, fotos, cancelar ----------------

route(
  router,
  {
    method: 'patch',
    path: '/pedidos/:id',
    tag: TAG,
    summary: 'Cliente: editar pedido antes de aceitar uma proposta (RF05, ecrã 04)',
    description:
      'Aceita o formato da app, igual ao de POST /pedidos: categoria_chave, titulo, descricao, zona, ponto_referencia, ' +
      'quando (null = o mais cedo possível). Também aceita categoria_id, morada_id, urgencia e data_pretendida. ' +
      'Só muda os campos enviados. 409 PEDIDO_NAO_EDITAVEL se já houver proposta aceite. Devolve o PedidoJSON.',
    access: ['cliente'],
    params: idParam,
    body: pedidoEdicao,
  },
  C.editar,
);

route(
  router,
  { method: 'post', path: '/pedidos/:id/publicar', tag: TAG, summary: 'Publicar um rascunho', access: ['cliente'], params: idParam, status: 200 },
  C.publicar,
);

route(
  router,
  {
    method: 'post',
    path: '/pedidos/:id/fotos',
    tag: TAG,
    summary: 'Juntar fotos ao pedido (opcional, máx. 5) (RM04)',
    access: ['cliente'],
    params: idParam,
    files: { fotos: 5 },
  },
  C.juntarFotos,
);

route(
  router,
  {
    method: 'post',
    path: '/pedidos/:id/cancelar',
    tag: TAG,
    summary: 'Cancelar pedido (RF05)',
    description: 'Possível até o serviço começar. Depois de "em curso", use Reportar problema.',
    access: ['cliente'],
    params: idParam,
    body: z.object({ motivo: z.string().trim().max(255).optional() }),
    status: 200,
  },
  C.cancelar,
);

route(
  router,
  {
    method: 'patch',
    path: '/pedidos/:id/estado',
    tag: TAG,
    summary: 'Profissional: "A caminho" e "Em curso" (RF08)',
    description: '"Concluído" só acontece pela confirmação com QR Code ou código. Devolve {id, estado}.',
    access: ['profissional'],
    params: idParam,
    body: z.object({ estado: z.enum(['a_caminho', 'em_curso']) }),
  },
  C.mudarEstado,
);

route(
  router,
  {
    method: 'post',
    path: '/pedidos/:id/pedir-de-novo',
    tag: TAG,
    summary: '"Pedir de novo": cria um rascunho igual a um pedido anterior (RF13)',
    description: 'Devolve {id, estado: "rascunho", mensagem, pedido: PedidoJSON}. Publica-se com POST /pedidos/:id/publicar.',
    access: ['cliente'],
    params: idParam,
  },
  C.pedirDeNovo,
);

export default router;
