import { Router } from 'express';
import { z } from 'zod';
import { env } from '../config/env';
import { execute, query, queryOne, transaction } from '../config/db';
import { badRequest, conflict, forbidden, notFound, tooMany } from '../utils/errors';
import { idParam, kz, route } from '../utils/route';
import { codigo6, tokenQr } from '../utils/crypto';
import { ficheiros, guardarImagemPrivada } from '../middlewares/upload';
import { notificar } from '../services/notificacoes';
import { codigoServico } from '../utils/validacoes';
import { confirmarPorCodigo, confirmarPorId, MAX_TENTATIVAS_CODIGO } from '../controllers/confirmacaoController';
import { registarAbertura } from '../models/confirmacaoModel';
import * as Conversa from '../models/conversaModel';
import * as Utilizador from '../models/utilizadorModel';
import { carregarPedido, ESTADOS_ABERTOS, ESTADOS_ATIVOS, exigirPapel, papelNoPedido } from '../services/pedidos';
import {
  CAMPOS_PROPOSTA, comprovativoJSON, fmtKz, kz as kzInteiro, propostaJSON, propostaPorId, resumoProfissional, resumosProfissionais,
} from '../services/formatos';

const router = Router();
const TAG_P = 'Propostas';
const TAG_Q = 'Confirmação por QR e comprovativo';
const TAG_R = 'Garantia e avaliação';

/** Valor mínimo de uma proposta (ecrã 15) */
const VALOR_MINIMO_KZ = 500;

/** Código alternativo ao QR: fixo em demonstração (CODIGO_QR_FIXO_DEV), aleatório nos outros casos */
const novoCodigoServico = () => env.codigoQrFixoDev ?? codigo6();

// =====================================================================
// PROPOSTAS (RF04, RF05, RF15)
// =====================================================================

const propostaCampos = z.object({
  valor_mao_obra: kz.openapi({ example: 8000 }),
  valor_material: kz.default(0).openapi({ example: 3500 }),
  valor_deslocacao: kz.default(0).openapi({ example: 1000 }),
  material_detalhe: z.string().trim().max(150).optional().openapi({ example: 'sifão e vedante' }),
  inclui_descricao: z.string().trim().max(300).optional().openapi({ description: 'Se vazio, é gerado a partir das componentes' }),
  tempo_chegada_min: z.number().int().min(5).max(24 * 60).optional().openapi({ example: 40 }),
  na_hora_pedida: z.boolean().default(false).openapi({ description: 'Chega à hora que o cliente pediu (em vez de tempo_chegada_min)' }),
  mensagem: z.string().trim().max(500).optional(),
});
const propostaBody = propostaCampos.superRefine((b, ctx) => {
  if (!b.na_hora_pedida && b.tempo_chegada_min === undefined) {
    ctx.addIssue({ code: 'custom', message: 'Indique quando chega ou escolha "na hora pedida"', path: ['tempo_chegada_min'] });
  }
});

function validarValorMinimo(b: { valor_mao_obra: number; valor_material: number; valor_deslocacao: number }) {
  if (Number(b.valor_mao_obra) + Number(b.valor_material) + Number(b.valor_deslocacao) < VALOR_MINIMO_KZ) {
    throw badRequest(`O valor fechado tem de ser pelo menos ${fmtKz(VALOR_MINIMO_KZ)}.`, 'VALOR_MINIMO');
  }
}

function descreverInclui(b: { valor_mao_obra: number; valor_material: number; valor_deslocacao: number }) {
  return [b.valor_mao_obra > 0 && 'Mão de obra', b.valor_material > 0 && 'material', b.valor_deslocacao > 0 && 'deslocação'].filter(Boolean).join(' · ');
}

