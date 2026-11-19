# Build stage
FROM node:22-alpine AS builder
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --no-audit
COPY . .
ARG VITE_API_BASE_URL=https://educca.cocorium.online/api/v1
ARG VITE_DEFAULT_DATA_MODE=api
ENV VITE_API_BASE_URL=${VITE_API_BASE_URL}
ENV VITE_DEFAULT_DATA_MODE=${VITE_DEFAULT_DATA_MODE}
RUN npm run build

# Runtime stage
FROM nginx:alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=builder /app/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
