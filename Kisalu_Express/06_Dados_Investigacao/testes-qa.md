# Testes e QA (2.ª entrega)

Resumo do controlo de qualidade feito ao protótipo alfa. Os testes usam apenas dados fictícios do `populate.sql`; não há dados pessoais nem respostas individuais do questionário neste documento.

## Metodologia

Três níveis de verificação, do mais pequeno ao mais completo:

1. **Testes automáticos da API** (Vitest): funções puras (estatística e Monte Carlo, com valores calculados à mão), validações, autenticação e regras de negócio.
2. **Testes automáticos da app** (`flutter test`): modelos, controladores, ecrãs (widget tests) e fluxos completos (do login até ao início, do pedido até à confirmação), com o `MockKisaluRepository`.
3. **QA ponta a ponta** contra a API real: um script percorre os fluxos de cliente e de profissional por HTTP, e os mesmos fluxos foram repetidos no browser com a app ligada ao servidor (`RestKisaluRepository`). Cada passo verifica o código HTTP, o corpo da resposta e o estado seguinte (por exemplo, depois de aceitar uma proposta o pedido passa a "em curso" e as outras propostas são recusadas).

Quando uma verificação falhava, corrigia-se o código, acrescentava-se um teste que a cobrisse e repetia-se a execução completa.

## Ambiente

| Componente | Detalhe |
|---|---|
| API | Node.js 20, Express 5, TypeScript, `npm run dev` |
| Base de dados | MySQL 8 em Docker Compose, recriada com `create.sql` e `populate.sql` antes de cada execução |
| App | Flutter, executada no browser (Chrome) com `--dart-define=KISALU_API=http://localhost:3000/api` |
| SMS | Simulado: o código vem em `codigo_dev` fora de produção |
| Dados | Fictícios (utilizadores de exemplo da Maria Kiala e do Joaquim Manuel, mais contas criadas durante o teste) |

## Números

| Nível | Resultado |
|---|---|
| Testes automáticos da API | 83 |
| Testes automáticos da app | 703 |
| Verificações ponta a ponta (API real) | 154, **0 falhas** |
| Cenário com dois serviços ativos em simultâneo | repetido à parte, sem falhas |
| Endpoints documentados | 82 |

## Cenários cobertos no ponta a ponta

| Cenário | O que se verifica |
|---|---|
| Cliente | Entrar por SMS, pesquisar, criar pedido, ver e aceitar propostas, mostrar o QR, comprovativo, avaliar, histórico, reclamação |
| Profissional | Entrar, ver pedidos perto, enviar proposta, ver o trabalho aceite, ler o QR e confirmar |
| Conversas, mapa, notificações, moradas e favoritos | Listagem, envio de mensagem, marcar como lida |
| Mudar de perfil e terminar sessão | O perfil ativo muda e o token deixa de servir após sair |
| Conta nova de profissional | Registo em três passos, documentos de identidade privados |
| Erros | 400 (dados inválidos), 401 (sem token), 404 (inexistente), JSON malformado, rota inexistente, CORS |

## Falhas encontradas e corrigidas

| # | Falha | Correção |
|---|---|---|
| 1 | Avaliar um serviço não tinha caminho com a API (só funcionava com dados simulados) | O ecrã do QR pergunta à API de 5 em 5 s se o serviço já foi confirmado e abre a avaliação; o histórico mostra "Avaliar" nos pedidos concluídos por avaliar |
| 2 | Com dois serviços ativos, a confirmação por QR escolhia o pedido errado | Novo `POST /pedidos/confirmar`, que procura entre os serviços ativos do profissional o que corresponde ao código; o ecrã 16 lista os trabalhos quando há mais do que um |
| 3 | Pedido novo não abria a partir da lista | Os pedidos NOVO passaram a abrir o ecrã 04 com as propostas |
| 4 | Listas desatualizadas ao voltar ao separador | Os ecrãs voltam a ler os dados ao regressar ao separador e têm puxar-para-atualizar |
| 5 | O aviso "Desfazer" ficava persistente no ecrã | Fecha ao fim de 10 s e ao sair do ecrã; o texto indica os 5 minutos para desfazer |
| 6 | Faltava recusar e editar pedido, reportar problema depois de confirmar, detalhe do trabalho para o profissional, notificações e ajuda | Acrescentados os ecrãs e os endpoints, com testes |
| 7 | A sessão não ficava guardada ao fechar a app | Token guardado com `flutter_secure_storage`; no arranque a app retoma a sessão |
| 8 | Eram aceites telemóveis estrangeiros | A API passou a aceitar só números angolanos (+244 e 9 dígitos começados por 9), como a app já fazia |
| 9 | Os documentos de identidade ficavam acessíveis publicamente | Gravados numa pasta privada fora de `/uploads`, servidos só a administradores |

Todas as correções foram repetidas e confirmadas no browser contra a API real.

## Matriz resumida de requisitos

| Área | Requisito | Verificado em |
|---|---|---|
| Autenticação | Entrada por código SMS, sessão mantida, perfil ativo | E2E, testes da API e da app |
| Pedidos | Criar, editar, cancelar, rascunho automático | E2E, testes da app |
| Propostas | Enviar, aceitar, recusar, alteração de preço com aprovação | E2E |
| Confirmação | QR Code, código numérico alternativo, comprovativo, garantia de 7 dias | E2E, cenário com dois serviços |
| Avaliações | Avaliação mútua, estatística e média bayesiana | E2E, testes de Matemática (valores à mão) |
| Chegada | Probabilidade de chegar a tempo (Monte Carlo) | Testes da API |
| Problemas | Reportar antes e depois de confirmar | E2E |
| Conversas e notificações | Listar, enviar, marcar como lida | E2E |
| Segurança e privacidade | Token JWT, documentos privados, validação de entrada | E2E (erros 400/401/404) |
| Câmara, push, GPS em tempo real, favoritos | Não implementados | 3.ª entrega |

## Limitações

Os testes não substituem os testes de usabilidade com utilizadores, previstos para a 3.ª entrega, nem validam a app num telemóvel físico. A leitura do QR com a câmara, as notificações push e o GPS ainda não estão integrados, por isso não foram testados.