route(
  router,
  {
    method: 'post',
    path: '/pedidos/:id/propostas',
    tag: TAG_P,
    summary: 'Profissional: enviar proposta com preço fechado (RF15, ecrã 15)',
    description:
      'Preço por componentes; o total é calculado pela base de dados e tem de ser pelo menos 500 Kz. ' +
      'Chegada: tempo_chegada_min ou na_hora_pedida (só em pedidos com hora marcada). Uma proposta por profissional e pedido. ' +
      'Devolve a PropostaJSON.',
    access: ['profissional'],
    params: idParam,
    body: propostaBody,
  },
  async (req, res) => {
    const b = req.valid.body;
    validarValorMinimo(b);
    const out = await transaction(async (conn) => {
      const p = await carregarPedido(req.valid.params.id, conn, true);
      if (!ESTADOS_ABERTOS.includes(p.estado)) throw conflict('Este pedido já não aceita propostas.');
      if (p.cliente_id === req.user!.id) throw forbidden();
      const temCategoria = await queryOne(`SELECT 1 ok FROM profissional_categoria WHERE profissional_id = ? AND categoria_id = ?`, [req.user!.id, p.categoria_id], conn);
      if (!temCategoria) throw forbidden('Este pedido não é da sua categoria.');
      if (b.na_hora_pedida) {
        const hora = await queryOne(`SELECT data_pretendida FROM pedido WHERE id = ?`, [p.id], conn);
        if (!hora.data_pretendida) throw badRequest('Este pedido não tem hora marcada. Indique quando chega.', 'SEM_HORA_PEDIDA');
      }

      const r = await execute(
        `INSERT INTO proposta (pedido_id, profissional_id, valor_mao_obra, valor_material, valor_deslocacao, inclui_descricao,
                               material_detalhe, tempo_chegada_min, na_hora_pedida, mensagem)
         VALUES (?,?,?,?,?,?,?,?,?,?)`,
        [p.id, req.user!.id, b.valor_mao_obra, b.valor_material, b.valor_deslocacao, b.inclui_descricao || descreverInclui(b),
          b.material_detalhe ?? null, b.na_hora_pedida ? null : b.tempo_chegada_min, b.na_hora_pedida, b.mensagem ?? null],
        conn,
      );
      if (p.estado === 'publicado') await execute(`UPDATE pedido SET estado = 'com_propostas' WHERE id = ?`, [p.id], conn);

      const total = await queryOne<{ n: number }>(`SELECT COUNT(*) n FROM proposta WHERE pedido_id = ? AND estado = 'enviada'`, [p.id], conn);
      await notificar(
        p.cliente_id,
        { tipo: 'nova_proposta', titulo: `Recebeu ${total!.n} proposta${total!.n > 1 ? 's' : ''}`, corpo: 'Compare preço, chegada e avaliações.', pedido_id: p.id, acao: 'ver_propostas' },
        conn,
      );
      return propostaPorId(r.insertId, conn);
    });
    res.status(201).json(out);
  },
);

route(
  router,
  {
    method: 'get',
    path: '/pedidos/:id/propostas',
    tag: TAG_P,
    summary: 'Cliente: comparar propostas (RF04)',
    description: 'Lista de PropostaJSON: preço em Kz por componentes, chegada prevista, estrelas e selo Verificado.',
    access: ['cliente'],
    params: idParam,
    query: z.object({ ordenar: z.enum(['preco', 'avaliacao', 'chegada']).default('preco') }),
  },
  async (req, res) => {
    const p = await carregarPedido(req.valid.params.id);
    if (p.cliente_id !== req.user!.id) throw notFound('Pedido');
    const pe = await queryOne(
      `SELECT pe.data_pretendida, m.latitude, m.longitude FROM pedido pe JOIN morada m ON m.id = pe.morada_id WHERE pe.id = ?`,
      [p.id],
    );
    const rows = await query(`SELECT ${CAMPOS_PROPOSTA} FROM proposta pr WHERE pr.pedido_id = ? AND pr.estado IN ('enviada','aceite')`, [p.id]);
    const ref = pe.latitude !== null ? { lat: Number(pe.latitude), lng: Number(pe.longitude) } : null;
    const resumos = await resumosProfissionais(rows.map((r) => r.profissional_id), ref);
    const lista = rows.map((r) => {
      const { latitude: _la, longitude: _lo, ...prof } = resumos.get(r.profissional_id)!;
      return { ...propostaJSON(r, pe.data_pretendida, prof, true), valor_formatado: fmtKz(r.valor_total) };
    });
    const quando = (x: any) => (x.chegada_prevista ? new Date(x.chegada_prevista).getTime() : Infinity);
    const ordem = {
      preco: (a: any, b: any) => a.valor_total - b.valor_total,
      avaliacao: (a: any, b: any) => b.profissional.rating - a.profissional.rating || b.profissional.num_avaliacoes - a.profissional.num_avaliacoes,
      chegada: (a: any, b: any) => quando(a) - quando(b),
    }[req.valid.query.ordenar as 'preco'];
    res.json(lista.sort(ordem));
  },
);

