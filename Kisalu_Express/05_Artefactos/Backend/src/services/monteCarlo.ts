/**
 * Simulação de Monte Carlo da hora de chegada do profissional (Matemática Discreta).
 *
 * Modelo de uma chegada (minutos):
 *   tempo = preparação + viagem + atraso
 *   preparação ~ Uniforme(5, 15)                 sair de casa, juntar o material
 *   viagem     = distância_km / velocidade · 60
 *   velocidade ~ LogNormal(ln 18, σ = 0,5) km/h  mediana de 18 km/h no trânsito de Luanda;
 *                                                 a lognormal é sempre positiva e tem cauda
 *                                                 para as viagens lentas
 *   atraso     = Uniforme(5, 25) com prob. 0,3   engarrafamento, desvio, chuva
 *                0 nos outros casos
 *
 * Repetimos o modelo N = 10 000 vezes e lemos a média, os percentis 50 e 90 e a fração
 * de simulações que chegam dentro dos minutos prometidos na proposta.
 * O gerador tem semente, por isso a mesma proposta dá sempre o mesmo resultado.
 * Explicação completa em docs/MATEMATICA.md.
 */

export const PARAMETROS_CHEGADA = {
  simulacoes: 10_000,
  preparacaoMin: [5, 15] as const,
  velocidadeMedianaKmh: 18,
  velocidadeSigma: 0.5,
  probAtraso: 0.3,
  atrasoMin: [5, 25] as const,
};

/** Gerador pseudoaleatório mulberry32: 32 bits de estado, devolve números em [0, 1) */
export function mulberry32(semente: number): () => number {
  let a = semente >>> 0;
  return () => {
    a = (a + 0x6d2b79f5) >>> 0;
    let t = a;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

/** Normal padrão N(0, 1) pelo método de Box-Muller */
export function normalPadrao(aleatorio: () => number): number {
  const u1 = 1 - aleatorio(); // (0, 1], evita ln(0)
  const u2 = aleatorio();
  return Math.sqrt(-2 * Math.log(u1)) * Math.cos(2 * Math.PI * u2);
}

/** Uniforme contínua em [a, b) */
export const uniforme = (aleatorio: () => number, a: number, b: number) => a + (b - a) * aleatorio();

/** Semente estável a partir do id da proposta (hash multiplicativo de Knuth) */
export const sementeDaProposta = (propostaId: number) => Math.imul(propostaId, 2654435761) >>> 0;

/** Percentil pelo método do posto mais próximo: o valor na posição ⌈p · n⌉ dos dados ordenados */
export function percentil(ordenados: number[], p: number): number {
  if (!ordenados.length) throw new RangeError('Sem valores.');
  const i = Math.min(ordenados.length, Math.max(1, Math.ceil(p * ordenados.length)));
  return ordenados[i - 1];
}

/** Uma chegada simulada, em minutos */
export function simularUmaChegada(distanciaKm: number, aleatorio: () => number, P = PARAMETROS_CHEGADA): number {
  const preparacao = uniforme(aleatorio, P.preparacaoMin[0], P.preparacaoMin[1]);
  const velocidade = P.velocidadeMedianaKmh * Math.exp(P.velocidadeSigma * normalPadrao(aleatorio));
  const viagem = (distanciaKm / velocidade) * 60;
  const atraso = aleatorio() < P.probAtraso ? uniforme(aleatorio, P.atrasoMin[0], P.atrasoMin[1]) : 0;
  return preparacao + viagem + atraso;
}

export interface EstimativaChegada {
  simulacoes: number;
  media_min: number;
  p50_min: number;
  p90_min: number;
  /** Fração (0 a 1) das simulações que chegam dentro dos minutos prometidos */
  prob_cumprir: number;
}

const arred = (x: number, casas: number) => Math.round(x * 10 ** casas) / 10 ** casas;

export function estimarChegada(
  opcoes: { distanciaKm: number; prometidoMin: number; semente: number; simulacoes?: number },
  P = PARAMETROS_CHEGADA,
): EstimativaChegada {
  const n = opcoes.simulacoes ?? P.simulacoes;
  const aleatorio = mulberry32(opcoes.semente);
  const tempos = new Float64Array(n);
  let total = 0;
  let cumpre = 0;
  for (let i = 0; i < n; i++) {
    const t = simularUmaChegada(opcoes.distanciaKm, aleatorio, P);
    tempos[i] = t;
    total += t;
    if (t <= opcoes.prometidoMin) cumpre++;
  }
  const ordenados = Array.from(tempos).sort((a, b) => a - b);
  return {
    simulacoes: n,
    media_min: arred(total / n, 1),
    p50_min: arred(percentil(ordenados, 0.5), 1),
    p90_min: arred(percentil(ordenados, 0.9), 1),
    prob_cumprir: arred(cumpre / n, 3),
  };
}

/**
 * Estimativa de uma proposta, ou null quando faltam dados: sem distância (GPS em falta)
 * ou sem minutos prometidos (proposta "na hora pedida").
 */
export function estimativaDaProposta(propostaId: number, distanciaKm: number | null | undefined, prometidoMin: number | null | undefined) {
  if (distanciaKm === null || distanciaKm === undefined || prometidoMin === null || prometidoMin === undefined) return null;
  return estimarChegada({ distanciaKm: Number(distanciaKm), prometidoMin: Number(prometidoMin), semente: sementeDaProposta(propostaId) });
}
