# Memória Descritiva — Kisalu Express

> Documento vivo: versão de novembro de 2026. As secções de Resultados e Reflexão serão completadas na entrega final.

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

Na app existem dois perfis. O cliente descreve o que precisa, indica a localização e a data pretendida e publica um pedido. Os profissionais da categoria que estão perto recebem uma notificação e respondem com propostas que incluem o preço fechado em kwanzas, o que está incluído e a hora de chegada. O cliente compara as propostas, consulta o perfil de cada profissional – fotos de trabalhos feitos, selo de verificação e avaliações de outros clientes – e aceita a que lhe parecer melhor. Durante o serviço, os dois podem trocar mensagens e o cliente recebe notificações com a hora prevista.

O elemento distintivo é a confirmação do serviço por QR Code. Quando o trabalho termina, o cliente mostra um código na sua app e o profissional lê-o com a dele. Esse gesto regista, de forma inequívoca, que o serviço foi concluído e pelo valor combinado, e abre a avaliação mútua. Com o tempo, cada profissional constrói uma reputação verificável, que o ajuda a conquistar novos clientes.

Do ponto de vista técnico, a solução é composta por uma aplicação Flutter, desenvolvida segundo o padrão MVC, uma API REST em Node.js e Express que concentra a lógica de negócio e uma base de dados relacional MySQL. A app recorre a capacidades próprias dos dispositivos móveis: geolocalização para encontrar profissionais por proximidade, câmara para ler o QR Code e notificações push para avisar de novos pedidos e propostas. Os dados pessoais são tratados de acordo com o RGPD, e os dados usados em desenvolvimento são fictícios.

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

Figma (mockups e protótipo); Google Forms (questionário); Android Studio e Visual Studio Code; Git, GitHub e GitHub Projects; MySQL Workbench; Postman (testes da API); Microsoft Word e Markdown (documentação).

### iii. Tecnologias utilizadas

Flutter e Dart; Node.js e Express; MySQL 8; autenticação por código SMS e JSON Web Tokens; Google Maps e geolocalização; geração e leitura de QR Code; notificações push.

### iv. Estrutura da equipa

Todos os elementos participam em todas as frentes; cada um assume a responsabilidade principal de uma área.

| Elemento | Responsabilidade principal |
|---|---|
| **Álvaro da Silva** | Coordenação geral do projeto; UX/UI e prototipagem em Figma, incluindo testes de usabilidade; desenvolvimento em Node.js e Flutter/Dart. |
| **Milton Malavo** | Back-end (Node.js e integração da API REST) e modelação da base de dados, com o Adilson; desenvolvimento em Node.js e Flutter/Dart. |
| **Adilson Yango** | Modelação e administração da base de dados MySQL (create, populate, queries), com o Milton; desenvolvimento em Node.js e Flutter/Dart. |

## e. Resultados

> Estado em novembro de 2026. A descrição final será atualizada na 3.ª entrega.

### i. Descrição da solução desenvolvida

Sistema cliente-servidor em três camadas: app móvel Flutter (MVC), API REST em Node.js/Express (MVC) e base de dados MySQL. Estão concluídos a proposta de projeto (v2), a identidade visual, o Mobile App Style Guide, a pesquisa com utilizadores, a avaliação heurística, o modelo do domínio, a arquitetura provisória e o protótipo v2 em Figma, com dez ecrãs.

### ii. Funcionalidades principais

- Registo e entrada com número de telemóvel e código SMS, com perfil de cliente ou de profissional.
- Pesquisa de profissionais por categoria e proximidade, em lista e em mapa.
- Pedidos de serviço com descrição, fotografia, localização, ponto de referência e rascunho automático.
- Propostas com preço fechado em kwanzas e o que incluem; aceitação com folha de confirmação; alteração de preço só com aprovação.
- Confirmação do serviço por QR Code, com código numérico alternativo e comprovativo.
- Reporte de problemas antes de confirmar e até 7 dias depois.
- Perfil do profissional com portefólio de trabalhos feitos.
- Avaliação mútua e reputação do profissional.
- Histórico de pedidos, mensagens e notificações.

### iii. Contributos relevantes

- Adaptação do modelo de marketplace de serviços ao contexto angolano (kwanzas, profissionais sem presença digital, moradas pouco normalizadas).
- Confirmação presencial por QR Code como mecanismo de confiança entre as partes.
- Requisitos derivados de dados reais: 8 insights do questionário e 22 problemas da avaliação heurística, ligados a 18 requisitos funcionais.
- Identidade visual própria, com sistema de cores, tipografia e iconografia para a app.

## f. Reflexão

> A completar até à entrega final.

### i. Lições aprendidas

- O protótipo v1 desenhava bem o caminho feliz, mas não os desvios: a avaliação heurística mostrou que faltava prever o que acontece quando algo corre mal.
- A hipótese inicial de que a espera era o pior momento não se confirmou: as dores mais fortes estão no fim do serviço, no preço que muda e no trabalho mal feito.
- O mapa, pensado como elemento central, teve pouco valor para os participantes (3,0 em 5).

### ii. Limitações

- Pagamentos reais integrados ficam fora do âmbito; o valor é combinado na app e pago diretamente ao profissional.
- A verificação de identidade dos profissionais é simulada com dados fictícios.
- A pesquisa tem 8 participantes, numa amostra urbana e qualificada, e só um profissional respondeu ao bloco próprio (nota de 1 em 5 à app). A adesão dos profissionais é o maior risco e tem de ser validada.

### iii. Trabalho futuro

- Integração com meios de pagamento locais, com retenção do valor até à confirmação (RF18).
- Painel de administração para moderação e verificação de profissionais.
- Publicação nas lojas de aplicações e testes com utilizadores reais em Luanda.