route(
  router,
  {
    method: 'patch',
    path: '/propostas/:id',
    tag: TAG_P,
    summary: 'Profissional: corrigir a proposta antes de ser aceite',
    access: ['profissional'],
    params: idParam,
    body: propostaCampos.partial(),
  },
  async (req, res) => {
    const pr = await queryOne(`SELECT * FROM proposta WHERE id = ? AND profissional_id = ?`, [req.valid.params.id, req.user!.id]);
    if (!pr) throw notFound('Proposta');
    if (pr.estado !== 'enviada') throw conflict('Só pode alterar propostas ainda não respondidas.');
    const enviados: Record<string, unknown> = Object.fromEntries(Object.entries(req.valid.body).filter(([, v]) => v !== undefined));
    // Os valores por omissão do Zod (0, false) só contam se o campo veio mesmo no corpo
    for (const k of ['valor_material', 'valor_deslocacao', 'na_hora_pedida']) if (!(k in (req.body ?? {}))) delete enviados[k];
    const novo = { ...pr, ...enviados };
    validarValorMinimo(novo);
    if (!novo.na_hora_pedida && !novo.tempo_chegada_min) throw badRequest('Indique quando chega ou escolha "na hora pedida".');
    await execute(
      `UPDATE proposta SET valor_mao_obra=?, valor_material=?, valor_deslocacao=?, inclui_descricao=?, material_detalhe=?,
              tempo_chegada_min=?, na_hora_pedida=?, mensagem=? WHERE id = ?`,
      [novo.valor_mao_obra, novo.valor_material, novo.valor_deslocacao, req.valid.body.inclui_descricao ?? descreverInclui(novo),
        novo.material_detalhe, novo.na_hora_pedida ? null : novo.tempo_chegada_min, !!novo.na_hora_pedida, novo.mensagem, pr.id],
    );
    res.json(await propostaPorId(pr.id));
  },
);

route(
  router,
  { method: 'post', path: '/propostas/:id/retirar', tag: TAG_P, summary: 'Profissional: retirar proposta', access: ['profissional'], params: idParam, status: 200 },
  async (req, res) => {
    const r = await execute(`UPDATE proposta SET estado = 'retirada', respondida_em = NOW() WHERE id = ? AND profissional_id = ? AND estado = 'enviada'`, [req.valid.params.id, req.user!.id]);
    if (!r.affectedRows) throw conflict('A proposta não existe ou já foi respondida.');
    res.json({ id: req.valid.params.id, estado: 'retirada' });
  },
);

route(
  router,
  { method: 'post', path: '/propostas/:id/recusar', tag: TAG_P, summary: 'Cliente: recusar proposta (RF05)', access: ['cliente'], params: idParam, status: 200 },
  async (req, res) => {
    const r = await execute(
      `UPDATE proposta pr JOIN pedido pe ON pe.id = pr.pedido_id SET pr.estado = 'recusada', pr.respondida_em = NOW()
        WHERE pr.id = ? AND pe.cliente_id = ? AND pr.estado = 'enviada'`,
      [req.valid.params.id, req.user!.id],
    );
    if (!r.affectedRows) throw conflict('A proposta não existe ou já foi respondida.');
    res.json({ id: req.valid.params.id, estado: 'recusada' });
  },
);

