# Kisalu Express · Métodos numéricos e estatística

O briefing de Matemática Discreta pede pelo menos um método numérico (escolhemos **Monte Carlo**) e conceitos de estatística dados nas aulas. Os dois estão na API e aparecem na app:

| O quê | Código | Endpoint | Onde aparece na app |
|---|---|---|---|
| Estatística das avaliações | `src/services/estatistica.ts` | `GET /profissionais/:id/estatisticas` | Ecrã 03 (perfil do profissional), bloco "Avaliações em números" |
| Média bayesiana | `src/services/estatistica.ts`, `src/models/profissionalModel.ts` | `GET /profissionais?ordenar=avaliacao` | Ordem dos profissionais na pesquisa |
| Monte Carlo da chegada | `src/services/monteCarlo.ts` | `GET /propostas/:id/estimativa-chegada` e `estimativa_chegada` em cada PropostaJSON do `GET /pedidos/:id` | Ecrã 04 (propostas): "Chega a tempo em ~85% dos casos" |

As funções são puras (números entram, números saem) e estão testadas em `tests/matematica.test.ts` com valores calculados à mão.

## 1. Estatística das avaliações

### De onde vêm os dados

Cada avaliação tem 1 a 5 estrelas. Os dados de exemplo trazem profissionais com historial (o Joaquim tem 126 avaliações) mas só algumas linhas em `avaliacao`. Por isso guardamos a **distribuição de frequências** no próprio perfil: colunas `profissional.avaliacoes_1` … `avaliacoes_5`. Estas contagens incluem o historial e as linhas reais; o trigger `trg_avaliacao_media` soma 1 à coluna certa em cada avaliação nova e recalcula `total_avaliacoes` e `media_avaliacao` a partir delas.

Uma distribuição $(n_1, …, n_5)$ representa a amostra $x_1, …, x_n$ com $n = \sum_k n_k$ valores, em que o valor $k$ aparece $n_k$ vezes. É sobre essa amostra que calculamos tudo.

### Fórmulas

| Medida | Fórmula | Notas |
|---|---|---|
| Média | $\bar{x} = \frac{1}{n}\sum_{i=1}^{n} x_i = \frac{1}{n}\sum_{k=1}^{5} k\,n_k$ | |
| Mediana | valor do meio dos dados ordenados; com $n$ par, média dos dois do meio | |
| Moda | valor com maior $n_k$ | em empate fica o menor (critério conservador) |
| Variância amostral | $s^2 = \frac{1}{n-1}\sum_{i=1}^{n}(x_i - \bar{x})^2$ | divide por $n-1$ (amostra, não população); `null` com $n < 2$ |
| Desvio padrão amostral | $s = \sqrt{s^2}$ | |
| IC a 95 % da média | $\bar{x} \pm c \cdot \frac{s}{\sqrt{n}}$ | $c = t_{0{,}975;\,n-1}$ se $n < 30$; $c = z_{0{,}975} = 1{,}96$ se $n \ge 30$ |
| Média bayesiana | $\tilde{x} = \frac{m\,C + \sum x_i}{m + n}$ | $m = 10$, $C$ = média global da categoria |

**Intervalo de confiança.** Com poucas avaliações não se conhece o desvio padrão da população e a média segue uma t de Student com $n-1$ graus de liberdade; a tabela dos valores críticos para 95 % (gl = 1 a 29) está em `T_95`, no código. A partir de 30 avaliações, pelo Teorema do Limite Central, usamos a normal ($z = 1{,}96$). Como uma média de estrelas nunca sai de [1, 5], os limites são cortados a esse intervalo (acontece com amostras muito pequenas).

