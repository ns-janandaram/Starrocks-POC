FROM golang:1.23-alpine AS builder

WORKDIR /app

# Install dependencies
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build binary
RUN CGO_ENABLED=0 GOOS=linux go build -o /kafka-starrocks-loader ./cmd/loader

# Final image
FROM alpine:3.19

RUN apk --no-cache add ca-certificates tzdata

WORKDIR /app

COPY --from=builder /kafka-starrocks-loader .

# Non-root user for security
RUN adduser -D -u 1000 appuser
USER appuser

EXPOSE 8080

CMD ["./kafka-starrocks-loader"]
