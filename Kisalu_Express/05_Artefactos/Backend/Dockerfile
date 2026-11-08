# ---- Etapa 1: compilar o TypeScript ----
FROM node:20-slim AS build
WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci

COPY tsconfig.json ./
COPY src ./src
RUN npm run build

# ---- Etapa 2: imagem final, só com o necessário para correr ----
FROM node:20-slim
WORKDIR /app
ENV NODE_ENV=production

COPY package.json package-lock.json ./
RUN npm ci --omit=dev && npm cache clean --force

COPY --from=build /app/dist ./dist
# Ficheiros SQL (create.sql → populate.sql; queries.sql com exemplos), para consulta dentro do contentor.
# A base do docker-compose é criada pelo serviço "db" a partir destes mesmos ficheiros.
COPY database ./database

# Pastas das imagens enviadas (montadas como volumes no docker-compose):
# uploads/ é pública (/uploads); privado/ guarda documentos de identidade e fotos de reclamações,
# que só o admin vê pela API
RUN mkdir -p uploads privado && chown -R node:node uploads privado
USER node

EXPOSE 3000
CMD ["node", "dist/server.js"]
