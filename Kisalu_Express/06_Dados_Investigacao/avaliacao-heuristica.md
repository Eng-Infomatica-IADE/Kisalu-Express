# Avaliação heurística

Avaliação dos sete ecrãs do protótipo v1 com as 11 heurísticas HMT (Rocha et al., 2014) e a escala de gravidade de 0 a 4 de Nielsen. Foram identificados 22 problemas, 7 deles graves. O protótipo v2 corrige todos e acrescenta 3 ecrãs.

## Heurísticas

| N.º | Heurística | v1 | Gravidade máx. | Problemas | v2 |
|---|---|---|---|---|---|
| 1 | Visibilidade do estado do sistema | Parcial | 2 | P05 · P15 | Sim |
| 2 | Relação com o mundo real | Parcial | 3 | P07 · P08 · P18 | Sim |
| 3 | Controlo e liberdade do utilizador | Não | 4 | P01 · P12 · P14 · P17 | Sim |
| 4 | Consistência e padrões | Parcial | 3 | P03 · P09 | Sim |
| 5 | Prevenção de erros | Não | 3 | P04 · P10 | Sim |
| 6 | Minimizar a carga de memória | Parcial | 2 | P02 | Sim |
| 7 | Personalização e atalhos | Não | 2 | P11 · P19 | Sim |
| 8 | Estética e design minimalista | Sim | 1 | P06 | Sim |
| 9 | Reconhecer, diagnosticar e recuperar de erros | Não | 3 | P13 · P21 | Sim |
| 10 | Ajuda e documentação | Não | 2 | P20 | Sim |
| 11 | Interação física e ergonomia | Parcial | 2 | P16 · P22 | Sim |

## Problemas e correções

| ID | Ecrã | Problema | HMT | Gravidade | Recomendação | Correção no v2 | Ecrã v2 |
|---|---|---|---|---|---|---|---|
| P01 | Entrar | Sem “Esqueci-me da palavra-passe” nem mostrar a palavra-passe. | 3 | 3 | Entrada com o número + código SMS (OTP). | Entrada com código SMS, sem palavra-passe. | 01 |
| P02 | Entrar | Palavra-passe a memorizar para quem usa pouco a app. | 6 | 2 | Login só com número + código; sessão mantida. | Campo removido; ajuda “Enviamos um código por SMS”. | 01 |
| P03 | Início | Botão central QR sem rótulo. | 4 | 3 | Rótulo “QR” e nome acessível. | Rótulo “QR” em todas as barras. | 02·04·05·07 |
| P04 | Início | QR sem estado definido sem serviço em curso. | 5 | 2 | Estado vazio com atalho para Pedidos. | Novo ecrã de estado vazio; QR desativado. | 09 |
| P05 | Início | Sino sem indicador de novidades. | 1 | 1 | Indicador no sino. | Ponto vermelho de novidades. | 02 |
| P06 | Início | Banner ocupa espaço antes das categorias. | 8 | 1 | Banner que se pode fechar. | Botão ✕ no banner. | 02 |
| P07 | Perfil | Sem fotos de trabalhos anteriores (fator nº1, 7/8). | 2 | 3 | Galeria “Trabalhos feitos”. | Secção “Trabalhos feitos” + “Ver todos (41)”. | 03 |
| P08 | Perfil | “desde 8.000 Kz” não diz o que inclui. | 2 | 2 | “Mão de obra desde…”. | “mão de obra desde 8.000 Kz”. | 03 |
| P09 | Propostas | Só a primeira proposta mostra “Aceitar”. | 4 | 2 | Cartões iguais. | “Inclui” + “Ver e aceitar” em todos. | 04 |
| P10 | Propostas | Aceitar sem resumo nem confirmação. | 5 | 3 | Folha de confirmação. | Folha “Confirmar a proposta?”. | 08 |
| P11 | Propostas | Não se pode ordenar as propostas. | 7 | 2 | Chips de ordenação. | Preço ↑ · Avaliação · Chegada. | 04 |
| P12 | Propostas | Sem editar ou cancelar o pedido. | 3 | 2 | Menu ⋯. | Menu ⋯ no cabeçalho. | 04 |
| P13 | QR | Sem alternativa se a câmara falhar. | 9 | 3 | Código numérico. | Código 482 173 sob o QR. | 05 |
| P14 | QR | Sem garantia nem reclamação antes de confirmar. | 3 | 4 | “O trabalho tem um problema?”. | Ligação de reclamação antes de confirmar. | 05 |
| P15 | QR | Sem comprovativo depois de confirmar. | 1 | 2 | Comprovativo partilhável. | “Comprovativo guardado · Ver”. | 06·07 |
| P16 | Avaliar | Estrelas pequenas (≈ 28 dp). | 11 | 2 | Alvos de 48 dp. | Estrelas de 48 dp, 8 dp de espaço. | 06 |
| P17 | Avaliar | Avaliar parece obrigatório. | 3 | 1 | “Avaliar mais tarde”. | Ligação “Avaliar mais tarde”. | 06 |
| P18 | Pedidos | Filtros abreviados e termos diferentes. | 2 | 1 | Termos fixos. | Concluídos · Cancelados. | 07 |
| P19 | Pedidos | Sem “Pedir de novo”. | 7 | 1 | Ação “Pedir de novo”. | “↻ Pedir de novo” e “Ver comprovativo”. | 07 |
| P20 | Todos | Sem ajuda nem contacto de apoio. | 10 | 2 | Ajuda contextual. | “Precisa de ajuda?” e “Como funciona?”. | 01·05 |
| P21 | Todos | Sem estados de erro, vazio ou sem rede. | 9 | 3 | Mensagens + rascunho + nova tentativa. | Novo ecrã sem rede com rascunho. | 10 |
| P22 | Todos | Legendas e texto secundário de 11–12 px. | 11 | 2 | Texto ≥ 12 / 16 sp; contraste AA. | Nenhum texto abaixo de 12 px. | todos |
