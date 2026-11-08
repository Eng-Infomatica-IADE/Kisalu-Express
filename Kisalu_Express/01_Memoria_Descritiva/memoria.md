# Memória Descritiva — Kisalu Express

> Documento vivo: versão da 2.ª entrega (novembro de 2026). As secções de Resultados e Reflexão serão completadas na entrega final.

## a. Identificação

| | |
|---|---|
| **i. Nome do projeto** | Kisalu Express |
| **ii. Ano letivo** | 2026/2027 |
| **iii. Semestre** | 3.º semestre |
| **iv. Unidades curriculares** | Projeto de Desenvolvimento Móvel; Programação de Dispositivos Móveis; Bases de Dados; Redes e Comunicação de Dados; Interfaces e Usabilidade; Matemática Discreta |
| **v. Docentes** | Fabio Guilherme (Projeto de Desenvolvimento Móvel); João Pedro Duarte Barros Monge (Programação de Dispositivos Móveis); Miguel Boavida (Bases de Dados); Nathan Campos e Pedro Rosa (Redes e Comunicação de Dados); Paula Neves (Interfaces e Usabilidade); André da Cunha Torcato e Ricardo Manuel Freitas de Sousa (Matemática Discreta) |

## b. Resumo

Em Angola, a maior parte dos serviços do dia-a-dia – reparar uma fuga de água, instalar uma tomada, rever um carro, fazer tranças ao domicílio – é prestada por trabalhadores independentes, conhecidos como biscateiros. A contratação acontece quase sempre por recomendação boca-a-boca, em grupos de WhatsApp ou diretamente na rua. Para quem precisa do serviço, isto significa incerteza: não sabe em quem confiar, quanto vai pagar nem se o trabalho ficará bem feito. Para o profissional, significa depender da sorte para ter trabalho e não ter forma de provar a qualidade do que faz.

A Kisalu Express é uma aplicação móvel que responde a este problema. O nome junta “kisalu”, palavra de origem kimbundu associada a trabalho, a “express”, que traduz rapidez e proximidade; a promessa da marca é “Quem sabe, resolve.”

Na app existem dois perfis. O cliente descreve o que precisa, indica a localização e a data pretendida e publica um pedido. Os profissionais da categoria que estão perto recebem uma notificação e respondem com propostas que incluem o preço fechado em kwanzas, o que está incluído e a hora de chegada. O cliente compara as propostas, consulta o perfil de cada profissional – fotos de trabalhos feitos, selo de verificação e avaliações de outros clientes – e aceita a que lhe parecer melhor.

O elemento distintivo é a confirmação do serviço por QR Code. Quando o trabalho termina, o cliente mostra um código na sua app e o profissional lê-o com a dele. Esse gesto regista, de forma inequívoca, que o serviço foi concluído e pelo valor combinado, e abre a avaliação mútua. Com o tempo, cada profissional constrói uma reputação verificável, que o ajuda a conquistar novos clientes.

Do ponto de vista técnico, a solução é composta por uma aplicação Flutter, desenvolvida segundo o padrão MVC, uma API REST em Node.js, Express 5 e TypeScript que concentra a lógica de negócio e uma base de dados relacional MySQL 8, executada em Docker. Na 2.ª entrega, a app e o servidor já funcionam juntos: o utilizador entra com um código SMS (simulado), publica pedidos, recebe e aceita propostas, confirma o serviço por QR Code e avalia, tanto no papel de cliente como no de profissional. Da Matemática Discreta vêm duas peças aplicadas ao produto: a estatística das avaliações (média, mediana, desvio padrão, intervalo de confiança e média bayesiana) e uma simulação de Monte Carlo que estima a probabilidade de o profissional chegar à hora prometida. Os dados pessoais são tratados de acordo com o RGPD, e os dados usados em desenvolvimento são fictícios.

O projeto é desenvolvido no âmbito do Projeto Multidisciplinar Mobile da Licenciatura em Engenharia Informática do IADE – Universidade Europeia, integrando os contributos de seis unidades curriculares. Segue uma metodologia ágil, com planeamento em GitHub Projects, prototipagem em Figma, implementação incremental e testes funcionais e de usabilidade, ao longo de três entregas no semestre.

## c. Contexto

### i. Problema abordado

A contratação de serviços informais em Angola é feita sem informação sobre preço, qualidade ou fiabilidade. Clientes perdem tempo e correm riscos; profissionais qualificados têm dificuldade em chegar a novos clientes e em construir reputação. Um questionário com 8 participantes (outubro de 2026) mostrou que a recomendação é o único filtro e não chega: 5 em 7 clientes escolheram por recomendação e todos tiveram pelo menos um problema. O preço mudou no fim em 4 de 7 casos e 5 em 7 tiveram trabalho mal feito, sem garantia. A economia informal representa a maioria do emprego em África, mas está quase ausente das plataformas digitais existentes, pensadas para outros mercados.

