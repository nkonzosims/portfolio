# Multi-stage build for Angular app served by Nginx

# 1) Build stage
FROM node:22-alpine AS build
WORKDIR /app

# Install deps first (better layer caching)
COPY package*.json ./
RUN npm ci --no-audit --no-fund

# Copy sources and build
COPY . .

# Build configuration can be overridden at build time
ARG BUILD_CONFIGURATION=production
ENV BUILD_CONFIGURATION=${BUILD_CONFIGURATION}

# Use Angular CLI script from node_modules
RUN npm run build -- --configuration=${BUILD_CONFIGURATION}

# 2) Runtime stage
FROM nginx:1.27-alpine

# Copy custom Nginx config
COPY nginx/default.conf /etc/nginx/conf.d/default.conf

# Copy built app
# Angular application build output (browser) to Nginx html root
COPY --from=build /app/dist/portfolio/browser /usr/share/nginx/html

EXPOSE 80

# Optional basic healthcheck
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s \
  CMD wget -qO- http://127.0.0.1/ >/dev/null 2>&1 || exit 1

# Default command provided by Nginx image
