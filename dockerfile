# 基礎映像
FROM node:18.17.0-slim AS base

# 安裝 pnpm
RUN npm install -g pnpm@8.6.3

# 安裝依賴
FROM base AS deps
RUN apt-get update && apt-get install -y \
    python3 \
    python3-dev \
    python3-pip \
    && rm -rf /var/lib/apt/lists/* \
    curl

WORKDIR /app
COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile
# 重新構建 TensorFlow.js
RUN npm rebuild @tensorflow/tfjs-node --build-from-source

# 構建階段
FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .



# 構建應用
ENV NEXT_TELEMETRY_DISABLED 1
RUN pnpm run build

# 生產階段
FROM base AS runner
WORKDIR /app
ENV NODE_ENV production
ENV NEXT_TELEMETRY_DISABLED 1
ENV TF_CPP_MIN_LOG_LEVEL 2

RUN groupadd -r nodejs && useradd -r -g nodejs nextjs

# 複製必要文件並設置權限
COPY --from=builder /app/public ./public
COPY --from=builder /app/package.json ./package.json
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static
COPY --from=builder /app/node_modules ./node_modules

USER nextjs

EXPOSE 3000
ENV PORT 3000
ENV HOSTNAME "0.0.0.0"
CMD ["pnpm", "run", "start"]