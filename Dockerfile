# ---------- BUILD STAGE ----------
FROM node:18-alpine AS builder 

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY tsconfig.json ./
COPY src ./src

RUN npm run build


# ---------- PRODUCTION STAGE ----------
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --omit=dev


COPY --from=builder /app/dist ./dist

ENV NODE_ENV=production

RUN addgroup -S app && adduser -S app -G app
USER app

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:8000/health', r => process.exit(r.statusCode === 200 ? 0 : 1))"


CMD ["node", "dist/index.js"]