route(
  router,
  {
    method: 'post',
    path: '/propostas/:id/aceitar',
    tag: TAG_P,
    summary: 'Cliente: aceitar proposta e fechar o acordo (RF05)',
    description:
      'Numa só transação: aceita esta proposta, recusa as outras, passa o pedido a "aceite", gera o QR Code + código numérico ' +
      'com o valor acordado e abre o chat. Devolve o resumo do acordo.',
    access: ['cliente'],
    params: idParam,
    status: 200,
  },
  async (req, res) => {
    const acordo = await transaction(async (conn) => {
      const pr = await queryOne(`SELECT * FROM proposta WHERE id = ? FOR UPDATE`, [req.valid.params.id], conn);
      if (!pr) throw notFound('Proposta');
      const p = await carregarPedido(pr.pedido_id, conn, true);
      if (p.cliente_id !== req.user!.id) throw notFound('Proposta');
      if (!ESTADOS_ABERTOS.includes(p.estado)) throw conflict('Este pedido já tem uma proposta aceite ou foi fechado.');
      if (pr.estado !== 'enviada') throw conflict('Esta proposta já não está disponível.');

      await execute(`UPDATE proposta SET estado = 'aceite', respondida_em = NOW() WHERE id = ?`, [pr.id], conn);
      const recusadas = await query<{ profissional_id: number }>(`SELECT profissional_id FROM proposta WHERE pedido_id = ? AND id <> ? AND estado = 'enviada'`, [p.id, pr.id], conn);
      await execute(`UPDATE proposta SET estado = 'recusada', respondida_em = NOW() WHERE pedido_id = ? AND id <> ? AND estado = 'enviada'`, [p.id, pr.id], conn);
      await execute(`UPDATE pedido SET estado = 'aceite', proposta_aceite_id = ? WHERE id = ?`, [pr.id, p.id], conn);
      await execute(`UPDATE historico_estado_pedido SET alterado_por = ? WHERE pedido_id = ? ORDER BY id DESC LIMIT 1`, [req.user!.id, p.id], conn);
      await execute(
        `INSERT INTO confirmacao_servico (pedido_id, token_qr, codigo_numerico, valor_acordado, expira_em)
         VALUES (?,?,?,?, NOW() + INTERVAL ? MINUTE)`,
        [p.id, tokenQr(), novoCodigoServico(), pr.valor_total, env.qrValidadeMin],
        conn,
      );
      await Conversa.abrirConversa(p.id, pr.profissional_id, conn);

      await notificar(pr.profissional_id, { tipo: 'proposta_aceite', titulo: 'Proposta aceite!', corpo: `Valor combinado: ${fmtKz(pr.valor_total)}. Veja a morada no pedido.`, pedido_id: p.id, acao: 'ver_pedido' }, conn);
      for (const r of recusadas) {
        await notificar(r.profissional_id, { tipo: 'estado_pedido', titulo: 'Proposta não escolhida', corpo: 'O cliente escolheu outra proposta.', pedido_id: p.id }, conn);
      }

      return queryOne(
        `SELECT pe.id AS pedido_id, pe.titulo, u.nome AS profissional, u.telemovel AS profissional_telemovel, pr.valor_total AS valor_acordado,
                pr.inclui_descricao AS inclui,
                IF(pr.na_hora_pedida, pe.data_pretendida, DATE_ADD(NOW(), INTERVAL pr.tempo_chegada_min MINUTE)) AS hora_prevista_chegada,
                (SELECT id FROM conversa c WHERE c.pedido_id = pe.id AND c.profissional_id = pr.profissional_id) AS conversa_id
           FROM proposta pr JOIN pedido pe ON pe.id = pr.pedido_id JOIN utilizador u ON u.id = pr.profissional_id
          WHERE pr.id = ?`,
        [pr.id],
        conn,
      );
    });
    res.json({
      ...acordo,
      valor_acordado: kzInteiro(acordo.valor_acordado),
      valor_formatado: fmtKz(acordo.valor_acordado),
      mensagem: 'Acordo fechado. O preço só muda se aprovar uma alteração na app.',
    });
  },
);

// ---------------- Alteração de preço só com aprovação (RF08, O4) ----------------

