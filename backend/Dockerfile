# Use Node.js LTS version
FROM node:24-alpine AS build

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install all dependencies (including dev dependencies for building)
RUN npm ci --ignore-scripts

# Copy source code
COPY . .

# Build the application
RUN npm run build

# Remove dev dependencies to reduce image size
RUN npm prune --omit=dev --ignore-scripts && npm cache clean --force

FROM node:24-alpine AS runtime
WORKDIR /app
ARG RELEASE_COMMIT=unknown
LABEL org.opencontainers.image.revision=$RELEASE_COMMIT
ENV NODE_ENV=production
COPY --from=build /app/package*.json ./
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/dist ./dist
COPY scripts/audit-production.cjs ./scripts/audit-production.cjs
RUN mkdir -p /app/storage && chown node:node /app/storage
USER node

# Expose port
EXPOSE 3000

# Start the application in production mode
CMD ["node", "dist/src/main"]
