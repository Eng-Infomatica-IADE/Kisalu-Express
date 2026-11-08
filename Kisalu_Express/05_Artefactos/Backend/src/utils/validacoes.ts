/**
 * Validações partilhadas e mensagens de erro em português.
 * As mensagens seguem o catálogo da app (kissalu-app/docs/frontend/VALIDACOES.md):
 * dizem o problema e a solução, tratam por "você" e nunca dizem "Formato inválido".
 */
import { z, ZodErrorMap, ZodIssueCode } from 'zod';
import '../docs/registry'; // ativa .openapi() nos schemas

/** Como cada campo aparece nas mensagens genéricas */
const ROTULOS: Record<string, string> = {
  telemovel: 'o número de telemóvel',
  email: 'o email',
  codigo: 'o código',
  token: 'o código do QR',
  token_qr: 'o código do QR',
  perfil: 'o perfil',
  nome: 'o nome',
  nome_completo: 'o nome completo',
  titulo: 'o título do pedido',
  descricao: 'a descrição',
  categoria_id: 'o tipo de serviço',
  categoria_chave: 'o tipo de serviço',
  categorias: 'os serviços que presta',
  morada_id: 'a morada',
  zona: 'a zona',
  ponto_referencia: 'o ponto de referência',
  quando: 'quando precisa do serviço',
  data_pretendida: 'a data e hora',
  urgencia: 'a urgência',
  estado: 'o estado',
  tipo: 'o tipo de problema',
  motivo: 'o motivo',
  estrelas: 'as estrelas',
  comentario: 'o comentário',
  etiquetas: 'as etiquetas',
  texto: 'a mensagem',
  valor_mao_obra: 'o valor da mão de obra',
  valor_material: 'o valor do material',
  valor_deslocacao: 'o valor da deslocação',
  valor_novo: 'o novo valor',
  tempo_chegada_min: 'quando chega',
  metodo_pagamento: 'o método de pagamento',
  anos_experiencia: 'os anos de experiência',
  raio_atuacao_km: 'o raio de deslocação',
  aprovar: 'a resposta',
};

const rotulo = (path: (string | number)[]) => {
  const campo = [...path].reverse().find((p) => typeof p === 'string') as string | undefined;
  if (!campo) return 'este valor';
  return ROTULOS[campo] ?? `o campo "${campo}"`;
};

const TIPOS: Record<string, string> = {
  string: 'texto',
  number: 'um número',
  boolean: 'sim ou não (true/false)',
  array: 'uma lista',
  object: 'um objeto',
  date: 'uma data',
};

/** Mensagens genéricas em português para os casos sem mensagem própria no schema */
export const mapaDeErrosPt: ZodErrorMap = (issue, ctx) => {
  const r = rotulo(issue.path);
  switch (issue.code) {
    case ZodIssueCode.invalid_type:
      if (issue.received === 'undefined' || issue.received === 'null') return { message: `Indique ${r}.` };
      return { message: `Confirme ${r}: esperávamos ${TIPOS[issue.expected] ?? issue.expected}.` };
    case ZodIssueCode.too_small:
      if (issue.type === 'string') {
        return { message: Number(issue.minimum) <= 1 ? `Indique ${r}.` : `Escreva pelo menos ${issue.minimum} caracteres em ${r}.` };
      }
      if (issue.type === 'array') return { message: `Escolha pelo menos ${issue.minimum} em ${r}.` };
      if (issue.type === 'number') return { message: `O valor mínimo para ${r} é ${issue.minimum}.` };
      break;
    case ZodIssueCode.too_big:
      if (issue.type === 'string') return { message: `Escreva no máximo ${issue.maximum} caracteres em ${r}.` };
      if (issue.type === 'array') return { message: `Escolha no máximo ${issue.maximum} em ${r}.` };
      if (issue.type === 'number') return { message: `O valor máximo para ${r} é ${issue.maximum}.` };
      break;
    case ZodIssueCode.invalid_enum_value:
      return { message: `Escolha uma destas opções para ${r}: ${issue.options.join(', ')}.` };
    case ZodIssueCode.invalid_string:
      if (issue.validation === 'email') return { message: 'Confirme o email. Exemplo: maria@exemplo.com.' };
      return { message: `Confirme ${r}.` };
    case ZodIssueCode.invalid_date:
      return { message: `Escolha uma data válida para ${r}.` };
    case ZodIssueCode.not_multiple_of:
      return { message: `Confirme ${r}: use um número inteiro.` };
    case ZodIssueCode.invalid_union:
      return { message: `Confirme ${r}.` };
    case ZodIssueCode.unrecognized_keys:
      return { message: `Há campos que não reconhecemos: ${issue.keys.join(', ')}.` };
  }
  return { message: ctx.defaultError };
};