route(
  router,
  {
    method: 'post',
    path: '/pedidos/:id/alteracoes-preco',
    tag: TAG_P,
    summary: 'Profissional: pedir alteração do preço combinado',
    description: 'O valor só muda se o cliente aprovar. Enquanto houver um pedido pendente, não é possível confirmar o serviço.',
    access: ['profissional'],
    params: idParam,
    body: z.object({ valor_novo: kz.positive(), motivo: z.string().trim().min(5).max(300) }),
  },
  async (req, res) => {
    const out = await transaction(async (conn) => {
      const p = await carregarPedido(req.valid.params.id, conn, true);
      if (p.profissional_aceite_id !== req.user!.id) throw forbidden('Só o profissional escolhido pode pedir alterações.');
      if (!ESTADOS_ATIVOS.includes(p.estado)) throw conflict('O preço já não pode ser alterado.');
      const pendente = await queryOne(`SELECT id FROM alteracao_preco WHERE proposta_id = ? AND estado = 'pendente'`, [p.proposta_aceite_id], conn);
      if (pendente) throw conflict('Já existe uma alteração à espera de resposta.');
      const cs = await queryOne(`SELECT valor_acordado FROM confirmacao_servico WHERE pedido_id = ?`, [p.id], conn);
      if (Number(cs.valor_acordado) === req.valid.body.valor_novo) throw badRequest('O valor novo é igual ao combinado.');
      const r = await execute(
        `INSERT INTO alteracao_preco (proposta_id, valor_anterior, valor_novo, motivo) VALUES (?,?,?,?)`,
        [p.proposta_aceite_id, cs.valor_acordado, req.valid.body.valor_novo, req.valid.body.motivo],
        conn,
      );
      await notificar(
        p.cliente_id,
        { tipo: 'alteracao_preco', titulo: 'Pedido de alteração de preço', corpo: `${fmtKz(cs.valor_acordado)} → ${fmtKz(req.valid.body.valor_novo)}. Aprove ou recuse na app.`, pedido_id: p.id, acao: 'ver_alteracao' },
        conn,
      );
      return { id: r.insertId, valor_anterior: cs.valor_acordado, valor_novo: req.valid.body.valor_novo, estado: 'pendente' };
    });
    res.status(201).json(out);
  },
);

route(
  router,
  {
    method: 'post',
    path: '/alteracoes-preco/:id/responder',
    tag: TAG_P,
    summary: 'Cliente: aprovar ou recusar a alteração de preço',
    access: ['cliente'],
    params: idParam,
    body: z.object({ aprovar: z.boolean() }),
    status: 200,
  },
  async (req, res) => {
    const out = await transaction(async (conn) => {
      const alt = await queryOne(
        `SELECT a.*, pr.pedido_id, pr.profissional_id, pe.cliente_id
           FROM alteracao_preco a JOIN proposta pr ON pr.id = a.proposta_id JOIN pedido pe ON pe.id = pr.pedido_id
          WHERE a.id = ? FOR UPDATE`,
        [req.valid.params.id],
        conn,
      );
      if (!alt || alt.cliente_id !== req.user!.id) throw notFound('Alteração');
      if (alt.estado !== 'pendente') throw conflict('Esta alteração já foi respondida.');
      const estado = req.valid.body.aprovar ? 'aprovada' : 'recusada';
      await execute(`UPDATE alteracao_preco SET estado = ?, respondida_em = NOW() WHERE id = ?`, [estado, alt.id], conn);
      if (req.valid.body.aprovar) {
        await execute(`UPDATE confirmacao_servico SET valor_acordado = ? WHERE pedido_id = ? AND estado = 'pendente'`, [alt.valor_novo, alt.pedido_id], conn);
      }
      await notificar(
        alt.profissional_id,
        { tipo: 'alteracao_preco', titulo: `Alteração ${estado}`, corpo: req.valid.body.aprovar ? `Novo valor: ${fmtKz(alt.valor_novo)}.` : `Mantém-se ${fmtKz(alt.valor_anterior)}.`, pedido_id: alt.pedido_id },
        conn,
      );
      return { id: alt.id, estado, valor_acordado: req.valid.body.aprovar ? alt.valor_novo : alt.valor_anterior };
    });
    res.json(out);
  },
);

// =====================================================================
// CONFIRMAÇÃO POR QR CODE + COMPROVATIVO (RF10, RF14)
// =====================================================================