### ii. Motivação

Os elementos do grupo conhecem de perto a realidade angolana e o impacto que um profissional de confiança tem no dia-a-dia de uma família. O projeto permite aplicar as competências do semestre a um problema real, com potencial impacto social: dar visibilidade e rendimento a quem trabalha por conta própria e tranquilidade a quem precisa de um serviço.

### iii. Objetivos

- Desenvolver uma app Flutter para Android e iOS, com perfis de cliente e de profissional.
- Implementar o ciclo pedido → proposta → serviço → confirmação por QR Code → avaliação.
- Garantir que o preço combinado é o preço pago e que o cliente tem resposta quando algo corre mal.
- Permitir a pesquisa de profissionais por categoria e por proximidade.
- Construir e documentar uma API REST em Node.js e uma base de dados MySQL.
- Garantir a usabilidade da solução e a conformidade com o RGPD.

## d. Processo

### i. Metodologia utilizada

Metodologia ágil, com sprints de duas semanas e tarefas geridas em GitHub Projects. O trabalho organiza-se em cinco fases – investigação, modelação, desenvolvimento, testes e entrega – com marcos nas três entregas do semestre (2 de outubro, 6 de novembro e 11 de dezembro de 2026). O design segue um processo centrado no utilizador: questionário com 8 participantes, personas e Journey Map, mockups, avaliação heurística (22 problemas, 7 graves, segundo as 11 heurísticas HMT de Rocha et al., 2014), protótipo v2 com as correções e, por fim, testes de usabilidade.

### ii. Ferramentas utilizadas

Figma (mockups e protótipo); Google Forms (questionário); Android Studio e Visual Studio Code; Git, GitHub e GitHub Projects (26 tarefas concluídas, 7 em curso e 11 por fazer à data da 2.ª entrega); Docker Compose; MySQL Workbench; Swagger e Postman (testes da API); Vitest e `flutter test` (testes automáticos); Microsoft Word e Markdown (documentação).

### iii. Tecnologias utilizadas

Flutter e Dart (Provider, go_router); Node.js, Express 5 e TypeScript; MySQL 8 em Docker; autenticação por código SMS (simulado) e JSON Web Tokens; geração de QR Code; geolocalização e mapa. A leitura do QR Code com a câmara e as notificações push ficam para a 3.ª entrega.

### iv. Estrutura da equipa

Todos os elementos participam em todas as frentes; cada um assume a responsabilidade principal de uma área.

| Elemento | Responsabilidade principal |
|---|---|
| **Álvaro da Silva** | Coordenação geral do projeto; UX/UI e prototipagem em Figma, incluindo testes de usabilidade; desenvolvimento em Node.js e Flutter/Dart. |
| **Milton Malavo** | Back-end (Node.js e integração da API REST) e modelação da base de dados, com o Adilson; desenvolvimento em Node.js e Flutter/Dart. |
| **Adilson Yango** | Modelação e administração da base de dados MySQL (create, populate, queries), com o Milton; desenvolvimento em Node.js e Flutter/Dart. |

## e. Resultados

> Estado na 2.ª entrega (novembro de 2026): protótipo alfa com servidor, base de dados e app a funcionar em conjunto. A descrição final será atualizada na 3.ª entrega.

### i. Descrição da solução desenvolvida

Sistema cliente-servidor em três camadas: app móvel Flutter (MVC, Provider, go_router), API REST em Node.js, Express 5 e TypeScript (routes, controllers, models e services) e base de dados MySQL 8 em Docker, com SMS simulado e uploads privados. O diagrama está em [arquitetura-v3.png](../04_Documentacao_Tecnica/arquitetura-v3.png).

Estão concluídos a proposta de projeto (v1 e v2), a identidade visual, o Mobile App Style Guide, a pesquisa com utilizadores, a avaliação heurística, o modelo do domínio e o protótipo em Figma. A app tem 30 ecrãs e folhas documentadas, com cliente e prestador (ecrãs 11 a 22 do lado do prestador, mais notificações, ajuda, detalhe do trabalho, edição de pedido, reporte de problema, comprovativo e recusa de proposta) e consome a API REST, com 82 endpoints documentados no formato bocoup e no Swagger. A base de dados tem os scripts `create`, `populate` e `queries` separados, com triggers e vistas.

