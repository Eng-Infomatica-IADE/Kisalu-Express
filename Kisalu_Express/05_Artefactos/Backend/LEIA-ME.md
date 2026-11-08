# Backend (API Kisalu Express)

Cópia do repositório de origem **kisalu-api** (<https://github.com/Eng-Infomatica-IADE/kisalu-api>), sem o `.env`. O `dados.env` está aqui com a mesma estrutura do original, mas com `SMTP_USER`, `SMTP_PASSWORD`, `JWT_SECRET` e `DB_PASSWORD` em branco, porque este repositório é público.

O SQL (criação, dados de teste e consultas) está em `../Base_Dados`. Para correr a API a partir desta pasta, copie `../Base_Dados` para `database/` (o `docker-compose` monta essa pasta na base de dados) ou use diretamente o repositório original. Copie `.env.example` para `.env` e preencha os valores.
