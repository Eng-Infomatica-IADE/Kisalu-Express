/**
 * Matemática Discreta: estatística das avaliações e Monte Carlo da chegada.
 * Os valores esperados foram calculados à mão (ver docs/MATEMATICA.md).
 */
import { describe, expect, it } from 'vitest';
import request from 'supertest';
import {
  desvioPadrao, distribuicao, estatisticasAvaliacoes, intervaloConfianca95, media, mediaBayesiana, mediana, moda,
  valorCritico95, valoresDaDistribuicao, variancia,
} from '../src/services/estatistica';
import { estimarChegada, mulberry32, percentil, sementeDaProposta } from '../src/services/monteCarlo';
import { app, auth, EMAIL, login } from './helpers';

describe('estatística descritiva', () => {
  // x = 2, 4, 4, 5, 5 → Σx = 20, x̄ = 4, Σ(x − x̄)² = 4 + 0 + 0 + 1 + 1 = 6
  const x = [5, 4, 2, 5, 4];

  it('média, mediana e moda', () => {
    expect(media(x)).toBe(4);
    expect(mediana(x)).toBe(4);
    expect(mediana([1, 2, 4, 5])).toBe(3); // n par: (2 + 4) / 2
    expect(moda(x)).toBe(4); // empate 4/5 → o menor
    expect(moda([5, 5, 4])).toBe(5);
    expect(media([])).toBeNull();
  });

  it('variância e desvio padrão amostrais (n − 1)', () => {
    expect(variancia(x)).toBeCloseTo(1.5, 10); // 6 / 4
    expect(desvioPadrao(x)).toBeCloseTo(Math.sqrt(1.5), 10); // 1,2247
    expect(variancia([3])).toBeNull();
  });

  it('distribuição de frequências e o caminho inverso', () => {
    expect(distribuicao(x)).toEqual({ 1: 0, 2: 1, 3: 0, 4: 2, 5: 2 });
    expect(valoresDaDistribuicao({ 1: 1, 2: 0, 3: 0, 4: 2, 5: 1 })).toEqual([1, 4, 4, 5]);
  });

  it('valor crítico: t de Student com n − 1 g.l. se n < 30, z = 1,96 se n ≥ 30', () => {
    expect(valorCritico95(5)).toEqual({ valor: 2.776, metodo: 't' });
    expect(valorCritico95(29)).toEqual({ valor: 2.048, metodo: 't' });
    expect(valorCritico95(30)).toEqual({ valor: 1.96, metodo: 'z' });
  });

  it('IC 95 % com t (n = 5), cortado a [1, 5]', () => {
    // margem = 2,776 · 1,2247 / √5 = 1,5205 → [2,48 ; 5,52] → superior cortado a 5
    const ic = intervaloConfianca95(x)!;
    expect(ic.metodo).toBe('t');
    expect(ic.inferior).toBeCloseTo(2.4795, 3);
    expect(ic.superior).toBe(5);
  });

  it('média bayesiana puxa para a média da categoria quando há poucas avaliações', () => {
    // (10 · 4,5 + 20) / (10 + 5) = 65 / 15 = 4,333
    expect(mediaBayesiana(20, 5, 4.5)).toBeCloseTo(4.3333, 4);
    // 2 avaliações de 5★ valem (47,8 + 10) / 12 = 4,82, não 5,0; um 3★ a seguir já a põe em 4,69
    expect(mediaBayesiana(10, 2, 4.78)).toBeCloseTo(4.8167, 4);
    expect(mediaBayesiana(13, 3, 4.78)).toBeLessThan(mediaBayesiana(604, 126, 4.78));
  });

  it('Joaquim: 126 avaliações (1, 1, 3, 13, 108)', () => {
    // Σx = 604, Σx² = 2940 → x̄ = 4,7937; s² = (2940 − 604²/126) / 125 = 0,3571; s = 0,5976
    // n ≥ 30 → z: 1,96 · 0,5976 / √126 = 0,1043 → [4,69 ; 4,90]
    // C = (604 + 247 + 474) / (126 + 54 + 97) = 4,7834 → (47,834 + 604) / 136 = 4,79
    const e = estatisticasAvaliacoes({ 1: 1, 2: 1, 3: 3, 4: 13, 5: 108 }, 1325 / 277);
    expect(e).toEqual({
      n: 126,
      media: 4.79,
      mediana: 5,
      moda: 5,
      desvio_padrao: 0.6,
      variancia: 0.357,
      ic95: { inferior: 4.69, superior: 4.9, metodo: 'z' },
      distribuicao: { '1': 1, '2': 1, '3': 3, '4': 13, '5': 108 },
      media_bayesiana: 4.79,
    });
  });

  it('Hélder: 28 avaliações usam t com 27 g.l.', () => {
    // Σx = 123, Σx² = 559 → x̄ = 4,393; s² = 0,6918; s = 0,8318; 2,052 · 0,8318 / √28 = 0,3226
    const e = estatisticasAvaliacoes({ 1: 0, 2: 1, 3: 3, 4: 8, 5: 16 }, null);
    expect(e.ic95).toEqual({ inferior: 4.07, superior: 4.72, metodo: 't' });
    expect(e.media_bayesiana).toBe(e.media); // sem média da categoria, o prior é a própria média
  });

  it('sem avaliações tudo vem a null', () => {
    const e = estatisticasAvaliacoes({ 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 }, 4.7);
    expect(e).toMatchObject({ n: 0, media: null, mediana: null, moda: null, desvio_padrao: null, ic95: null, media_bayesiana: 4.7 });
  });
});

