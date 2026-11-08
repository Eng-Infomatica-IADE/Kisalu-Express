<p align="center"><img src="Documentos/img/logo.png" alt="Kisalu Express" width="320"></p>

<p align="center"><b>Quem sabe, resolve.</b></p>

# Kisalu Express

## Documentação

| Documento | Markdown | PDF |
|---|---|---|
| Proposta inicial (1.ª entrega) | [g05-proposta-v1.md](Documentos/g05-proposta-v1.md) | [g05-proposta-v1.pdf](Documentos/g05-proposta-v1.pdf) |
| Segunda proposta (2.ª entrega) | [g05-proposta-v2.md](Documentos/g05-proposta-v2.md) | [g05-proposta-v2.pdf](Documentos/g05-proposta-v2.pdf) |
| Relatório intermédio (2.ª entrega) | – | – |
| Relatório final (3.ª entrega) | – | – |
| Mobile App Style Guide | – | [g05-mobile-style-guide.pdf](Documentos/g05-mobile-style-guide.pdf) |

**Memória e arquivo documental:** [Kisalu_Express/](Kisalu_Express)
· [Identificação (info.md)](Kisalu_Express/00_Identificacao/info.md)
· [Memória descritiva](Kisalu_Express/01_Memoria_Descritiva/memoria.md)
· [Imagens](Kisalu_Express/02_Imagens/legendas.md)
· [Documentação técnica](Kisalu_Express/04_Documentacao_Tecnica/README.md)
· [Artefactos](Kisalu_Express/05_Artefactos/README.md)

**Gestão do projeto:** [GitHub Projects – Kisalu Express](https://github.com/orgs/Eng-Infomatica-IADE/projects/1)

**Protótipo:** [Figma – Kisalu Express Mockups (G05)](https://www.figma.com/design/y6x5pO2mwQpoiF5ep18mSl/Kisalu-Express-%E2%80%94-Mockups--G05-?node-id=68-2) (ficheiro `y6x5pO2mwQpoiF5ep18mSl`, com o frame v3.1)

## Repositórios

| Repositório | Conteúdo |
|---|---|
| [Kisalu-Express](https://github.com/Eng-Infomatica-IADE/Kisalu-Express) (este) | Documentação, entregas e cópia dos artefactos em `Kisalu_Express/05_Artefactos` |
| [kissalu-app](https://github.com/Eng-Infomatica-IADE/kissalu-app) | Front-end Flutter (código em `app/`) |
| [kisalu-api](https://github.com/Eng-Infomatica-IADE/kisalu-api) | Back-end Node.js e scripts SQL |

## Estrutura de `Kisalu_Express/05_Artefactos`

```
05_Artefactos/
  Aplicacao_Movel/    app Flutter/Dart
  Backend/            API REST (Node.js, Express 5, TypeScript)
  Base_Dados/         create.sql, populate.sql, queries.sql
  Apresentacoes/      slides de cada apresentação
  identidade-visual/  brand book, logótipos e ícones
```

Instruções para correr cada parte em [05_Artefactos/README.md](Kisalu_Express/05_Artefactos/README.md).

## Sobre o projeto

Marketplace móvel que liga clientes a prestadores de serviços informais (biscateiros: eletricistas, canalizadores, mecânicos, pedreiros, técnicos de AC, cabeleireiras, etc.) em Angola, com perfis de cliente e biscateiro, pedidos, propostas, avaliações, localização e confirmação de serviço por QR Code.

**Projeto Multidisciplinar Mobile** · Licenciatura em Engenharia Informática · Universidade Europeia / IADE · 2026/2027 · Grupo 05

| Elemento | Número |
|---|---|
| Álvaro da Silva | 20252049 |
| Adilson Yango | 20252312 |
| Milton Malavo | 20252099 |

## Estado

O front-end está na versão v3.1, com 22 ecrãs (incluindo o lado do prestador, ecrãs 11 a 22), corrigidos após a avaliação heurística. O back-end REST está integrado com a app (entrada por SMS, pedidos, propostas, confirmação por QR, avaliações, conversas e notificações) e a base de dados MySQL está separada em scripts próprios. Depois de um teste de QA ponta a ponta foram acrescentados recusar e editar pedidos, reportar problema depois de confirmar, o detalhe do trabalho para o profissional, notificações e ajuda. Documentação técnica em [Kisalu_Express/04_Documentacao_Tecnica](Kisalu_Express/04_Documentacao_Tecnica).

## Mockups

![Mockups Kisalu Express v2](Documentos/img/mockups-v2.png)

## Tecnologias

Flutter / Dart · Node.js, Express 5 e TypeScript (API REST) · MySQL 8 · Docker Compose · Figma · GitHub Projects
