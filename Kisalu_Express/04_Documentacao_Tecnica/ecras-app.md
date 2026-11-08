# Especificação das telas — Kisalu Express (Figma v2 e v3)

Fonte: Figma **"Kisalu Express — Mockups (G05)"**, secção **"Mockups v2 (após avaliação heurística)"**
(<https://www.figma.com/design/y6x5pO2mwQpoiF5ep18mSl/Kisalu-Express-%E2%80%94-Mockups--G05-?node-id=1-2>).
Os ecrãs 01–10 são da **v2** (a v1 fica no Figma apenas para comparação). Os ecrãs 11–22 são da secção
**"Mockups v3"**, com as correções da avaliação heurística de 2 de novembro, que estão na secção
**"Mockups v3.1 (correções heurísticas)"** (frame `68:2`, ver o fim deste ficheiro). A barra de estado
9:41 é do sistema e não se implementa.

- Frame base: **360 × 844 dp** (Android), escala 1 dp = 1 px.
- Imagens de referência: `ecras/NN-*.png` (capturas do Figma, ~374 × 806 px).
  **Abre sempre a imagem antes de implementar uma tela.**
- Regras visuais: `docs/design/STYLE_GUIDE.md` (repositório kissalu-app). Dados: `app/lib/data/mock/` (via `KisaluRepository`).
- Os textos abaixo são **literais** (copiar exatamente, incluindo acentos e "Kz").
- `P01…P22` = problemas da avaliação heurística que a tela corrige (Relatório Fase 1, cap. 3). Não os reintroduzir.
- As telas são **estáticas**: sem backend. Botões navegam entre telas ou mostram estados com dados mock.

## Índice

> As linhas 23 a 30 foram acrescentadas à cópia depois do teste de QA ponta a ponta; as capturas em `ecras/` são da v3 (geradas a partir da app Flutter) e têm ~780 px de largura (originais de 3120 × 6752 px em `../02_Imagens`).

| # | Tela | Rota | Barra inferior | Ficheiro | Imagem |
|---|------|------|----------------|----------|--------|
| 01 | Login / Registo | `/login` | não | `features/autenticacao/views/login_view.dart` | `01-login.png` |
| 02 | Início — pesquisa de profissionais | `/inicio` | Início ativo | `features/inicio/views/inicio_view.dart` | `02-inicio.png` |
| 03 | Perfil do profissional | `/profissional/:id` | não | `features/profissional/views/perfil_profissional_view.dart` | `03-perfil-profissional.png` |
| 04 | Pedido e propostas | `/pedidos/:id` | Pedidos ativo | `features/pedidos/views/pedido_detalhe_view.dart` | `04-pedido-propostas.png` |
| 05 | Confirmação por QR Code | `/qr` | QR ativo | `features/confirmacao_qr/views/confirmar_servico_view.dart` | `05-confirmar-qr.png` |
| 06 | Avaliação do serviço | `/pedidos/:id/avaliar` | não | `features/avaliacao/views/avaliar_servico_view.dart` | `06-avaliar-servico.png` |
| 07 | Histórico de pedidos | `/pedidos` | Pedidos ativo | `features/pedidos/views/historico_pedidos_view.dart` | `07-historico-pedidos.png` |
| 08 | Confirmar proposta (bottom sheet) | sobre `/pedidos/:id` | — | `features/pedidos/widgets/confirmar_proposta_sheet.dart` | `08-confirmar-proposta.png` |
| 09 | QR sem serviço em curso | `/qr` (sem serviço) · `/qr?vazio=1` | QR **desativado** | mesmo ficheiro da 05 | `09-qr-sem-servico.png` |
| 10 | Novo pedido sem rede | `/novo-pedido` · passo 1: `/novo-pedido?novo=1` | não | `features/novo_pedido/views/novo_pedido_view.dart` | `10-novo-pedido-sem-rede.png` |
| 11 | Código SMS | `/codigo-sms` | não | `features/autenticacao/views/codigo_sms_view.dart` | `11-codigo-sms.png` |
| 12 | Criar perfil (profissional, passo 1 de 3) | `/registo-profissional` | não | `features/registo_profissional/views/registo_profissional_view.dart` | `12-registo-profissional.png` |
| 13 | Verificar identidade (passo 2 de 3) | `/verificar-identidade` | não | `features/registo_profissional/views/verificar_identidade_view.dart` | `13-verificar-identidade.png` |
| 14 | Início do profissional | `/inicio` em modo profissional | Início ativo | `features/inicio_profissional/views/inicio_profissional_view.dart` | `14-inicio-profissional.png` |
| 15 | Enviar proposta | `/enviar-proposta/:pedidoId` | não | `features/proposta/views/enviar_proposta_view.dart` | `15-enviar-proposta.png` |
| 16 | Confirmar serviço (ler o QR do cliente) | `/qr` em modo profissional | QR ativo | `features/confirmacao_profissional/views/ler_qr_view.dart` | `16-ler-qr.png` |
| 17 | Serviço confirmado (profissional) | `/servico-confirmado/:pedidoId` | não | `features/confirmacao_profissional/views/servico_confirmado_view.dart` | `17-servico-confirmado.png` |
| 18 | Conversas | `/conversas` | Conversas ativo | `features/conversas/views/conversas_view.dart` | `18-conversas.png` |
| 19 | Conversa do pedido | `/conversas/:id` | não | `features/conversas/views/conversa_view.dart` | `19-conversa-pedido.png` |
| 20 | Perfil | `/perfil` | Perfil ativo | `features/perfil/views/perfil_view.dart` | `20-perfil.png` |
| 21 | Todos os serviços | `/categorias` | não | `features/categorias/views/todos_servicos_view.dart` | `21-todos-servicos.png` |
| 22 | Mapa "Perto de si" | `/mapa` | não | `features/mapa/views/mapa_view.dart` | `22-mapa.png` |
| 23 | Notificações | `/notificacoes` | não | `features/notificacoes/views/notificacoes_view.dart` | `23-notificacoes.png` |
| 24 | Ajuda | `/ajuda` | não | `features/ajuda/views/ajuda_view.dart` | `24-ajuda.png` |
| 25 | Detalhe do trabalho (profissional) | `/trabalhos/:id` | não | `features/trabalho/views/trabalho_detalhe_view.dart` | `25-trabalho-detalhe.png` |
| 26 | Pedido depois de aceitar a proposta | `/pedidos/:id` | Pedidos ativo | mesmo ficheiro da 04 | `26-pedido-aceite.png` |
| 27 | Editar pedido | `/novo-pedido?editar=:id` | não | mesmo ficheiro da 10 | `27-editar-pedido.png` |
| 28 | Reportar problema (folha) | sobre o pedido | — | `features/pedidos/` | `28-reportar-problema.png` |
| 29 | Comprovativo (folha do histórico) | sobre `/pedidos` | — | `features/pedidos/widgets/historico_comprovativo_folha.dart` | `29-comprovativo.png` |
| 30 | Recusar proposta (diálogo) | sobre `/pedidos/:id` | — | `features/pedidos/widgets/pedido_detalhe_proposta_cartao.dart` | `30-recusar-proposta.png` |

**Perfil ativo.** A sessão tem um perfil ativo (cliente ou profissional) exposto por `KisaluRepository.perfilAtivo`
e alterado por `mudarPerfil` (avisa por `alteracoes`). Decide o separador **Início** (02 ou 14), o separador **QR**
(05/09 ou 16) e a lista do separador **Pedidos** (pedidos do cliente ou trabalhos do profissional). O `AppShell`
mantém o QR sempre ativo em modo profissional.

---

## Componentes partilhados (construir primeiro — milestone M1)

Ficam em `app/lib/core/widgets/`, prefixo `K`. Detalhes de medidas no `STYLE_GUIDE.md`.

| Componente | Usado em | Notas |
|---|---|---|
| `KBottomNavBar` | 02, 04, 05, 07, 09 | 5 separadores com ícone + rótulo; ativo = ícone e rótulo laranja (sem pílula, como no Figma v2); QR = círculo laranja 52 dp com sombra laranja ao centro, rótulo "QR" por baixo; QR desativado = círculo `areia300`, ícone branco esbatido (09) |
| `KIconButton` / `KBackButton` | 02, 03, 04, 05, 06, 09, 10 | quadrado visível 40 dp (alvo 48), branco, raio 12, borda `areia200`; voltar com nome acessível "Voltar"; `mostrarPonto` para o sino (02); `contorno: false` sobre o cabeçalho laranja (03) |
| `KTopBar` | 04, 05, 06, 09, 10 | voltar + título (Sora 700 20, cabeçalho) + `acao` opcional (`KIconButton` "⋯"); vai no topo do `body` dentro de `SafeArea`, não em `Scaffold.appBar` |
| `KPrimaryButton` / `KSecondaryButton` / `KTextLink` | todas | primário 52 dp laranja; secundário contorno laranja fundo branco; terciário texto laranja; estados premido/desativado/a carregar |
| `KTextField` | 01, 10 | rótulo por cima, 52 dp, ícone à esquerda, texto de ajuda por baixo |
| `KSearchField` | 02 | pílula, ícone lupa laranja, placeholder "Que serviço precisa hoje?" |
| `KChip` (filtro / etiqueta / informativo) + `KSegmentedControl` | 01, 03, 04, 06, 07 | pílula 32 dp (alvo 48); normal = contorno `areia400` fundo branco; filtro selecionado = Ébano; etiqueta selecionada = laranja (sem "✓", como no Figma v2); informativo (03) não clicável; segmentado fundo `areia100` com opção ativa branca a negrito |
| `KStatusBadge` | 03, 04, 07 | pílula (como a imagem), Sora 700 12 MAIÚSCULAS, `compacta` 11 no 07, sem ícone (exceto VERIFICADO); `.estado(EstadoPedido)`, `.propostas(n)`, `.verificado(sobreCor:)`: NOVO (tomClaro/brasa), N PROPOSTAS (Ébano/branco), EM CURSO (tomClaro/brasa), CONCLUÍDO (sucessoFundo/sucesso), CANCELADO (erroFundo/erro), VERIFICADO (sucessoFundo/sucesso + ícone escudo) |
| `KAvatar` | 02, 03, 04, 06, 08 | círculo `tomClaro` com iniciais Sora 800 cor `brasa` |
| `KCard` | todas | branco, raio 20, sombra nível 1, padding 16; `onTap` só se tiver um único destino; `destacado` = borda laranja sem sombra (04) |
| `KPriceText` | 03, 04, 07, 08 | Sora 800 via `KFormat.kz`; tamanhos `lista` 15 · `cartao` 20 · `destaque` 24 · `display` 32; anuncia "kwanzas" |
| `KRatingInline` | 02, 04 | estrela ouro + "4,8" bold + "(126)" neutro500 |
| `KCategoryTile` | 02 | quadrado 56 dp `tomClaro` raio 16 com ícone 24 Brasa + rótulo por baixo (12 sp); selecionada = fundo laranja ícone branco |
| `KInlineAlert` | 10 | erro / aviso / sucesso: fundo semântico, ícone + **negrito** + texto |
| `KEmptyState` | 09, Conversas, Perfil | círculo `tomClaro` 96 dp com ícone, título Sora 700, texto, botão secundário |
| `KStepProgress` | 10 | 4 barras horizontais; concluídas laranja, restantes `areia200` |
| `KisaluMark` | 01, 02 | pin com "K" (logótipo isolado). Desenhar com `CustomPainter` ou SVG em `assets/brand/` até haver o ficheiro original |
| `KFolha` / `mostrarKFolha` | 05, 07, 08 | folha inferior: fundo branco, raio 24, pega no topo, barreira Ébano ~40 %, scroll se não couber |
| `KLinhaChaveValor` | 07, 08 | "Profissional — Joaquim Manuel ✓"; `.preco` com Sora 800 para o valor |
| `KIncluiBox` | 04, 08 | caixa `areia50` raio 10 com "**Inclui:** …" e aviso "Material não incluído." a `erro` |
| `KEstrelas` | 03, 06 | 5 estrelas: leitura (pequenas) ou escolha (48 dp, 8 dp de intervalo); "N de 5 estrelas" |
| `KSecaoTitulo` | 02, 03 | Título 2 + ligação "Ver todos" ou acessório (chip "Mapa") |
| `KLinhaIcone` | 04, 10 | ícone laranja + texto ("Talatona", "Hoje, 16:00") |
| `KSkeleton` / `KSkeletonLista` | todas com dados | esqueletos `areia200` do estado "a carregar" |
| `KEstadoBuilder` | todas com dados | desenha `EstadoUi`: esqueletos, sucesso, vazio, erro com "Tentar outra vez", não encontrado |
| `mostrarKSnack` | 01, 02, 06, 08, 10 | SnackBar com ação opcional ("Desfazer") |

---

<a id="ecra-01"></a>
## 01 · Login / Registo

**Corrige:** P01, P02 (SMS em vez de palavra-passe), P20 (ajuda).

Layout (de cima para baixo):
1. **Cabeçalho laranja** (≈ 40 % superior) fundo `laranja` com círculos decorativos mais claros (laranja ligeiramente mais claro, grandes, cortados nas bordas). Barra de estado clara.
   - `KisaluMark` branca (≈ 56 × 64 dp), alinhada à margem esquerda.
   - "Kisalu Express" — Sora 800 ~30 sp, branco.
   - "Quem sabe, resolve." — DM Sans 16, branco 85 %.
2. **Folha clara** (fundo `areia50`, cantos superiores raio 24) que sobrepõe o cabeçalho:
   - "Entrar ou criar conta" — Título 2.
   - Controlo segmentado (fundo `areia100`, raio 14): **"Sou cliente"** (selecionado: fundo branco, bold) · "Sou profissional".
   - Rótulo "Telemóvel" + campo com ícone telefone e valor "+244 923 000 000".
   - Ajuda: "Enviamos um código por SMS: sem palavra-passe." (bodyMedium, neutro700).
   - Botão primário **"Receber código SMS"**.
   - Botão secundário **"Criar conta"**.
   - "Ao continuar aceita os Termos e a Política de Privacidade (RGPD)." centrado, legenda.
   - Ligação "Precisa de ajuda? Fale connosco" (laranja, bold, alinhada à esquerda).

Interações (estáticas): o segmentado escolhe o perfil (Sou cliente / Sou profissional); "Receber código SMS" e "Criar conta" validam o telemóvel, pedem o código e abrem o ecrã 11 (`push(AppRoutes.codigoSms)`); "Criar conta" só difere no destino depois do código (profissional → 12); ajuda → SnackBar "Em breve".
Acessibilidade: campo com `TextInputType.phone`; rótulo visível (não usar só placeholder).

<a id="ecra-02"></a>
## 02 · Início — Pesquisa de biscateiros

**Corrige:** P03 (QR com rótulo), P05 (ponto no sino), P06 (banner fechável).

1. Cabeçalho: "Boa tarde, Maria" (Título 1) · por baixo ícone localização laranja + "Talatona, Luanda" (bodyMedium). À direita botão sino (quadrado branco raio 14, 48 dp) com **ponto vermelho** (`erro`) de novidades. Saudação muda com a hora (Bom dia / Boa tarde / Boa noite) — opcional.
2. `KSearchField` "Que serviço precisa hoje?".
3. **Banner** Ébano, raio 16: etiqueta amarela (fundo `ouro`, texto Ébano) "CONFIRMAÇÃO POR QR"; texto branco bold "Pague só quando o / trabalho estiver feito."; `KisaluMark` laranja vivo à direita; botão ✕ (fechar) no canto superior direito → esconde o banner (estado local).
4. Secção "Serviços" (Título 2) + "Ver todos" (laranja, bold) à direita → `/categorias` (21).
5. Grelha 4 × 2 de `KCategoryTile`: Eletricista, **Canalizador (selecionado)**, Mecânico, Pedreiro, Ar cond., Cabeleireira, Pintor, Limpeza.
6. Secção "Perto de si" + chip contorno "📍 Mapa" à direita → `/mapa` (22).
7. Lista de cartões de profissional: `KAvatar` "JM" · "Joaquim Manuel" (Título 3) + ícone verificado verde · "Canalizador · 1,2 km" · "★ 4,8 (126)" · botão pequeno "Ver" (fundo `tomClaro`, texto `brasa`, pílula). Segundo cartão: Ana Cardoso (scroll).
8. `KBottomNavBar` (Início ativo).

Interações: categoria / pesquisa → `push(AppRoutes.novoPedido)`; "Ver" e cartão → `push(AppRoutes.profissional('p1'))`; sino → SnackBar.

<a id="ecra-03"></a>
## 03 · Perfil do profissional

**Corrige:** P07 (trabalhos feitos), P08 ("mão de obra desde").

1. Cabeçalho laranja (≈ 180 dp) com `KBackButton` (branco) à esquerda e badge **VERIFICADO** (branco com texto/ícone verde) à direita.
2. Cartão branco sobreposto ao cabeçalho, centrado: `KAvatar` grande (≈ 80 dp) "JM"; "Joaquim Manuel" (Título 2); "Canalizador · Talatona, Luanda" (bodyMedium neutro700); três métricas em linha: **4,8** Avaliação · **126** Serviços · **6 anos** Experiência (números Sora 700 laranja, rótulos legenda).
3. "Especialidades" (Título 2) + chips contorno: Fugas de água · Esquentadores · Desentupimentos · Loiças sanitárias.
4. "Trabalhos feitos" + "Ver todos (41)" laranja · 3 miniaturas (raio 12, gradiente areia como placeholder de foto) com legenda sobreposta: Antes/depois · Esquentador · Loiça sanitária · legenda "Fotos de serviços confirmados por QR na Kisalu".
5. "Avaliações recentes": cartões com avatar "MS", "Maria S.", 5 estrelas ouro, comentário "Chegou a horas e resolveu a fuga em 40 min. Recomendo!" (+ "Pedro K.").
6. **Barra inferior fixa** (branca, sombra para cima): à esquerda "mão de obra desde" (legenda) + **"8.000 Kz"** (Sora 800); à direita botão primário **"Pedir serviço"** (≈ 60 % da largura).

Interações: voltar → `pop`; "Pedir serviço" → `push(AppRoutes.novoPedido)`.

<a id="ecra-04"></a>
## 04 · Pedido e propostas

**Corrige:** P09 (cartões iguais), P11 (ordenação), P12 (menu ⋯).

1. `KTopBar`: voltar · "O meu pedido" · botão "⋯" → menu com **Editar pedido** e **Cancelar pedido** (cancelar abre diálogo de confirmação: "Cancelar este pedido? Os 3 profissionais que enviaram proposta vão ser avisados.").
2. Cartão do pedido: badges **NOVO** + **3 PROPOSTAS**; "Fuga de água na cozinha" (Título 2); "Cano a pingar debaixo do lava-loiça. Precisa de reparação hoje."; linha com ícone local "Talatona" e ícone calendário "Hoje, 16:00"; **mapa estático** (placeholder: retângulo `areia100` com grelha de ruas `areia200` e pin `KisaluMark` laranja) raio 12.
3. "Propostas recebidas" (Título 2) + chips de ordenação: **"Preço ↑" (selecionado, Ébano)** · "Avaliação" · "Chegada". Ordenar a lista localmente.
4. Cartões de proposta (todos iguais): `KAvatar` · nome como na imagem: "Joaquim M." no primeiro, "Rui Santos" no segundo (`Proposta.nomeVisivel`) · "★ 4,8 · chega em 40 min" · preço à direita "12.500 Kz" · caixa `areia50` raio 10 "**Inclui:** mão de obra · material · deslocação" · botão primário **"Ver e aceitar"**. O cartão selecionado/primeiro tem **borda laranja 1,5 dp**. O terceiro cartão não aparece na imagem. Se o material não está incluído, mostrar "Material não incluído." em `erro` (ver Style Guide, cartão Rui Santos).
5. `KBottomNavBar` (Pedidos ativo).

Interações: "Ver e aceitar" → abre a folha **08**; tocar no nome/avatar → `push(AppRoutes.profissional(id))`.

<a id="ecra-05"></a>
## 05 · Confirmação por QR Code

**Corrige:** P03, P13 (código numérico), P14 (reportar problema), P20 ("Como funciona?").

1. `KTopBar`: voltar · "Confirmar serviço".
2. Texto: "Mostre o código só quando o trabalho estiver concluído e verificado." (bodyLarge neutro700).
3. Cartão branco centrado:
   - QR (≈ 160 dp, `qr_flutter`; o conteúdo é o **token opaco** devolvido pelo repositório (`CodigoConfirmacao.token`), tratado como texto sem significado: nunca o id do pedido, o código numérico, o valor nem um URL — ver `docs/frontend/SEGURANCA.md`) dentro de moldura branca com **borda laranja 2 dp raio 16**; logótipo `KisaluMark` pequeno ao centro.
   - "Joaquim Manuel" (Título 3) · "Canalizador · 12.500 Kz" (bodyMedium neutro700).
   - Caixa `areia50`: "Se a leitura falhar, diga este código:" (legenda) + **"482 173"** (Sora 800 ~28, espaçamento largo).
   - `Semantics(label: 'Código QR para confirmar o serviço de 12.500 Kz')`.
4. Linha com duas ligações: **"O trabalho tem um problema?"** (cor `erro`, bold, esquerda) · **"Como funciona?"** (laranja, direita).
5. Cartão com 3 passos numerados (círculo `tomClaro` com número `brasa`): "O profissional lê o código" · "Confirma o valor combinado" · "Avalie o serviço e a experiência".
6. `KBottomNavBar` (QR ativo).

Interações: "O trabalho tem um problema?" → bottom sheet simples "Conte-nos o que aconteceu. Tem 7 dias." (texto + botão "Enviar"); "Como funciona?" → bottom sheet com os 3 passos; (demo) tocar no QR → `push(AppRoutes.avaliar('ped1'))`.

<a id="ecra-06"></a>
## 06 · Avaliação do serviço

**Corrige:** P15 (comprovativo), P16 (estrelas 48 dp), P17 (avaliar mais tarde).

1. `KTopBar`: voltar · "Avaliar serviço".
2. Círculo `sucessoFundo` (≈ 72 dp) com ícone check verde.
3. "Serviço confirmado" (Título 2, centrado) · "Fuga de água na cozinha · 12.500 Kz" (bodyMedium) · ligação "Comprovativo guardado em Pedidos · Ver" (laranja, bold, legenda).
4. Cartão: `KAvatar` "JM" + "Como correu com o Joaquim?" (Título 3); **5 estrelas de 48 × 48 dp, 8 dp de intervalo** (4 preenchidas `ouro`, 1 `areia300`); "Muito bom" (laranja, bold). Escala: 1 Mau · 2 Fraco · 3 Razoável · 4 Muito bom · 5 Excelente. Semântica "4 de 5 estrelas".
5. "O que correu bem?" (Título 3) + chips multisseleção: **Pontual**, **Preço justo**, Simpático, **Trabalho limpo**, Rápido (selecionados = laranja/branco).
6. Área de texto (raio 14, 3+ linhas): "Resolveu tudo em 40 minutos. Voltaria a chamar."
7. Botão primário **"Enviar avaliação"** + ligação **"Avaliar mais tarde"** por baixo.

Interações: estrelas e chips interativos (estado local num controller); enviar → SnackBar "Avaliação enviada. Obrigado!" e `go(AppRoutes.pedidos)`; mais tarde → `go(AppRoutes.pedidos)`.

<a id="ecra-07"></a>
## 07 · Histórico de pedidos

**Corrige:** P18 (termos fixos), P19 ("Pedir de novo").

1. "Os seus pedidos" (Título 1).
2. Chips de filtro com scroll horizontal: **Todos (selecionado, Ébano)** · Em curso · Concluídos · Cancelados. Filtrar a lista localmente.
3. Cartões (um por pedido): ícone da categoria em quadrado `tomClaro` raio 12 · título (Título 3) · "Joaquim M. · Hoje" (bodyMedium) · à direita preço (Sora 700) + `KStatusBadge`.
   - Fuga de água · Joaquim M. · Hoje · 12.500 Kz · **EM CURSO**
   - Tomada sem luz · Carlos D. · 24 set · 6.000 Kz · **CONCLUÍDO** — com rodapé no cartão: "↻ Pedir de novo" (esquerda) · "Ver comprovativo" (direita), ambos laranja bold
   - Limpeza de AC · Nuno F. · 12 set · 9.500 Kz · CONCLUÍDO
   - Pastilhas de travão · Hélder T. · 3 set · 15.000 Kz · **CANCELADO**
   - Tranças · Ana C. · 28 ago · 20.000 Kz · CONCLUÍDO
4. `KBottomNavBar` (Pedidos ativo).

Interações: cartão "Em curso" → `go(AppRoutes.pedido('ped1'))`; "Pedir de novo" → `push(AppRoutes.novoPedido)`; "Ver comprovativo" → bottom sheet com o comprovativo (Style Guide, cartão "Serviço confirmado": valor, Profissional, Serviço, Data, Pagamento, Código KX-482173, "Partilhar" / "Reportar problema").

<a id="ecra-08"></a>
## 08 · Confirmar proposta (bottom sheet sobre a 04)

**Corrige:** P10 (aceitar sem confirmação). RNF08, RNF10.

`showModalBottomSheet` com o ecrã 04 escurecido por trás (barrier Ébano ~40 %). Folha branca, raio 24, pega no topo.
1. "Confirmar a proposta?" (Título 2).
2. "O Joaquim só recebe a sua morada e o seu contacto depois de confirmar." (bodyMedium).
3. Linhas chave/valor: "Profissional" — **"Joaquim Manuel ✓"**; "Valor fechado" — **"12.500 Kz"** (Sora 800 ~24).
4. Caixa `areia50`: "**Inclui:** mão de obra · material (sifão e vedante) · deslocação".
5. "Chegada prevista" — **"Hoje, 15h40"**.
6. Botão primário **"Confirmar proposta"** + ligação **"Voltar às propostas"**.

Interações: confirmar → fecha a folha, SnackBar "Proposta aceite. O Joaquim já foi avisado." com ação "Desfazer", e navega para `/qr`; voltar → fecha a folha.

<a id="ecra-09"></a>
## 09 · QR sem serviço em curso

**Corrige:** P04.

Mesmo ficheiro da 05, quando `servicoEmCurso()` devolve `null` (ou `/qr?vazio=1`).
1. `KTopBar`: voltar · "Confirmar serviço".
2. `KEmptyState` centrado verticalmente: círculo `tomClaro` 96 dp com ícone QR laranja; "Ainda não tem serviços / para confirmar" (Título 2 centrado); "Quando aceitar uma proposta, o código QR do serviço aparece aqui." (bodyMedium centrado); botão secundário **"Ver os meus pedidos"** → `go(AppRoutes.pedidos)`.
3. `KBottomNavBar` com **QR desativado** (círculo `areia300`).

<a id="ecra-10"></a>
## 10 · Novo pedido sem rede

**Corrige:** P21 (estados sem rede). RM03, RNF07.

O fluxo "Novo pedido" tem 4 passos (UF1: descrição + foto → morada + referência → data/urgência → rever). **No Figma só existe o passo 3/4 "Rever o pedido" em estado sem rede** — implementar esse com fidelidade; os outros passos são extras (milestone M3) e seguem o Style Guide.
1. `KTopBar`: voltar · "Novo pedido".
2. `KStepProgress` (3 de 4 barras laranja).
3. "Passo 3 de 4 · Rever o pedido" (legenda neutro500).
4. "Fuga de água na cozinha" (Título 2).
5. `KInlineAlert` erro: ícone aviso · "**Sem ligação.** O seu pedido ficou guardado como rascunho e vamos tentar enviar outra vez automaticamente."
6. Cartão branco com 3 linhas ícone + texto: 📍 "Talatona · perto da cantina do Sr. Zé" · 📅 "Hoje, o mais cedo possível" · 📷 "1 foto anexada" (usar `KIcons`, não emoji).
7. No fundo: botão primário **desativado** "A aguardar rede…" + ligação **"Tentar outra vez"**.

Interações: "Tentar outra vez" → simula 1 s de carregamento e volta ao mesmo estado (é estático); voltar → `pop`.
Estado alternativo (com rede): mesmo layout sem alerta e botão ativo **"Publicar pedido"** → SnackBar "Pedido publicado. Já avisámos 8 canalizadores perto de si." e `go(AppRoutes.pedido('ped1'))`.

<a id="ecra-11"></a>
## 11 · Código SMS

**Corrige:** RF01 (faltava o ecrã do código). Dados: o pedido de código em curso vive no repositório
(`codigoSmsPendente`), nunca na rota nem em `extra` (SEGURANCA.md).

1. `KTopBar`: voltar · "Confirmar número".
2. "Introduza o código" (Sora 24) · "Enviámos um código de 6 dígitos para +244 923 000 000." (16 sp, neutro700).
3. **6 caixas** de 50 × 60 dp, raio 14, borda `areia300`, espaço 10 dp; dígitos Sora 24. Figma: "4 8 2 1 7" escritos e a 6.ª com borda laranja 2 dp (foco). Campo de texto invisível por baixo (só dígitos, máximo 6, teclado numérico). Erro em linha, com ícone, por baixo das caixas.
4. Relógio + "Reenviar código em 0:42" (contagem decrescente simulada; a 0:00 passa a ligação "Reenviar código").
5. Fundo: botão primário **"Confirmar"** · ligação **"Alterar número"**.

Interações: "Confirmar" valida o formato (`KValidators.codigoSms`) e chama `validarCodigoSms`; `000000` falha com "O código não está certo. Confirme o SMS e tente outra vez.". Depois de confirmar a sessão passa ao perfil escolhido no Login: cliente → `/inicio`; profissional que **entrou** → `/inicio` em modo profissional; profissional que **criou conta** → `/registo-profissional`. "Alterar número" e voltar → Login.

<a id="ecra-12"></a>
## 12 · Criar perfil (profissional, passo 1 de 2)

1. `KTopBar`: voltar · "Criar perfil". `KStepProgress` 1 de 3 · "O seu perfil".
2. `KAvatar` 64 dp "JM" + "Fotografia de perfil" (bold) + ligação "Adicionar fotografia" (simulada: "Em breve").
3. "Nome completo" · "Joaquim Manuel".
4. "Que serviços presta?" · chips de multisseleção **Canalizador** e **Pedreiro** (selecionados), Eletricista, Pintor, **"Mais…"** (abre os 13 serviços e desaparece).
5. "Anos de experiência" · "10" (só números, 0 a 60).
6. "Zona de atuação" · ícone localização + "Viana, Luanda".
7. "Raio de deslocação" · "10 km" (laranja, bold) · cursor de 1 a 30 km.
8. Botão primário **"Continuar"**.

Interações: "Continuar" valida (`KValidators.nomeCompleto`, `servicosPrestados`, `anosExperiencia`, `zonaAtuacao`), guarda o registo (`guardarRegistoProfissional`, que passa a sessão a profissional) e abre o 13. O erro de cada campo aparece ao sair do campo ou ao continuar.

<a id="ecra-13"></a>
## 13 · Verificar identidade (passo 2 de 2)

1. `KTopBar`: voltar · "Verificar identidade". `KStepProgress` 2 de 3 · "Selo Verificado".
2. Caixa `sucessoFundo` com escudo: "Com o selo Verificado, os clientes sabem quem entra em casa deles."
3. Cartão: **"Documento de identidade"** · "Frente e verso" · `ENVIADO` (verde) / **"Fotografia do rosto"** · "Para comparar com o documento" · `FALTA` (tom claro).
4. Cadeado + "Usamos estes dados só para verificar a identidade. O documento não é mostrado a clientes."
5. Botão primário **"Enviar para verificação"** · ligação **"Fazer mais tarde"**.

Interações: tocar na linha do rosto simula a fotografia (passa a `ENVIADO`); "Enviar para verificação" sem o rosto avisa "Falta a fotografia do rosto. Adicione-a para enviar."; com os dois vai ao Início com o aviso "Enviado para verificação."; "Fazer mais tarde" vai ao Início.

<a id="ecra-14"></a>
## 14 · Início do profissional

Vive dentro do `AppShell` (barra com Início ativo), escolhido por `PorPerfil` quando o perfil ativo é profissional.

1. "Boa tarde, Joaquim" (Sora 24) · pin + "Viana · até 10 km".
2. Cartão Ébano: **"Disponível para trabalhar"** + "Está a receber pedidos da sua zona." + interruptor laranja (em memória; desligado mostra "Não está a receber pedidos.").
3. Três cartões: **3** "Pedidos novos" · **4,8** "Avaliação" · **126** "Serviços" (número laranja).
4. "Pedidos perto de si" · "Ver todos" ("Em breve").
5. Cartões: ícone da categoria · "Fuga de água na cozinha" · "Talatona · 3,4 km · Hoje, 16:00" · `NOVO` · "Ver pedido" / "Reparar muro do quintal" · "Viana · 1,8 km · Amanhã, 9:00" · "há 22 min" · "Ver pedido".

Privacidade (RNF10): o pedido só mostra zona e distância, nunca a morada nem o contacto do cliente. "Ver pedido" → `/enviar-proposta/:pedidoId`.

<a id="ecra-15"></a>
## 15 · Enviar proposta

1. `KTopBar`: voltar · "Enviar proposta".
2. Cartão do pedido: "Fuga de água na cozinha" · "Cano a pingar debaixo do lava-loiça. Precisa de reparação hoje." · pin "Talatona · 3,4 km" · calendário "Hoje, 16:00".
3. "O que inclui o preço?" · cartão com **Mão de obra 8.000 Kz · Material 3.500 Kz · Deslocação 1.000 Kz**. Cada valor é um campo editável (só dígitos, pontos e espaços; fica formatado ao sair; 0 permitido).
4. "Quando pode chegar?" · chips **40 min** (selecionado, Ébano) · 1 h · 2 h · "Hoje, 16:00" (hora pedida pelo cliente).
5. Fundo: "Valor fechado" · **12.500 Kz** (soma calculada, nunca escrita) · botão primário **"Enviar proposta"**.

Interações: "Enviar proposta" valida cada componente (`KValidators.componenteKz`: "Escreva o valor de mão de obra. Se não cobra, escreva 0.") e o total (`valorKz`, mínimo 500 Kz), chama `enviarProposta`, mostra "Proposta enviada. O cliente já a pode ver." e volta ao Início.

<a id="ecra-16"></a>
## 16 · Confirmar serviço (ler o QR do cliente)

Separador QR em modo profissional. Fundo Ébano, **sem câmara** (nenhum pacote de câmara, RM03): o visor é desenho.

1. `KTopBar` escura: voltar · "Confirmar serviço" (branco).
2. "Peça ao cliente o código de 6 dígitos que aparece no ecrã dele." · visor 248 dp com quatro cantos laranja vivo e linha de leitura. (No Figma: "Aponte a câmara para o código do cliente."; mudou no QA porque não há leitor de QR.)
3. Cartão `areia50`: **"Código de confirmação"** (no Figma: "A câmara não funciona?") · "Código do cliente" · campo "482 173" · botão primário **"Confirmar serviço"**.

Interações: valida o formato (`KValidators.codigoConfirmacao`) e chama `confirmarServicoComCodigo`. Qualquer código de 6 dígitos confirma, exceto `000000` ("O código não está certo. Confirme com o cliente."). Sucesso → `/servico-confirmado/tp1`. Voltar → Início.

<a id="ecra-17"></a>
## 17 · Serviço confirmado (profissional)

1. `KTopBar`: voltar · "Serviço confirmado".
2. Círculo `sucessoFundo` 72 dp com check · **"Trabalho concluído"** (Sora 22) · "Maria K. confirmou o valor combinado."
3. Cartão: Serviço **Fuga de água na cozinha** · Valor recebido **12.500 Kz** · Data **Hoje, 15:52**.
4. Caixa tom claro com câmara: "Mostre este trabalho no seu perfil" · "Os clientes escolhem primeiro quem mostra fotos de trabalhos feitos."
5. Botão primário **"+ Adicionar fotos"** (simulado: "Fotos adicionadas ao seu perfil.") · ligação **"Voltar ao Início"**.

<a id="ecra-18"></a>
## 18 · Conversas

Separador Conversas. Lista com `ListView.builder` num cartão: avatar · nome · última mensagem · hora (hoje) ou data · círculo laranja com o número de mensagens por ler.

- **Joaquim Manuel** · "Chego às 15h40, como combinado." · 15:02 · `2` (mensagem em negrito)
- **Carlos Dias** · "Obrigado pela preferência!" · 24 set
- **Nuno Ferreira** · "O filtro já está limpo." · 12 set

Tocar numa linha → `/conversas/:id`. Sem conversas mantém o estado vazio "Ainda não tem conversas" (`KEstadoVazioCentrado`).

<a id="ecra-19"></a>
## 19 · Conversa do pedido

1. `KTopBar`: voltar · nome ("Joaquim Manuel").
2. Faixa `areia100`: ícone da categoria + "Fuga de água na cozinha · 12.500 Kz".
3. Mensagens: as minhas à direita (laranja, texto branco), as do outro à esquerda (branco com contorno), hora por baixo. "Boa tarde. Já tem o sifão para a reparação?" 14:51 · "Boa tarde, Maria. Sim, levo o sifão e o vedante." 14:53 · "Chego às 15h40, como combinado." 15:02.
4. Barra: botão da câmara (48 dp) · campo "Escreva uma mensagem" · botão enviar laranja.

Interações: enviar acrescenta a mensagem em memória (hora do repositório); campo vazio não envia; o campo limita a 1.000 caracteres (VALIDACOES.md); a câmara mostra "Em breve". Abrir a conversa marca as mensagens como lidas.

<a id="ecra-20"></a>
## 20 · Perfil

Separador Perfil.

1. "Perfil" · cartão: `KAvatar` "MK" · **Maria Kiala** · **+244 923 *** 000** (mascarado) · "Talatona, Luanda".
2. Cartão de linhas (ícone em quadrado tom claro + seta; linhas de 64 dp): Os meus dados · Moradas guardadas ("2 moradas") · Profissionais favoritos ("3") · Notificações · Ajuda e apoio · Privacidade e dados. Cada uma mostra "Em breve".
3. Cartão Ébano **"Também presta serviços? Mudar para profissional"** (em modo profissional: "Quer pedir serviços? Mudar para cliente"). Alterna o perfil ativo e vai ao Início.
4. Ligação destrutiva **"Terminar sessão"** → `terminarSessao` e `go(AppRoutes.login)`.

<a id="ecra-21"></a>
## 21 · Todos os serviços

Aberto por "Ver todos" no Início.

1. `KTopBar`: voltar · "Todos os serviços".
2. Pesquisa "Procurar um serviço" (filtra localmente, sem distinguir maiúsculas nem acentos; sem resultados: "Sem resultados").
3. `GridView.builder` de 4 colunas com as 13 categorias, na ordem do Style Guide, margens de 24 dp. Tocar numa abre `/novo-pedido?novo=1`.

<a id="ecra-22"></a>
## 22 · Mapa "Perto de si"

Aberto pelo chip "Mapa" no Início. Mapa **estático** desenhado com `CustomPaint` (sem pacotes de mapas): quarteirões `areia100`, ruas brancas de 10 dp, ponto verde de posição.

1. `KTopBar` com título centrado "Perto de si" · chip **"Lista"** (volta).
2. Pins com o logótipo `KisaluMark`: laranja o selecionado, cinzento os outros (alvo de 48 dp); tocar muda o cartão.
3. Cartão em baixo (`KCartaoProfissional`): "Joaquim Manuel" · "Canalizador · 1,2 km" · "4,8 (126)" · "Ver" → `/profissional/:id`.

## Correções v3.1 (avaliação heurística dos ecrãs 11–22)

A avaliação está em `build/v3/avaliacao-heuristica-v3.md` (fora deste repositório). Onde este ficheiro
e a lista abaixo não coincidem, vale a lista.

| ID | Ecrã | O que mudou na app |
|---|---|---|
| V01 | 12, 13 | Registo em **2 passos**: "Passo 1 de 2 · O seu perfil", "Passo 2 de 2 · Selo Verificado", barra de 2 segmentos. |
| V02 | 13 | "Enviar para verificação" **desativado** até haver as duas fotografias, com "Falta a fotografia do rosto para poder enviar." por cima. |
| V03 | 13 | "Frente e verso · **Alterar**" e, no rosto, "**Toque para tirar a fotografia**" a laranja. |
| V04 | 15 | Valores com contorno `areia400` e lápis. |
| V05 | 16 | Linha "Fuga de água na cozinha · Maria K. · 12.500 Kz" por baixo da instrução. |
| V06 | 11 | "Confirmar" desativado até aos 6 dígitos. |
| V07 | 11b | Código errado: caixas a vermelho e "O código não está certo. Confirme o SMS e tente outra vez." |
| V08 | 11 | "O código preenche-se sozinho quando o SMS chegar." |
| V09 | 12 | Serviços selecionados a **Ébano** (chip de filtro). |
| V10 | 12 | Cursor de 24 dp e limites "1 km" / "30 km". |
| V11 | 14 | Sino com ponto de novidades (há pedidos novos). |
| V12 | 15 | "O cliente vê o total e o que inclui. Depois de aceite, o valor fechado não muda." por cima do total. |
| V13 | 17 | Sem seta de voltar; só "Voltar ao Início". |
| V14 | 17 | "Valor **combinado**". |
| V15 | 19 | Botão de ligar no topo. |
| V16 | 19 | "14:51 · Lida" nas minhas mensagens já lidas. |
| V17 | 20 | "Notificações" com ícone de sino. |
| V18 | 20b | "Terminar sessão" abre a folha "Terminar sessão?" / "Para voltar a entrar, recebe um novo código por SMS." / **Terminar sessão** / Cancelar. |
| V19 | 21 | "Ar condicionado" por extenso (na grelha, uma palavra por linha). |
| V20 | 21 | "Não encontra o serviço?" / "**Descreva o que precisa**" → novo pedido. |
| V21 | 22 | Legenda "Está aqui" junto ao ponto verde e botão de localização por cima do cartão. |
| V22 | 22 | "Ver perfil" e "· Verificado" em texto. |
| V23 | 11–13 (e chips/campos) | Contornos de campos e chips em `areia400`; "ENVIADO" verde sobre branco com contorno. |
| V24 | vários | Número numa linha própria (11), "Fotografia de perfil (opcional)" (12), "NOVO · há 5 min" (14), "Hora pedida, 16:00" (15), enviar desativado sem texto e seta na faixa do pedido (19), "3 guardados" e cartão em duas linhas (20), título do mapa à esquerda (22). |
| V30 | barra | Separadores de largura fixa: o botão QR já não muda de sítio. |

---

## Ecrãs e ações acrescentados depois do QA

Não estão no Figma. Vieram do relatório de QA e dos testes no browser com a API real (Entrega 2b). Seguem o Style Guide e só usam componentes `K*`; os textos são estes.

### Ecrãs novos

| Ecrã | Rota | Como chegar | Conteúdo |
|---|---|---|---|
| Notificações | `/notificacoes` | Sino dos ecrãs 02 e 14; Perfil → "Notificações" | Barra "Notificações" com voltar. Lista de cartões: ícone do sino em quadrado tom claro, título (Sora 600), texto, data curta ("Hoje", "24 set"); as que estavam por ler têm contorno laranja e a etiqueta **"NOVA"** (cor + texto). Ao abrir passam a lidas na API e o ponto vermelho do sino desaparece. Vazio: "Sem notificações" · "Quando receber propostas ou o profissional estiver a caminho, avisamos aqui." Puxar para baixo atualiza. |
| Ajuda | `/ajuda` | Login → "Precisa de ajuda? Fale connosco" (a API é pública); Perfil → "Ajuda e apoio" | Barra "Ajuda". "Perguntas frequentes" e um cartão com as perguntas, cada uma expansível (alvo 48 dp) com a resposta por baixo. Vazio: "Ainda não há perguntas" · "Volte mais tarde." |
| O trabalho (profissional) | `/trabalhos/:id` | Pedidos em modo profissional → tocar num trabalho | Cartão com estado ("EM CURSO") e etapa ("PROPOSTA ACEITE", "A CAMINHO", "TRABALHO COMEÇADO"), título, descrição e "Valor combinado". Cartão "Cliente": nome, telemóvel, botões **"Ligar"** ("Em breve": não há pacote de chamadas, RM03) e **"Conversa"**. Cartão "Onde é": morada, "Ponto de referência: …"; sem morada, "A morada exata aparece quando o cliente aceita a sua proposta." Ações: **"Estou a caminho"** (só antes de sair) e **"Comecei o trabalho"**, cada uma com confirmação ("Está a caminho?" / "Começou o trabalho?", "Agora não" · "Sim, avisar"); depois de começar: "Quando acabar, peça ao cliente o código de 6 dígitos." + **"Confirmar serviço"** (abre o 16). Trabalho concluído ou cancelado: sem ações. |

### Ações acrescentadas a ecrãs existentes

| Ecrã | O quê |
|---|---|
| 02, 07, 14, 18 | Ao voltar ao separador (ou a uma rota tapada) a lista volta a ler, sem esqueletos. Puxar para baixo também atualiza (`RefreshIndicator` laranja). O 04 e o 05/16 também releem ao voltar. |
| 02, 14 | O sino abre as Notificações; o ponto vermelho segue o número de notificações por ler. |
| 03 | Bloco **"Avaliações em números"** entre "Trabalhos feitos" e "Avaliações recentes" (estatística, Matemática Discreta; `kisalu-api/docs/MATEMATICA.md`). Cartão com "4,8 ± 0,6" (Sora 22) e a legenda "média ± desvio padrão"; "Entre 4,7 e 4,9 com 95% de confiança"; cinco barras horizontais de 5 a 1 estrelas (número + estrela ouro, barra ouro sobre areia, contagem a negrito ao lado; o leitor de ecrã ouve "5 estrelas: 108 avaliações"); "n = 126 avaliações" em legenda. Sem avaliações o bloco não aparece; com uma só, não há desvio nem intervalo. Se a estatística falhar, o resto do perfil mostra-se na mesma. |
| 04 | Em cada cartão de proposta, por baixo do nome e das estrelas, uma linha pequena **"Chega a tempo em ~85% dos casos"** (simulação de Monte Carlo com 10 000 viagens; percentagem arredondada a 5 %). A partir de 80 %: verde de sucesso com ícone de relógio; abaixo: cor de aviso com ícone de aviso (nunca só a cor). Não aparece em propostas "na hora pedida" nem sem GPS. A ordenação "Chegada" desempata pela mediana simulada da chegada. |
| 04 | Cada proposta tem **"Recusar"** (botão secundário) por baixo de "Ver e aceitar", com confirmação "Recusar esta proposta?" · "A proposta do Rui sai da lista e ele é avisado. Não é possível desfazer." · "Manter" / "Recusar". Depois: "Proposta recusada." (a API não tem desfazer). |
| 04 | Com proposta aceite já não há "Ver e aceitar": aparece "Proposta aceite" com o cartão do profissional (selo **"ACEITE"** com visto, valor fechado, chegada, "Inclui"), **"Ver código QR"** (abre o QR desse pedido, `/qr?pedido=:id`), **"Conversa"** e, nos primeiros 5 minutos, "Desfazer aceitação (até 5 min)". O menu ⋯ deixa de ter "Editar pedido". |
| 04 → 10 | "Editar pedido" abre o formulário já preenchido (`/novo-pedido?editar=:id`), com o título "Editar pedido" e o botão "Guardar alterações"; grava com PATCH (não cria outro pedido) e volta ao 04 com "Pedido atualizado." |
| 08 | SnackBar depois de aceitar: "Proposta aceite. O Joaquim já foi avisado. Pode desfazer nos próximos 5 minutos." · "Desfazer". Fecha sozinho ao fim de 10 s e quando se sai do QR (não tapa a barra de escrita da conversa). A janela da API (5 min) continua no 04. |
| 05 | Enquanto o QR está aberto, a app pergunta à API de 5 em 5 s se o profissional já confirmou; quando sim, abre a avaliação (06). Tocar no QR só abre o 06 nos dados fictícios. |
| 07 | Pedidos concluídos e ainda não avaliados têm **"Avaliar"** (abre o 06); depois de avaliar a ação desaparece. "Pedir de novo" abre o novo pedido já preenchido com o pedido antigo (`/novo-pedido?de=:id`). No comprovativo, "Reportar problema" só aparece dentro da garantia de 7 dias e abre a folha "O trabalho tem um problema?" do ecrã 05; depois de enviar mostra "Problema enviado", a resposta da equipa e o contacto do profissional. Fora do prazo, a folha mostra o erro da API. |
| 10 | O rascunho do pedido novo fica guardado no aparelho a cada passo e quando não há rede (RM07); apaga-se ao publicar. |
| 16 | Texto por baixo do título: "Peça ao cliente o código de 6 dígitos que aparece no ecrã dele." (não há leitor de QR). Título do cartão: "Código de confirmação". Com mais do que um trabalho à espera: "Tem 2 trabalhos por confirmar. O código do cliente diz qual é." e uma linha por trabalho (serviço · cliente · valor). |
| 19 | Sem proposta aceite, a faixa do pedido mostra só o título (nunca "0 Kz"). |
| 20 | "Notificações" e "Ajuda e apoio" abrem os ecrãs novos. "Mudar para profissional" sem registo feito abre o registo (12). |
| Arranque | Com a API, a sessão fica guardada no aparelho: se o token ainda for válido, a app abre no Início do perfil ativo em vez do Login. |

---

## Mapa de navegação (protótipo estático)

```
/dev (galeria) ─┬─ /login ──Receber código SMS / Criar conta──▶ /codigo-sms (11)
                │
/codigo-sms ──Confirmar (cliente)──────────────────────────▶ /inicio (02)
            ──Confirmar (profissional que entra)───────────▶ /inicio em modo profissional (14)
            ──Confirmar (profissional + Criar conta)───────▶ /registo-profissional (12)
            ──Alterar número / voltar──────────────────────▶ /login
/registo-profissional (12) ──Continuar──▶ /verificar-identidade (13) ──Enviar / Fazer mais tarde──▶ /inicio (14)

/inicio (02) ──categoria/pesquisa──▶ /novo-pedido?novo=1 (passo 1)
   ├──Ver todos──▶ /categorias (21) ──categoria──▶ /novo-pedido?novo=1
   ├──chip Mapa──▶ /mapa (22) ──Ver──▶ /profissional/p1 · ──Lista──▶ volta
   └──Ver──▶ /profissional/p1 (03) ──Pedir serviço──▶ /novo-pedido?novo=1
/dev ──ecrã 10──▶ /novo-pedido (retoma o rascunho: passo 3 sem rede)
/pedidos (07) ──Em curso──▶ /pedidos/ped1 (04) ──Ver e aceitar──▶ folha 08 ──Confirmar──▶ /qr?pedido=ped1 (05)
/pedidos/ped1 (04, aceite) ──Ver código QR──▶ /qr?pedido=ped1 · ──Editar pedido──▶ /novo-pedido?editar=ped1
/pedidos (07) ──Avaliar──▶ /pedidos/ped2/avaliar (06) · ──Pedir de novo──▶ /novo-pedido?de=ped2
/qr (05) ──profissional confirma (verificação de 5 em 5 s) ou toque no QR, só demo──▶ /pedidos/ped1/avaliar (06) ──Enviar──▶ /pedidos
/inicio (02, 14) ──sino──▶ /notificacoes · /login e /perfil ──Ajuda──▶ /ajuda
/qr sem serviço (09) ──Ver os meus pedidos──▶ /pedidos
/conversas (18) ──linha──▶ /conversas/c1 (19)
/perfil (20) ──Mudar para profissional──▶ /inicio (14) · ──Mudar para cliente──▶ /inicio (02) · ──Terminar sessão──▶ /login

Modo profissional (perfil ativo = profissional):
/inicio (14) ──Ver pedido──▶ /enviar-proposta/pp1 (15) ──Enviar proposta──▶ /inicio (14)
/qr (16) ──Confirmar serviço──▶ /servico-confirmado/tp1 (17) ──Voltar ao Início──▶ /inicio (14)
/pedidos mostra os trabalhos do profissional ──trabalho──▶ /trabalhos/tp1 ──Estou a caminho / Comecei o trabalho / Confirmar serviço──▶ /qr (16)
```
