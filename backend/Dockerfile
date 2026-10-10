# API de Apamuy para producción (Railway u otro host con Docker).
# Build: docker build -t apamuy-api backend/

FROM node:24-alpine AS build
WORKDIR /app
COPY package.json package-lock.json prisma.config.ts ./
COPY prisma ./prisma
# postinstall genera el cliente de Prisma en src/generated.
RUN npm ci
COPY . .
RUN npm run build && npm prune --omit=dev

FROM node:24-alpine AS runtime
ENV NODE_ENV=production
WORKDIR /app
COPY --from=build --chown=node:node /app/package.json /app/prisma.config.ts ./
COPY --from=build --chown=node:node /app/node_modules ./node_modules
COPY --from=build --chown=node:node /app/prisma ./prisma
COPY --from=build --chown=node:node /app/dist ./dist
USER node
EXPOSE 3000
# Las migraciones corren aparte, antes de arrancar (en Railway: preDeployCommand).
CMD ["node", "dist/main.js"]
