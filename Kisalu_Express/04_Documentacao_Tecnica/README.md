# Documentação técnica

Estado na 2.ª entrega (protótipo alfa com servidor, base de dados e app).

| Documento | Ficheiro | Estado |
|---|---|---|
| Arquitetura do sistema (v3: Flutter MVC ↔ REST ↔ API Node/Express 5/TS ↔ MySQL 8) | [arquitetura-v3.png](arquitetura-v3.png) | Atual (3140 px de largura) |
| Arquitetura do sistema (proposta v2) | [arquitetura.png](arquitetura.png) | Substituída pela v3, mantida como histórico |
| Modelo do domínio | [modelo-dominio.png](modelo-dominio.png) | Versão da proposta v2 (11 entidades); o modelo ER atual está em [dados.md](dados.md) |
| Arquitetura da app Flutter | [arquitetura-app.md](arquitetura-app.md) | Atual |
| Especificação dos ecrãs da app (30 ecrãs e folhas) | [ecras-app.md](ecras-app.md) · capturas em [ecras/](ecras) | Atual |
| Documentação REST da API (formato bocoup, 82 endpoints) | [api-rest.md](api-rest.md) | Atual |
| Contrato app ↔ API (formas JSON e regras) | [contrato-api.md](contrato-api.md) | Atual |
| Modelo ER, dicionário de dados, triggers, vistas e diagrama de classes | [dados.md](dados.md) | Atual |
| Matemática: estatística das avaliações e Monte Carlo | [matematica.md](matematica.md) | Novo na 2.ª entrega |
| Base de dados (create, populate, queries) | [../05_Artefactos/Base_Dados](../05_Artefactos/Base_Dados) | Atual |
| Código da app, da API e da BD | [../05_Artefactos](../05_Artefactos) | Atual |
| Testes e QA | [../06_Dados_Investigacao/testes-qa.md](../06_Dados_Investigacao/testes-qa.md) | Novo na 2.ª entrega |
| Relatório de Base de Dados (BD Report) | [../../Documentos/g05-bd-report.md](../../Documentos/g05-bd-report.md) · [PDF](../../Documentos/g05-bd-report.pdf) | 2.ª entrega |
| Repositórios Git | [Kisalu-Express](https://github.com/Eng-Infomatica-IADE/Kisalu-Express) · [kissalu-app](https://github.com/Eng-Infomatica-IADE/kissalu-app) · [kisalu-api](https://github.com/Eng-Infomatica-IADE/kisalu-api) | Ativos |

Os ficheiros `arquitetura-app.md`, `ecras-app.md`, `api-rest.md`, `contrato-api.md`, `dados.md` e `matematica.md` são cópias dos documentos dos repositórios de origem; as ligações para documentação que não foi copiada apontam para o GitHub. As capturas em `ecras/` têm cerca de 780 px de largura, para leitura no GitHub; os originais (3120 × 6752 px) estão em [../02_Imagens](../02_Imagens/legendas.md).

Para ver a API a funcionar: `docker compose up -d --build` no repositório kisalu-api e abrir `http://localhost:3000/docs` (Swagger).