**Média bayesiana.** Um profissional novo com duas avaliações de 5★ tem média 5,0, mas isso diz pouco. A média bayesiana junta-lhe $m = 10$ avaliações "fictícias" iguais à média $C$ da sua categoria principal (vista `vw_media_categoria`: soma de todas as estrelas dos profissionais da categoria a dividir pelo número de avaliações). Com poucas avaliações o resultado fica perto de $C$; com muitas, perto da média do próprio profissional. O valor $m = 10$ é da ordem do número de avaliações a partir do qual a média de um profissional começa a ser estável: pequeno ao lado dos 126 do Joaquim (muda-lhe a média menos de 0,01), grande ao lado de 2 ou 3. Na pesquisa (`ordenar=avaliacao`) o prior é a média da categoria pesquisada; sem categoria, a da categoria principal de cada profissional.

### Exemplo: Joaquim Manuel (126 avaliações)

Distribuição: $n_1 = 1$, $n_2 = 1$, $n_3 = 3$, $n_4 = 13$, $n_5 = 108$.

- $n = 126$; $\sum x = 1 + 2 + 9 + 52 + 540 = 604$; $\bar{x} = 604 / 126 = 4{,}794$ (o perfil mostra 4,8).
- Mediana e moda: 5 (mais de metade das avaliações são de 5★).
- $\sum x^2 = 1 + 4 + 27 + 208 + 2700 = 2940$, logo $s^2 = \frac{2940 - 604^2/126}{125} = \frac{2940 - 2895{,}365}{125} = 0{,}357$ e $s = 0{,}598$.
- $n \ge 30$, logo $z$: margem $= 1{,}96 \times 0{,}598 / \sqrt{126} = 1{,}96 \times 0{,}0533 = 0{,}104$. IC 95 % = [4,69 ; 4,90].
- Categoria principal: canalizador (Joaquim, Rui, Paulo): $C = \frac{604 + 247 + 474}{126 + 54 + 97} = \frac{1325}{277} = 4{,}783$.
- $\tilde{x} = \frac{10 \times 4{,}783 + 604}{10 + 126} = \frac{651{,}83}{136} = 4{,}79$.

Resposta real de `GET /profissionais/2/estatisticas`:

```json
{ "n": 126, "media": 4.79, "mediana": 5, "moda": 5, "desvio_padrao": 0.6, "variancia": 0.357,
  "ic95": { "inferior": 4.69, "superior": 4.9, "metodo": "z" },
  "distribuicao": { "1": 1, "2": 1, "3": 3, "4": 13, "5": 108 }, "media_bayesiana": 4.79 }
```

Com $n < 30$, o Hélder (28 avaliações: 0, 1, 3, 8, 16) usa $t_{0{,}975;27} = 2{,}052$: $\bar{x} = 4{,}39$, $s = 0{,}832$, margem $= 2{,}052 \times 0{,}832/\sqrt{28} = 0{,}323$, IC = [4,07 ; 4,72] com `"metodo": "t"`.

E porque é que a ordenação bayesiana é mais justa: um profissional novo com 2 avaliações de 5★ numa categoria com $C = 4{,}78$ fica com $\tilde{x} = (47{,}8 + 10)/12 = 4{,}82$ (não 5,0); se a terceira avaliação for de 3★, desce para $(47{,}8 + 13)/13 = 4{,}68$ e fica abaixo do Joaquim. Uma nota fraca do Joaquim, pelo contrário, quase não lhe mexe na média.

### Na app (ecrã 03)

Bloco "Avaliações em números": "4,8 ± 0,6" (média ± desvio padrão), "Entre 4,7 e 4,9 com 95% de confiança", barras horizontais com a distribuição de 5 a 1 estrelas (o número ao lado de cada barra; o leitor de ecrã ouve "5 estrelas: 108 avaliações") e "n = 126 avaliações".

## 2. Monte Carlo: probabilidade de chegar a tempo

Na proposta o profissional promete chegar em X minutos ("chega em 40 min"). Monte Carlo responde à pergunta do cliente: **qual é a probabilidade de isso acontecer?** Não há fórmula fechada simples para a soma de uma uniforme, de uma razão com uma lognormal e de uma mistura; por isso simulamos muitas chegadas e contamos.

### Modelo de uma chegada

$$T = P + \frac{d}{V}\cdot 60 + A$$