route(
  router,
  {
    method: 'get',
    path: '/pedidos/:id/qr',
    tag: TAG_Q,
    summary: 'Cliente: QR Code e código numérico do serviço em curso (ecrã 05)',
    description:
      'token é o texto a desenhar no QR: opaco, sem o id do pedido nem o código. Vale QR_VALIDADE_MIN minutos (10 por omissão) ' +
      'e renova-se ao abrir de novo. Depois de 5 códigos errados, abrir o ecrã gera um código novo. Mostrar só com o trabalho feito.',
    access: ['cliente'],
    params: idParam,
  },
  async (req, res) => {
    const p = await carregarPedido(req.valid.params.id);
    if (p.cliente_id !== req.user!.id) throw notFound('Pedido');
    if (!ESTADOS_ATIVOS.includes(p.estado)) throw conflict('Este pedido não tem um serviço por confirmar.');

    const cs = await queryOne(
      `SELECT id, tentativas, expira_em IS NULL OR expira_em <= NOW() AS expirado
         FROM confirmacao_servico WHERE pedido_id = ? AND estado = 'pendente'`,
      [p.id],
    );
    if (!cs) throw notFound('Confirmação');
    // Fica registado quando o cliente abriu o QR: desempata códigos iguais em POST /pedidos/confirmar
    await registarAbertura(cs.id);
    const bloqueado = cs.tentativas >= MAX_TENTATIVAS_CODIGO;
    if (cs.expirado || bloqueado) {
      await execute(
        `UPDATE confirmacao_servico
            SET token_qr = ?, expira_em = NOW() + INTERVAL ? MINUTE
                ${bloqueado ? ', codigo_numerico = ?, tentativas = 0' : ''}
          WHERE id = ?`,
        [tokenQr(), env.qrValidadeMin, ...(bloqueado ? [novoCodigoServico()] : []), cs.id],
      );
    }

    const q = await queryOne(
      `SELECT cs.token_qr, cs.codigo_numerico, cs.valor_acordado, cs.expira_em, c.nome AS categoria, c.chave AS categoria_chave,
              pr.profissional_id
         FROM confirmacao_servico cs JOIN pedido pe ON pe.id = cs.pedido_id JOIN categoria c ON c.id = pe.categoria_id
         JOIN proposta pr ON pr.id = pe.proposta_aceite_id
        WHERE cs.id = ?`,
      [cs.id],
    );
    const valor = kzInteiro(q.valor_acordado);
    res.json({
      pedido_id: p.id,
      token: q.token_qr,
      codigo: q.codigo_numerico,
      valido_ate: q.expira_em,
      valor_acordado: valor,
      profissional: await resumoProfissional(q.profissional_id),
      categoria: q.categoria,
      categoria_chave: q.categoria_chave,
      codigo_formatado: `${q.codigo_numerico.slice(0, 3)} ${q.codigo_numerico.slice(3)}`,
      valor_formatado: fmtKz(valor),
      // RNF09: rótulo para leitores de ecrã
      rotulo_acessivel: `Código QR para confirmar serviço de ${fmtKz(valor)}`,
      instrucoes: ['O profissional lê o código', 'Confirma o valor combinado', 'Avalie o serviço e a experiência'],
    });
  },
);

const metodoPagamento = z.enum(['dinheiro', 'multicaixa_express', 'transferencia']).default('dinheiro').openapi({ description: 'RF14' });

route(
  router,
  {
    method: 'post',
    path: '/pedidos/confirmar',
    tag: TAG_Q,
    summary: 'Profissional: confirmar o serviço só com o código (ou o QR), sem indicar o pedido (RF10, ecrã 16)',
    description:
      'Envie codigo (6 dígitos, aceita "482 173") ou token_qr (lido do QR). A API procura, entre os serviços ativos com a ' +
      'proposta deste profissional aceite e a confirmação pendente, aquele cujo código ou QR corresponde, e confirma esse. ' +
      'Código errado conta uma tentativa em todos os serviços pendentes dele; com 5 erros fica bloqueado (429) até o cliente ' +
      'abrir de novo o QR. Se, em desenvolvimento (CODIGO_QR_FIXO_DEV), vários serviços tiverem o mesmo código, confirma o ' +
      'que o cliente abriu (ou renovou) no ecrã do QR mais recentemente. Sem serviços por confirmar: 404 SEM_SERVICO_POR_CONFIRMAR. ' +
      'Devolve o ComprovativoJSON, como POST /pedidos/:id/confirmar.',
    access: ['profissional'],
    body: z
      .object({
        codigo: codigoServico.optional(),
        token_qr: z.string().trim().min(10, 'Não conseguimos ler este QR. Peça o código numérico ao cliente.').max(64).optional()
          .openapi({ description: 'Conteúdo lido do QR (kx_qr_…)' }),
        metodo_pagamento: metodoPagamento,
      })
      .refine((b) => b.token_qr || b.codigo, { message: 'Escreva o código que o cliente lhe disse.', path: ['codigo'] }),
    status: 200,
  },
  confirmarPorCodigo,
);