O código está em três repositórios: [Kisalu-Express](https://github.com/Eng-Infomatica-IADE/Kisalu-Express) (documentação e artefactos), [kissalu-app](https://github.com/Eng-Infomatica-IADE/kissalu-app) (front-end) e [kisalu-api](https://github.com/Eng-Infomatica-IADE/kisalu-api) (back-end e base de dados). Uma cópia do código está em `05_Artefactos`. O planeamento está no [GitHub Projects](https://github.com/orgs/Eng-Infomatica-IADE/projects/1) (26 tarefas concluídas, 7 em curso, 11 por fazer).

### ii. Funcionalidades principais

- Registo e entrada com número de telemóvel angolano e código SMS (simulado), com sessão guardada e perfil de cliente ou de profissional na mesma conta.
- Pesquisa de profissionais por categoria e proximidade, em lista e em mapa.
- Pedidos de serviço com descrição, fotografia, localização, ponto de referência e rascunho automático; editar e cancelar pedidos.
- Propostas com preço fechado em kwanzas e o que incluem; aceitar, recusar (com diálogo de confirmação) e alteração de preço só com aprovação.
- Confirmação do serviço por QR Code, com código numérico alternativo, comprovativo e garantia de 7 dias.
- Reporte de problemas antes de confirmar e depois, até 7 dias.
- Lado do prestador: registo em três passos, verificação de identidade (documentos privados), envio de propostas, detalhe do trabalho aceite e leitura do QR do cliente.
- Perfil do profissional com portefólio de trabalhos feitos e "Avaliações em números".
- Avaliação mútua, histórico de pedidos, conversas, notificações e ajuda.

### iii. Contributos relevantes

- Adaptação do modelo de marketplace de serviços ao contexto angolano (kwanzas, profissionais sem presença digital, moradas pouco normalizadas, telemóvel +244).
- Confirmação presencial por QR Code como mecanismo de confiança entre as partes.
- Requisitos derivados de dados reais: 8 insights do questionário e 22 problemas da avaliação heurística, ligados a 18 requisitos funcionais.
- **Matemática Discreta aplicada ao produto**: estatística das avaliações (média, mediana, moda, variância e desvio padrão amostrais, intervalo de confiança a 95 % e distribuição por estrelas), média bayesiana para ordenar profissionais com poucas avaliações e simulação de Monte Carlo (10 000 viagens) para estimar a probabilidade de chegar a tempo. Estão descritas em [matematica.md](../04_Documentacao_Tecnica/matematica.md) e testadas com valores calculados à mão.
- **Qualidade verificada**: 83 testes automáticos na API, 703 na app e 154 verificações ponta a ponta contra a API real, sem falhas. O teste de QA encontrou e corrigiu falhas de fluxo (ver [testes-qa.md](../06_Dados_Investigacao/testes-qa.md)).
- Identidade visual própria, com sistema de cores, tipografia e iconografia para a app.

## f. Reflexão

> A completar até à entrega final.

### i. Lições aprendidas

- O protótipo v1 desenhava bem o caminho feliz, mas não os desvios: a avaliação heurística mostrou que faltava prever o que acontece quando algo corre mal.
- A hipótese inicial de que a espera era o pior momento não se confirmou: as dores mais fortes estão no fim do serviço, no preço que muda e no trabalho mal feito.
- O mapa, pensado como elemento central, teve pouco valor para os participantes (3,0 em 5).
- Testar a app contra a API real revelou falhas que os testes com dados simulados não apanhavam (por exemplo, a avaliação não tinha caminho com a API e a confirmação do pedido errado com dois serviços ativos). Passámos a validar cada fluxo de ponta a ponta antes de o dar por fechado.

### ii. Limitações

- Pagamentos reais integrados ficam fora do âmbito; o valor é combinado na app e pago diretamente ao profissional.
- A verificação de identidade dos profissionais é simulada com dados fictícios e o SMS é simulado (o código aparece no terminal do servidor).
- A leitura do QR Code com a câmara, a captura de documento, as notificações push e o GPS em tempo real ainda não estão integrados; a app corre, para já, no browser e no emulador.
- A pesquisa tem 8 participantes, numa amostra urbana e qualificada, e só um profissional respondeu ao bloco próprio (nota de 1 em 5 à app). A adesão dos profissionais é o maior risco e tem de ser validada.
- A simulação de Monte Carlo usa parâmetros de velocidade e atraso assumidos, ainda não calibrados com dados reais.

### iii. Trabalho futuro

3.ª entrega:

- Leitor de QR Code com a câmara, captura de documento de identidade, notificações push, GPS e lista de favoritos.
- App instalada num telemóvel real e testes de usabilidade com utilizadores.
- Manual de utilizador, póster, vídeo de demonstração e vídeo de apresentação.

Depois do semestre:

- Integração com meios de pagamento locais, com retenção do valor até à confirmação (RF18).
- Painel de administração para moderação e verificação de profissionais.
- Publicação nas lojas de aplicações e testes com utilizadores reais em Luanda.