| Termo | Distribuição | Porquê |
|---|---|---|
| $P$, preparação | $U(5, 15)$ min | sair, juntar a ferramenta e o material: no mínimo 5 min, raramente mais de 15 |
| $d$, distância | fixa, em km | linha reta (Haversine) entre a zona base do profissional e a morada do pedido |
| $V$, velocidade | $\ln V \sim N(\ln 18;\ 0{,}5^2)$ km/h | lognormal: é sempre positiva e tem cauda para as viagens lentas. Mediana 18 km/h, uma estimativa para candongueiro, mota ou carro no trânsito urbano de Luanda; com $\sigma = 0{,}5$, 90 % das viagens ficam entre 8 e 41 km/h |
| $A$, atraso | $U(5, 25)$ min com probabilidade 0,3; 0 nos outros casos | engarrafamento, desvio, chuva: cerca de uma em cada três viagens tem um imprevisto |

Os parâmetros são suposições razoáveis, não medições: quando a app tiver chegadas reais (hora de "A caminho" e de "Em curso"), podem ser ajustados aos dados.

### Algoritmo

1. Gerador pseudoaleatório **mulberry32** com semente. A semente é derivada do id da proposta (hash multiplicativo de Knuth, $\text{id} \times 2654435761 \bmod 2^{32}$), por isso a mesma proposta dá sempre o mesmo resultado e os testes são reprodutíveis.
2. Normal padrão pelo método de **Box-Muller**: $Z = \sqrt{-2\ln U_1}\cos(2\pi U_2)$; velocidade $V = 18\,e^{0{,}5 Z}$.
3. Repetir $N = 10\,000$ vezes: gerar $P$, $V$, $A$ e calcular $T_j$.
4. Resultados:
   - `media_min` $= \frac{1}{N}\sum T_j$;
   - `p50_min` e `p90_min`: percentis pelo método do posto mais próximo (o valor na posição $\lceil pN \rceil$ dos tempos ordenados);
   - `prob_cumprir` $= \frac{\#\{j : T_j \le X\}}{N}$, com $X$ = `tempo_chegada_min` da proposta.

Com $N = 10\,000$ o erro padrão de `prob_cumprir` é no máximo $\sqrt{0{,}25/10\,000} = 0{,}005$, meio ponto percentual: chega bem para uma frase arredondada a 5 %.

Verificação com a média teórica (teste automático): $E[T] = 10 + d \cdot \frac{60}{18} e^{\sigma^2/2} + 0{,}3 \times 15$. Para $d = 3$ km, $E[T] = 10 + 10 \times 1{,}133 + 4{,}5 = 25{,}83$ min; a simulação dá um valor a menos de 0,5 min disto.

### Exemplo: as três propostas do pedido 1 da Maria

Respostas reais de `GET /propostas/:id/estimativa-chegada`:

| Proposta | Distância | Prometido | Média | p50 | p90 | prob_cumprir | Na app |
|---|---|---|---|---|---|---|---|
| 1, Joaquim | 1,2 km | 40 min | 19,0 | 16,6 | 32,8 | 0,980 | "Chega a tempo em ~100% dos casos" |
| 2, Rui | 1,8 km | 60 min | 21,5 | 18,9 | 35,7 | 1,000 | "Chega a tempo em ~100% dos casos" |
| 3, Paulo | 2,9 km | 25 min | 25,5 | 23,1 | 40,1 | 0,576 | "Chega a tempo em ~60% dos casos" |

O Paulo promete o tempo mais curto, mas é o que tem menos hipóteses de o cumprir: está mais longe e 25 min mal chegam para a preparação mais a viagem.

### Na app (ecrã 04)

No cartão de cada proposta, por baixo das estrelas, uma linha discreta: "Chega a tempo em ~85% dos casos" (percentagem arredondada a 5 %). Verde com ícone de relógio a partir de 80 %; abaixo disso, cor de aviso com ícone de aviso (nunca só a cor). A ordenação "Chegada" continua pela hora prometida e desempata pela mediana simulada (`p50_min`). Propostas "na hora pedida" ou sem GPS não trazem estimativa (`null`) e não mostram a linha.
