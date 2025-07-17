# Build stage
FROM golang:1.23.5-alpine AS builder

# Set working directory
WORKDIR /app

# Install build dependencies
RUN apk --no-cache add ca-certificates git

# Copy go mod and sum files
COPY go.mod go.sum ./

# Download dependencies
RUN go mod download

# Copy source code
COPY . .

# Build the application with version info
ARG VERSION=dev
ARG COMMIT_SHA=unknown
ARG BUILD_DATE=unknown

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -ldflags="-w -s -X main.version=${VERSION} -X main.commitSha=${COMMIT_SHA} -X main.buildDate=${BUILD_DATE}" \
    -o api ./cmd/api

# Final stage - using distroless for minimal attack surface
FROM gcr.io/distroless/static:nonroot

# Copy certificates from builder
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

# Set working directory
WORKDIR /app

# Copy the binary from builder
COPY --from=builder /app/api .

# Default environment variables
ENV ADDR=":8080" \
    DB_ADDR="postgres://admin:password@db:5432/portfolio?sslmode=disable" \
    DB_MAX_OPEN_CONNS=30 \
    DB_MAX_IDLE_CONNS=30 \
    DB_MAX_IDLE_TIME="15m" \
    LOG_LEVEL="info"

# Expose the application port
EXPOSE 8080

# Use non-root user for security
USER nonroot:nonroot

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 CMD [ "/app/api", "health" ]

# Run the application
ENTRYPOINT ["/app/api"]