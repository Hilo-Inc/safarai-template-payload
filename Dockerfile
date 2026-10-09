# Payload website template as one image: Next.js standalone output with SQLite.
# Runtime settings (see README): SERVER_URL, PAYLOAD_SECRET, DATABASE_URL, MEDIA_DIR.
FROM node:22-alpine AS base
RUN apk add --no-cache libc6-compat && corepack enable pnpm

FROM base AS deps
WORKDIR /app
COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile

FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
ENV NEXT_TELEMETRY_DISABLED=1
# The build renders pages, which starts Payload: it gets a throwaway database
# (migrated on startup) and secret. Neither ends up in the image.
RUN DATABASE_URL=file:/tmp/build.db PAYLOAD_SECRET=build-only pnpm run build

FROM base AS runner
WORKDIR /app
ENV NODE_ENV=production \
    NEXT_TELEMETRY_DISABLED=1 \
    PORT=3000 \
    HOSTNAME=0.0.0.0 \
    DATABASE_URL=file:/data/payload.db \
    MEDIA_DIR=/app/media

RUN addgroup --system --gid 1001 nodejs && adduser --system --uid 1001 nextjs
COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static
# The database and uploads live on volumes mounted at these paths.
RUN mkdir -p /data /app/media && chown nextjs:nodejs /data /app/media /app/.next

USER nextjs
EXPOSE 3000
VOLUME ["/data", "/app/media"]
CMD ["node", "server.js"]
