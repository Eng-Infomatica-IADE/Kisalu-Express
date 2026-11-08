/**
 * Estatística descritiva e inferencial das avaliações (Matemática Discreta).
 * Funções puras: recebem números e devolvem números, sem base de dados.
 * As fórmulas estão explicadas em docs/MATEMATICA.md.
 */

/** Contagem de avaliações por número de estrelas: { 1: n1, …, 5: n5 } */
export type Distribuicao = Record<1 | 2 | 3 | 4 | 5, number>;

const ESTRELAS = [1, 2, 3, 4, 5] as const;

/** Média bayesiana: peso (em "avaliações fictícias") dado à média da categoria */
export const PRIOR_M = 10;

/** Valor crítico da normal para 95 % (bilateral) */
export const Z_95 = 1.96;

/**
 * Valores críticos t de Student para 95 % bilateral (t_{0,975; gl}), gl = 1 … 29.
 * A partir de n = 30 usa-se a normal (z = 1,96).
 */
export const T_95: readonly number[] = [
  12.706, 4.303, 3.182, 2.776, 2.571, 2.447, 2.365, 2.306, 2.262, 2.228,
  2.201, 2.179, 2.16, 2.145, 2.131, 2.12, 2.11, 2.101, 2.093, 2.086,
  2.08, 2.074, 2.069, 2.064, 2.06, 2.056, 2.052, 2.048, 2.045,
];

export function soma(valores: number[]): number {
  return valores.reduce((a, b) => a + b, 0);
}

/** x̄ = Σx / n */
export function media(valores: number[]): number | null {
  return valores.length ? soma(valores) / valores.length : null;
}

/** Valor do meio dos dados ordenados; com n par, a média dos dois do meio */
export function mediana(valores: number[]): number | null {
  const n = valores.length;
  if (!n) return null;
  const o = [...valores].sort((a, b) => a - b);
  const meio = Math.floor(n / 2);
  return n % 2 ? o[meio] : (o[meio - 1] + o[meio]) / 2;
}

/** Valor mais frequente. Em empate, devolve o menor (critério conservador). */
export function moda(valores: number[]): number | null {
  if (!valores.length) return null;
  const freq = new Map<number, number>();
  for (const v of valores) freq.set(v, (freq.get(v) ?? 0) + 1);
  let melhor: number | null = null;
  let max = 0;
  for (const [v, f] of freq) {
    if (f > max || (f === max && melhor !== null && v < melhor)) {
      melhor = v;
      max = f;
    }
  }
  return melhor;
}

/** Variância amostral: s² = Σ(x − x̄)² / (n − 1). null com menos de 2 valores. */
export function variancia(valores: number[]): number | null {
  const n = valores.length;
  if (n < 2) return null;
  const m = soma(valores) / n;
  return soma(valores.map((x) => (x - m) ** 2)) / (n - 1);
}

/** Desvio padrão amostral: s = √s² */
export function desvioPadrao(valores: number[]): number | null {
  const v = variancia(valores);
  return v === null ? null : Math.sqrt(v);
}

/** Frequência absoluta de cada número de estrelas (1 a 5) */
export function distribuicao(valores: number[]): Distribuicao {
  const d: Distribuicao = { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 };
  for (const v of valores) if (v >= 1 && v <= 5 && Number.isInteger(v)) d[v as 1]++;
  return d;
}

/** Operação inversa: a lista de valores que uma distribuição representa */
export function valoresDaDistribuicao(d: Distribuicao): number[] {
  return ESTRELAS.flatMap((e) => Array<number>(Math.max(0, Math.trunc(d[e] ?? 0))).fill(e));
}

/** Valor crítico para 95 %: t de Student com n − 1 graus de liberdade se n < 30; z = 1,96 se n ≥ 30 */
export function valorCritico95(n: number): { valor: number; metodo: 't' | 'z' } {
  if (n >= 30) return { valor: Z_95, metodo: 'z' };
  if (n < 2) throw new RangeError('São precisos pelo menos 2 valores.');
  return { valor: T_95[n - 2], metodo: 't' };
}

export interface Intervalo {
  inferior: number;
  superior: number;
  metodo: 't' | 'z';
}

/**
 * Intervalo de confiança a 95 % para a média: x̄ ± c · s / √n.
 * Como uma média de estrelas nunca sai de [1, 5], os limites são cortados a esse intervalo.
 */
export function intervaloConfianca95(valores: number[], limites: [number, number] = [1, 5]): Intervalo | null {
  const n = valores.length;
  const s = desvioPadrao(valores);
  if (s === null) return null;
  const m = soma(valores) / n;
  const { valor, metodo } = valorCritico95(n);
  const margem = (valor * s) / Math.sqrt(n);
  return {
    inferior: Math.max(limites[0], m - margem),
    superior: Math.min(limites[1], m + margem),
    metodo,
  };
}

/**
 * Média bayesiana: (m · C + Σx) / (m + n).
 * É a média que se obtém juntando m avaliações "fictícias" iguais à média C da categoria.
 * Com poucas avaliações fica perto de C; com muitas, perto da média do profissional.
 */
export function mediaBayesiana(somaValores: number, n: number, mediaCategoria: number, m = PRIOR_M): number {
  return (m * mediaCategoria + somaValores) / (m + n);
}

const arred = (x: number | null, casas: number) => (x === null ? null : Math.round(x * 10 ** casas) / 10 ** casas);

/** Resposta de GET /profissionais/:id/estatisticas, a partir da distribuição 1–5 */
export function estatisticasAvaliacoes(d: Distribuicao, mediaCategoria: number | null) {
  const valores = valoresDaDistribuicao(d);
  const n = valores.length;
  const ic = intervaloConfianca95(valores);
  const C = mediaCategoria ?? media(valores);
  return {
    n,
    media: arred(media(valores), 2),
    mediana: mediana(valores),
    moda: moda(valores),
    desvio_padrao: arred(desvioPadrao(valores), 2),
    variancia: arred(variancia(valores), 3),
    ic95: ic ? { inferior: arred(ic.inferior, 2)!, superior: arred(ic.superior, 2)!, metodo: ic.metodo } : null,
    distribuicao: { '1': d[1], '2': d[2], '3': d[3], '4': d[4], '5': d[5] },
    media_bayesiana: C === null ? null : arred(mediaBayesiana(soma(valores), n, C), 2),
  };
}
