FROM node:24-bookworm-slim AS build

WORKDIR /app

RUN npm install -g npm@11.13.0

COPY package.json package-lock.json ./
RUN npm ci

COPY . .
RUN npm run build -- --configuration production --output-path=dist/frontend

FROM nginx:stable-alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/dist/frontend/browser/ /usr/share/nginx/html/

EXPOSE 80
