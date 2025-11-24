FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev
COPY index.js ./
ENV API_URL=http://api:8080/monitoring/ingest
ENV MONITORING_INTERVAL_MS=5000
CMD ["npm", "start"]