describe('Monte Carlo da chegada', () => {
  it('mulberry32 é reprodutível e fica em [0, 1)', () => {
    const a = mulberry32(42);
    const b = mulberry32(42);
    const xs = Array.from({ length: 1000 }, () => a());
    expect(xs).toEqual(Array.from({ length: 1000 }, () => b()));
    expect(xs.every((v) => v >= 0 && v < 1)).toBe(true);
    expect(mulberry32(43)()).not.toBe(xs[0]);
  });

  it('percentil pelo posto mais próximo', () => {
    const o = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
    expect(percentil(o, 0.5)).toBe(5);
    expect(percentil(o, 0.9)).toBe(9);
  });

  it('mesma semente, mesmo resultado; sementes diferentes por proposta', () => {
    const o = { distanciaKm: 3, prometidoMin: 25, semente: sementeDaProposta(3) };
    expect(estimarChegada(o)).toEqual(estimarChegada(o));
    expect(sementeDaProposta(1)).not.toBe(sementeDaProposta(2));
  });

  it('a média simulada bate com a média teórica', () => {
    // E[t] = 10 + d · 60/18 · e^{σ²/2} + 0,3 · 15; com d = 3: 10 + 10 · 1,1331 + 4,5 = 25,83
    const e = estimarChegada({ distanciaKm: 3, prometidoMin: 25, semente: 7 });
    expect(e.simulacoes).toBe(10_000);
    expect(e.media_min).toBeGreaterThan(25.3);
    expect(e.media_min).toBeLessThan(26.4);
    expect(e.p50_min).toBeLessThan(e.p90_min);
    expect(e.prob_cumprir).toBeGreaterThan(0);
    expect(e.prob_cumprir).toBeLessThan(1);
  });

  it('sem distância, o tempo fica entre 5 e 40 min; prometer mais nunca baixa a probabilidade', () => {
    const zero = estimarChegada({ distanciaKm: 0, prometidoMin: 40, semente: 1 });
    expect(zero.prob_cumprir).toBe(1);
    const curto = estimarChegada({ distanciaKm: 4, prometidoMin: 20, semente: 9 });
    const longo = estimarChegada({ distanciaKm: 4, prometidoMin: 40, semente: 9 });
    expect(longo.prob_cumprir).toBeGreaterThan(curto.prob_cumprir);
  });
});

describe('endpoints', () => {
  it('GET /profissionais/:id/estatisticas (público)', async () => {
    // Hélder (mecânico, sem avaliações nos outros testes): 0, 1, 3, 8, 16
    const res = await request(app).get('/api/profissionais/9/estatisticas').expect(200);
    expect(res.body.data).toEqual({
      n: 28,
      media: 4.39,
      mediana: 5,
      moda: 5,
      desvio_padrao: 0.83,
      variancia: 0.692,
      ic95: { inferior: 4.07, superior: 4.72, metodo: 't' },
      distribuicao: { '1': 0, '2': 1, '3': 3, '4': 8, '5': 16 },
      media_bayesiana: 4.39, // único mecânico: a média da categoria é a dele
    });
    // Joaquim: a distribuição soma o total do perfil (os outros testes podem ter juntado avaliações)
    const [est, perfil] = await Promise.all([
      request(app).get('/api/profissionais/2/estatisticas').expect(200),
      request(app).get('/api/profissionais/2').expect(200),
    ]);
    const d = est.body.data.distribuicao;
    expect(d['1'] + d['2'] + d['3'] + d['4'] + d['5']).toBe(perfil.body.data.total_avaliacoes);
    expect(est.body.data.n).toBe(perfil.body.data.total_avaliacoes);
    expect(est.body.data.ic95.metodo).toBe('z');
    await request(app).get('/api/profissionais/999999/estatisticas').expect(404);
  });

  it('a pesquisa por avaliação devolve a média bayesiana', async () => {
    const res = await request(app).get('/api/profissionais?ordenar=avaliacao&categoria_chave=canalizador').expect(200);
    const lista = res.body.data;
    expect(lista.length).toBeGreaterThan(0);
    for (let i = 1; i < lista.length; i++) {
      if (lista[i].verificado === lista[i - 1].verificado) {
        expect(Number(lista[i - 1].media_bayesiana)).toBeGreaterThanOrEqual(Number(lista[i].media_bayesiana));
      }
    }
  });

  it('estimativa de chegada: cliente e profissional da proposta veem, outros não', async () => {
    const maria = await login(EMAIL.maria);
    const res = await request(app).get('/api/propostas/1/estimativa-chegada').set(auth(maria)).expect(200);
    expect(res.body.data).toMatchObject({ proposta_id: 1, distancia_km: 1.2, simulacoes: 10_000 });
    expect(res.body.data.prob_cumprir).toBeGreaterThan(0.9);

    const joaquim = await login(EMAIL.joaquim);
    await request(app).get('/api/propostas/1/estimativa-chegada').set(auth(joaquim)).expect(200);
    const rui = await login(EMAIL.rui);
    await request(app).get('/api/propostas/1/estimativa-chegada').set(auth(rui)).expect(404);

    // A mesma estimativa vem dentro da PropostaJSON do GET /pedidos/1 (só para o cliente)
    const pedido = await request(app).get('/api/pedidos/1').set(auth(maria)).expect(200);
    const pr1 = pedido.body.data.propostas.find((p: any) => p.id === 1);
    const { proposta_id: _a, distancia_km: _b, tempo_prometido_min: _c, ...estimativa } = res.body.data;
    expect(pr1.estimativa_chegada).toEqual(estimativa);
    const visto = await request(app).get('/api/pedidos/1').set(auth(joaquim)).expect(200);
    expect(visto.body.data.propostas[0].estimativa_chegada).toBeNull();
  });
});
