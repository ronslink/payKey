# Stage 1: build the Vite app
FROM node:24-alpine AS builder
WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci

COPY . .
ARG VITE_ANDROID_APP_URL
ARG VITE_IOS_APP_URL
ARG VITE_API_URL=https://api.paydome.co
ENV VITE_ANDROID_APP_URL=$VITE_ANDROID_APP_URL
ENV VITE_IOS_APP_URL=$VITE_IOS_APP_URL
ENV VITE_API_URL=$VITE_API_URL
RUN npm run build

# Stage 2: serve the static build
FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
