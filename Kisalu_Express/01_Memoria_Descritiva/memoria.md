# Memória Descritiva — Kisalu Express

> Documento vivo: versão da 1.ª entrega (outubro de 2026). As secções de Resultados e Reflexão serão completadas nas entregas seguintes.

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

Na app existem dois perfis. O cliente descreve o que precisa, indica a localização e a data pretendida e publica um pedido. Os profissionais da categoria que estão perto recebem uma notificação e respondem com propostas que incluem o preço em kwanzas e o tempo estimado de chegada. O cliente compara as propostas, consulta o perfil de cada profissional – especialidades, anos de experiência, selo de verificação e avaliações de outros clientes – e aceita a que lhe parecer melhor. Durante o serviço, os dois podem trocar mensagens e o cliente acompanha a chegada no mapa.

O elemento distintivo é a confirmação do serviço por QR Code. Quando o trabalho termina, o cliente mostra um código na sua app e o profissional lê-o com a dele. Esse gesto regista, de forma inequívoca, que o serviço foi concluído e pelo valor combinado, e abre a avaliação mútua. Com o tempo, cada profissional constrói uma reputação verificável, que o ajuda a conquistar novos clientes.

Do ponto de vista técnico, a solução é composta por uma aplicação Flutter, desenvolvida segundo o padrão MVC, uma API REST em Node.js e Express que concentra a lógica de negócio e uma base de dados relacional MySQL. A app recorre a capacidades próprias dos dispositivos móveis: geolocalização para encontrar profissionais por proximidade, câmara para ler o QR Code e notificações push para avisar de novos pedidos e propostas. Os dados pessoais são tratados de acordo com o RGPD, e os dados usados em desenvolvimento são fictícios.

O projeto é desenvolvido no âmbito do Projeto Multidisciplinar Mobile da Licenciatura em Engenharia Informática do IADE – Universidade Europeia, integrando os contributos de seis unidades curriculares. Segue uma metodologia ágil, com planeamento em GitHub Projects, prototipagem em Figma, implementação incremental e testes funcionais e de usabilidade, ao longo de três entregas no semestre.

## c. Contexto

### i. Problema abordado

A contratação de serviços informais em Angola é feita sem informação sobre preço, qualidade ou fiabilidade. Clientes perdem tempo e correm riscos; profissionais qualificados têm dificuldade em chegar a novos clientes e em construir reputação. A economia informal representa a maioria do emprego em África, mas está quase ausente das plataformas digitais existentes, pensadas para outros mercados.

### ii. Motivação

Os elementos do grupo conhecem de perto a realidade angolana e o impacto que um profissional de confiança tem no dia-a-dia de uma família. O projeto permite aplicar as competências do semestre a um problema real, com potencial impacto social: dar visibilidade e rendimento a quem trabalha por conta própria e tranquilidade a quem precisa de um serviço.

### iii. Objetivos

- Desenvolver uma app Flutter com perfis de cliente e de profissional.
- Implementar o ciclo pedido → proposta → serviço → confirmação por QR Code → avaliação.
- Permitir a pesquisa de profissionais por categoria e por proximidade.
- Construir e documentar uma API REST em Node.js e uma base de dados MySQL.
- Garantir a usabilidade da solução e a conformidade com o RGPD.

## d. Processo

### i. Metodologia utilizada

Metodologia ágil, com sprints de duas semanas e tarefas geridas em GitHub Projects. O trabalho organiza-se em cinco fases – investigação, modelação, desenvolvimento, testes e entrega – com marcos nas três entregas do semestre (2 de outubro, 6 de novembro e 11 de dezembro de 2026). O design segue um processo centrado no utilizador: pesquisa, guiões de teste, mockups, avaliação heurística e testes de usabilidade.

### ii. Ferramentas utilizadas

Figma (mockups e protótipo); Android Studio e Visual Studio Code; Git, GitHub e GitHub Projects; MySQL Workbench; Postman (testes da API); Microsoft Word e Markdown (documentação).

### iii. Tecnologias utilizadas

Flutter e Dart; Node.js e Express; MySQL 8; JSON Web Tokens e bcrypt; Google Maps e geolocalização; geração e leitura de QR Code; notificações push.

### iv. Estrutura da equipa

Todos os elementos participam em todas as frentes; cada um assume a responsabilidade principal de uma área.

| Elemento | Responsabilidade principal |
|---|---|
| **Álvaro da Silva** | Coordenação geral do projeto; UX/UI e prototipagem em Figma, incluindo testes de usabilidade; desenvolvimento em Node.js e Flutter/Dart. |
| **Milton Malavo** | Back-end (Node.js e integração da API REST) e modelação da base de dados, com o Adilson; desenvolvimento em Node.js e Flutter/Dart. |
| **Adilson Yango** | Modelação e administração da base de dados MySQL (create, populate, queries), com o Milton; desenvolvimento em Node.js e Flutter/Dart. |

## e. Resultados

> Estado à data da 1.ª entrega. A descrição final será atualizada na 3.ª entrega.

### i. Descrição da solução desenvolvida

Sistema cliente-servidor em três camadas: app móvel Flutter (MVC), API REST em Node.js/Express (MVC) e base de dados MySQL. Nesta fase estão concluídos a proposta de projeto, a identidade visual, o modelo do domínio, a arquitetura provisória e os mockups dos sete ecrãs principais em Figma.

### ii. Funcionalidades principais

- Registo e autenticação com perfil de cliente ou de profissional.
- Pesquisa de profissionais por categoria e proximidade, em lista e em mapa.
- Pedidos de serviço com descrição, fotografia, localização e data.
- Propostas com preço em kwanzas e tempo estimado; aceitação pelo cliente.
- Confirmação do serviço por QR Code.
- Avaliação mútua e reputação do profissional.
- Histórico de pedidos, mensagens e notificações.

### iii. Contributos relevantes

- Adaptação do modelo de marketplace de serviços ao contexto angolano (kwanzas, profissionais sem presença digital, moradas pouco normalizadas).
- Confirmação presencial por QR Code como mecanismo de confiança entre as partes.
- Identidade visual própria, com sistema de cores, tipografia e iconografia para a app.

## f. Reflexão

> A completar ao longo do projeto.

### i. Lições aprendidas

_A registar nas entregas seguintes._

### ii. Limitações

- Pagamentos reais integrados ficam fora do âmbito; o valor é combinado na app e pago diretamente ao profissional.
- A verificação de identidade dos profissionais é simulada com dados fictícios.

### iii. Trabalho futuro

- Integração com meios de pagamento locais.
- Painel de administração para moderação e verificação de profissionais.
- Publicação nas lojas de aplicações e testes com utilizadores reais em Luanda.
