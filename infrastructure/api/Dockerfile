FROM golang:1.24-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o /app/bin/api ./src/main.go

FROM alpine:3.19
RUN apk add --no-cache ca-certificates
WORKDIR /app
COPY --from=builder /app/bin/api /app/api

# Create mount points with proper permissions for nobody user
RUN mkdir -p /mnt/data /mnt/backups && \
    chmod 777 /mnt/data /mnt/backups

EXPOSE 8080
USER nobody
ENTRYPOINT ["/app/api"]