z.setErrorMap(mapaDeErrosPt);

// ---------------------------------------------------------------------
// Telemóvel angolano (+244 9XXXXXXXX)
// ---------------------------------------------------------------------

const faltam = (n: number, unidade: string) =>
  n === 1 ? `Falta 1 número. ${unidade}` : `Faltam ${n} números. ${unidade}`;
const aMais = (n: number, unidade: string) =>
  n === 1 ? `Tem 1 número a mais. ${unidade}` : `Tem ${n} números a mais. ${unidade}`;

/**
 * Valida um número de telemóvel angolano e devolve-o normalizado (+244923456789).
 * Aceita espaços, hífenes e o indicativo como +244, 00244 ou 244.
 */
export function mensagemTelemovel(valor: string): string | null {
  let t = valor.trim().replace(/[\s-]/g, '');
  if (!t) return 'Escreva o seu número de telemóvel.';
  if (t.startsWith('+244')) t = t.slice(4);
  else if (t.startsWith('00244')) t = t.slice(5);
  else if (t.startsWith('244') && t.length > 9) t = t.slice(3);
  else if (t.startsWith('+') || t.startsWith('00')) return 'Use um número angolano (+244). Exemplo: 923 456 789.';
  if (!/^\d+$/.test(t)) return 'Use só números. Exemplo: 923 456 789.';
  const UNIDADE = 'Um número angolano tem 9 dígitos.';
  if (t.length < 9) return faltam(9 - t.length, UNIDADE);
  if (t.length > 9) return aMais(t.length - 9, UNIDADE);
  if (t[0] !== '9') return 'O número começa por 9. Exemplo: 923 456 789.';
  return null;
}

export function normalizarTelemovel(valor: string): string {
  const t = valor.trim().replace(/[\s-]/g, '');
  return `+244${t.slice(-9)}`;
}

export const telemovelAngolano = z
  .string({ required_error: 'Escreva o seu número de telemóvel.', invalid_type_error: 'Escreva o seu número de telemóvel.' })
  .transform((s, ctx) => {
    const erro = mensagemTelemovel(s);
    if (erro) {
      ctx.addIssue({ code: ZodIssueCode.custom, message: erro });
      return z.NEVER;
    }
    return normalizarTelemovel(s);
  })
  .openapi({ example: '+244923000000', description: 'Número angolano: +244 e 9 dígitos começados por 9' });

// ---------------------------------------------------------------------
// Códigos de 6 dígitos
// ---------------------------------------------------------------------

interface MensagensCodigo {
  vazio: string;
  digitos: string;
  aMais: string;
}

/** Código de 6 dígitos; aceita "482 173" e devolve "482173" */
export function codigoSeisDigitos(m: MensagensCodigo) {
  return z
    .string({ required_error: m.vazio, invalid_type_error: m.vazio })
    .transform((s, ctx) => {
      const c = s.replace(/\s/g, '');
      const erro = !c
        ? m.vazio
        : !/^\d+$/.test(c)
          ? m.digitos
          : c.length < 6
            ? faltam(6 - c.length, 'O código tem 6 dígitos.')
            : c.length > 6
              ? m.aMais
              : null;
      if (erro) {
        ctx.addIssue({ code: ZodIssueCode.custom, message: erro });
        return z.NEVER;
      }
      return c;
    });
}

/** Código recebido por SMS (ecrã 11) */
export const codigoSms = codigoSeisDigitos({
  vazio: 'Escreva o código que recebeu por SMS.',
  digitos: 'Use só números. O código tem 6 dígitos.',
  aMais: 'O código tem 6 dígitos. Confirme o SMS.',
}).openapi({ example: '482173' });

/** Código alternativo ao QR, dito pelo cliente (ecrã 16) */
export const codigoServico = codigoSeisDigitos({
  vazio: 'Escreva o código que o cliente lhe disse.',
  digitos: 'Use só números. Exemplo: 482 173.',
  aMais: 'O código tem 6 dígitos. Confirme com o cliente.',
}).openapi({ example: '482173', description: 'Os 6 dígitos ditos pelo cliente (aceita "482 173")' });