route(
  router,
  {
    method: 'post',
    path: '/pedidos/:id/confirmar',
    tag: TAG_Q,
    summary: 'Profissional: confirmar o serviço lendo o QR ou com o código numérico (RF10, ecrã 16)',
    description:
      'Envie token (lido do QR) ou codigo (os 6 dígitos ditos pelo cliente). Cada código errado conta; à quinta tentativa fica ' +
      'bloqueado (429) até o cliente abrir de novo o QR. Fecha o pedido pelo valor acordado (O4) e devolve o ComprovativoJSON. ' +
      'Com vários serviços ativos, prefira POST /pedidos/confirmar, que encontra o pedido pelo código.',
    access: ['profissional'],
    params: idParam,
    body: z
      .object({
        token: z.string().trim().min(10, 'Não conseguimos ler este QR. Peça o código numérico ao cliente.').max(64).optional()
          .openapi({ description: 'Conteúdo lido do QR' }),
        codigo: codigoServico.optional(),
        metodo_pagamento: metodoPagamento,
      })
      .refine((b) => b.token || b.codigo, { message: 'Escreva o código que o cliente lhe disse.', path: ['codigo'] }),
    status: 200,
  },
  confirmarPorId,
);

route(
  router,
  {
    method: 'get',
    path: '/pedidos/:id/comprovativo',
    tag: TAG_Q,
    summary: 'Comprovativo digital: valor, data e profissional (RF10, RF17)',
    description: 'ComprovativoJSON, para o cliente, o profissional escolhido ou o admin.',
    access: 'auth',
    params: idParam,
  },
  async (req, res) => {
    const p = await carregarPedido(req.valid.params.id);
    const papel = await papelNoPedido(p, req.user);
    exigirPapel(papel, 'cliente', 'profissional_aceite', 'admin');
    const c = await comprovativoJSON(p.id);
    if (!c) throw notFound('Comprovativo');
    res.json(c);
  },
);

// =====================================================================
// REPORTAR PROBLEMA / GARANTIA DE 7 DIAS (RF11)
// =====================================================================

route(
  router,
  {
    method: 'post',
    path: '/pedidos/:id/reclamacoes',
    tag: TAG_R,
    summary: 'Reportar problema (antes de confirmar ou até 7 dias depois) (RF11)',
    description: 'O prazo de 7 dias é garantido por um trigger na base de dados (422 se passou).',
    access: ['cliente', 'profissional'],
    params: idParam,
    files: { foto: 1 },
    body: z.object({
      tipo: z.enum(['trabalho_mal_feito', 'preco_diferente', 'nao_compareceu', 'atraso', 'comportamento', 'outro']),
      descricao: z.string({ required_error: 'Conte-nos o que aconteceu.' }).trim()
        .min(10, 'Escreva um pouco mais para percebermos o problema.').max(2000, 'A descrição pode ter até 2000 caracteres.'),
    }),
  },
  async (req, res) => {
    const p = await carregarPedido(req.valid.params.id);
    const papel = await papelNoPedido(p, req.user);
    exigirPapel(papel, 'cliente', 'profissional_aceite');
    const [foto] = ficheiros(req, 'foto');
    // A foto fica fora de /uploads: só a equipa (admin) a vê
    const fotoUrl = foto ? await guardarImagemPrivada(foto, 'reclamacoes') : null;

    const r = await execute(
      `INSERT INTO reclamacao (pedido_id, autor_id, tipo, descricao, foto_url) VALUES (?,?,?,?,?)`,
      [p.id, req.user!.id, req.valid.body.tipo, req.valid.body.descricao, fotoUrl],
    );
    const outro = papel === 'cliente' ? p.profissional_aceite_id : p.cliente_id;
    if (outro) await notificar(outro, { tipo: 'reclamacao', titulo: 'Foi reportado um problema', corpo: 'A equipa Kisalu vai acompanhar. Veja os detalhes no pedido.', pedido_id: p.id });

    const contacto = await Utilizador.contactoDoAutorDaProposta(p.proposta_aceite_id);
    res.status(201).json({
      id: r.insertId,
      estado: 'aberta',
      mensagem: 'Recebemos o seu problema. Respondemos em até 48 horas.',
      ...(papel === 'cliente' && contacto ? { contacto_profissional: contacto } : {}),
    });
  },
);

