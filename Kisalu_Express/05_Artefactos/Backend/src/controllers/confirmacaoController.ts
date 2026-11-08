/**
 * Controller da confirmação do serviço (RF10, ecrã 16): o profissional lê o QR do cliente
 * ou escreve o código de 6 dígitos. Fecha o pedido pelo valor acordado e devolve o comprovativo.
 */
import { Request, Response } from 'express';
import { PoolConnection } from 'mysql2/promise';
import { transaction } from '../config/db';
import { AppError, badRequest, conflict, forbidden, notFound, tooMany } from '../utils/errors';
import { notificar } from '../services/notificacoes';
import { comprovativoJSON } from '../services/formatos';
import * as Pedido from '../models/pedidoModel';
import * as Proposta from '../models/propostaModel';
import * as Confirmacao from '../models/confirmacaoModel';

export const MAX_TENTATIVAS_CODIGO = 5;

const MSG_BLOQUEADO = 'Fez demasiadas tentativas. Peça ao cliente para abrir de novo o código na app.';

function erroCodigoErrado(metodo: 'qr' | 'codigo', restam: number) {
  const msg = metodo === 'qr' ? 'Este QR Code não corresponde ao serviço.' : 'Este código não corresponde ao serviço. Confirme com o cliente.';
  return badRequest(restam > 0 ? `${msg} Restam ${restam} tentativas.` : `${msg} Não restam tentativas.`, 'CODIGO_ERRADO');
}

/** Fecha o serviço: valida a alteração de preço e o QR, grava o comprovativo e avisa o cliente */
async function fecharServico(cs: Confirmacao.ConfirmacaoPendente, metodo: 'qr' | 'codigo', metodoPagamento: string, conn: PoolConnection) {
  if (await Proposta.alteracaoPendente(cs.proposta_aceite_id, conn)) {
    throw conflict('Há uma alteração de preço à espera do cliente. Peça-lhe que responda primeiro.', 'ALTERACAO_PENDENTE');
  }
  if (metodo === 'qr' && cs.qr_expirado) {
    throw badRequest('Este código expirou. Peça ao cliente para abrir o QR outra vez.', 'QR_EXPIRADO');
  }
  const numero = `KX-${new Date().getUTCFullYear()}-${String(cs.id).padStart(6, '0')}`;
  await Confirmacao.marcarConfirmado(cs.id, metodo, metodoPagamento, numero, conn);
  await notificar(
    cs.cliente_id,
    { tipo: 'lembrete_avaliacao', titulo: 'Serviço confirmado', corpo: `Comprovativo ${numero} guardado. Como correu? Avalie o serviço.`, pedido_id: cs.pedido_id, acao: 'avaliar' },
    conn,
  );
}

/**
 * Corre a confirmação numa transação. O erro de código errado só é lançado depois do commit,
 * para a tentativa ficar contada.
 */
async function confirmarComTentativas(fn: (conn: PoolConnection) => Promise<{ pedidoId: number } | { erro: AppError }>) {
  const r = await transaction(fn);
  if ('erro' in r) throw r.erro;
  return r.pedidoId;
}

/** POST /pedidos/:id/confirmar — o pedido vem no caminho */
export async function confirmarPorId(req: Request, res: Response) {
  const b = req.valid.body;
  const pedidoId = await confirmarComTentativas(async (conn) => {
    const p = await Pedido.carregarPedido(req.valid.params.id, conn, true);
    if (p.profissional_aceite_id !== req.user!.id) throw forbidden('Este serviço não está associado à sua conta.');
    if (!Pedido.ESTADOS_ATIVOS.includes(p.estado)) throw conflict('Este código já foi usado. Veja o estado do serviço em Pedidos.');
    if (await Proposta.alteracaoPendente(p.proposta_aceite_id, conn)) {
      throw conflict('Há uma alteração de preço à espera do cliente. Peça-lhe que responda primeiro.', 'ALTERACAO_PENDENTE');
    }
    const cs = await Confirmacao.pendenteDoPedido(p.id, conn);
    if (!cs) throw notFound('Confirmação');
    if (cs.tentativas >= MAX_TENTATIVAS_CODIGO) throw tooMany(MSG_BLOQUEADO);

    const metodo = b.token ? 'qr' : 'codigo';
    const certo = b.token ? b.token === cs.token_qr : b.codigo === cs.codigo_numerico;
    if (!certo) {
      await Confirmacao.contarTentativa([cs.id], conn);
      return { erro: erroCodigoErrado(metodo, MAX_TENTATIVAS_CODIGO - cs.tentativas - 1) };
    }
    await fecharServico(cs, metodo, b.metodo_pagamento, conn);
    return { pedidoId: p.id };
  });
  res.json(await comprovativoJSON(pedidoId));
}

/**
 * POST /pedidos/confirmar — o profissional só tem o código (ou o QR). Procura, entre os serviços
 * ativos dele com a confirmação pendente, o que corresponde, e confirma esse (QA-03/QA-05).
 *
 * - Código errado: conta uma tentativa em todos os serviços pendentes dele (assim não se pode
 *   adivinhar o código de um serviço tentando nos outros). Todos bloqueados → 429.
 * - Vários serviços com o mesmo código (só em desenvolvimento, com CODIGO_QR_FIXO_DEV): ganha o
 *   que o cliente abriu (ou renovou) no ecrã do QR mais recentemente.
 */
export async function confirmarPorCodigo(req: Request, res: Response) {
  const b = req.valid.body;
  const metodo: 'qr' | 'codigo' = b.token_qr ? 'qr' : 'codigo';
  const pedidoId = await confirmarComTentativas(async (conn) => {
    const pendentes = await Confirmacao.pendentesDoProfissional(req.user!.id, Pedido.ESTADOS_ATIVOS, conn);
    if (!pendentes.length) {
      throw new AppError(404, 'SEM_SERVICO_POR_CONFIRMAR', 'Não tem nenhum serviço à espera de confirmação. Veja os seus pedidos.');
    }
    const livres = pendentes.filter((c) => c.tentativas < MAX_TENTATIVAS_CODIGO);
    const certo = (c: Confirmacao.ConfirmacaoPendente) => (metodo === 'qr' ? c.token_qr === b.token_qr : c.codigo_numerico === b.codigo);

    // Já vêm ordenados pela última abertura do QR: o primeiro que corresponde é o escolhido
    const escolhido = pendentes.find(certo);
    if (escolhido && escolhido.tentativas >= MAX_TENTATIVAS_CODIGO) throw tooMany(MSG_BLOQUEADO);
    if (!escolhido) {
      if (!livres.length) throw tooMany(MSG_BLOQUEADO);
      await Confirmacao.contarTentativa(livres.map((c) => c.id), conn);
      const restam = Math.max(...livres.map((c) => MAX_TENTATIVAS_CODIGO - c.tentativas - 1));
      return { erro: erroCodigoErrado(metodo, restam) };
    }
    await fecharServico(escolhido, metodo, b.metodo_pagamento, conn);
    return { pedidoId: escolhido.pedido_id };
  });
  res.json(await comprovativoJSON(pedidoId));
}
