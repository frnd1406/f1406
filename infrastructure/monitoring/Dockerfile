FROM golang:1.24-alpine AS builder
WORKDIR /app
COPY go.mod ./
COPY go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o /app/monitoring-agent main.go

FROM alpine:3.19
RUN apk add --no-cache ca-certificates
COPY --from=builder /app/monitoring-agent /usr/local/bin/monitoring-agent
ENTRYPOINT ["monitoring-agent"]