route(
  router,
  { method: 'get', path: '/reclamacoes', tag: TAG_R, summary: 'As minhas reclamações', access: 'auth' },
  async (req, res) => {
    const rows = await query(
      `SELECT r.id, r.pedido_id, pe.titulo, r.tipo, r.descricao, r.foto_url IS NOT NULL AS tem_foto, r.estado, r.resolucao, r.criado_em, r.resolvida_em
         FROM reclamacao r JOIN pedido pe ON pe.id = r.pedido_id WHERE r.autor_id = ? ORDER BY r.criado_em DESC`,
      [req.user!.id],
    );
    res.json(rows.map((r) => ({ ...r, tem_foto: !!r.tem_foto })));
  },
);

// =====================================================================
// AVALIAÇÃO (RF12)
// =====================================================================

route(
  router,
  {
    method: 'post',
    path: '/pedidos/:id/avaliacao',
    tag: TAG_R,
    summary: 'Avaliar com estrelas, etiquetas e comentário (RF12)',
    description:
      'Só para serviços confirmados por QR (trigger trg_avaliacao_valida). Uma avaliação por serviço. ' +
      'etiquetas usa as chaves da app: pontual, preco_justo, simpatico, trabalho_limpo, rapido (ids também servem).',
    access: ['cliente'],
    params: idParam,
    body: z.object({
      estrelas: z.number({ required_error: 'Escolha de 1 a 5 estrelas.', invalid_type_error: 'Escolha de 1 a 5 estrelas.' })
        .int('Escolha de 1 a 5 estrelas.').min(1, 'Escolha de 1 a 5 estrelas.').max(5, 'Escolha de 1 a 5 estrelas.'),
      comentario: z.string().trim().max(500, 'O comentário pode ter até 500 caracteres.').optional(),
      etiquetas: z.array(z.union([z.string().trim().min(2).max(30), z.number().int().positive()])).max(5).default([])
        .openapi({ example: ['pontual', 'preco_justo'] }),
    }),
  },
  async (req, res) => {
    const b = req.valid.body;
    const etiquetas = b.etiquetas.length
      ? await query<{ id: number; chave: string }>(`SELECT id, chave FROM etiqueta WHERE chave IN (?) OR id IN (?)`, [
          [...b.etiquetas.filter((e: unknown) => typeof e === 'string'), ''],
          [...b.etiquetas.filter((e: unknown) => typeof e === 'number'), 0],
        ])
      : [];
    const desconhecidas = b.etiquetas.filter((e: string | number) => !etiquetas.some((x) => x.chave === e || x.id === e));
    if (desconhecidas.length) throw badRequest(`Etiqueta desconhecida: ${desconhecidas.join(', ')}.`, 'ETIQUETA_INVALIDA');
    const out = await transaction(async (conn) => {
      const p = await carregarPedido(req.valid.params.id, conn);
      if (p.cliente_id !== req.user!.id) throw notFound('Pedido');
      if (!p.profissional_aceite_id) throw conflict('Este pedido não teve serviço.');
      const r = await execute(
        `INSERT INTO avaliacao (pedido_id, cliente_id, profissional_id, estrelas, comentario) VALUES (?,?,?,?,?)`,
        [p.id, req.user!.id, p.profissional_aceite_id, b.estrelas, b.comentario ?? null],
        conn,
      );
      if (etiquetas.length) {
        await execute(`INSERT IGNORE INTO avaliacao_etiqueta (avaliacao_id, etiqueta_id) VALUES ?`, [etiquetas.map((e) => [r.insertId, e.id])], conn);
      }
      return queryOne(
        `SELECT a.id, a.estrelas, a.comentario, p.media_avaliacao AS nova_media_profissional, p.total_avaliacoes,
                (SELECT GROUP_CONCAT(e.chave ORDER BY e.id) FROM avaliacao_etiqueta ae JOIN etiqueta e ON e.id = ae.etiqueta_id
                  WHERE ae.avaliacao_id = a.id) AS etiquetas
           FROM avaliacao a JOIN profissional p ON p.utilizador_id = a.profissional_id WHERE a.id = ?`,
        [r.insertId],
        conn,
      );
    });
    res.status(201).json({ ...out, etiquetas: out.etiquetas ? String(out.etiquetas).split(',') : [] });
  },
);

export default router;
