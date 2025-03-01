ARG GO_VERSION=1.24

FROM golang:${GO_VERSION}-alpine AS builder

# Combine RUN commands to reduce layers and use --no-cache instead of removing cache after
RUN apk add --no-cache alpine-sdk git

WORKDIR /api

# Copy only dependency files first for better layer caching
COPY go.mod go.sum ./
RUN go mod download

# Copy source code after dependencies are installed
COPY . .
# Add build flags for smaller, more secure binary
RUN go build -ldflags="-s -w" -o ./app ./main.go

# Use a smaller base image for the runtime container
FROM alpine:3.21

# Set all ENVs together for better readability
ENV CONFIG=/config \
    DATA=/assets \
    UID=998 \
    PID=100 \
    GIN_MODE=release

# Define volumes
VOLUME ["/config", "/assets"]

# Install certificates and create directories in a single layer
RUN apk add --no-cache ca-certificates && \
    mkdir -p /config /assets /api && \
    chmod 777 /config /assets

WORKDIR /api

# Copy only what's needed from the builder
COPY --from=builder /api/app .
COPY client ./client
COPY webassets ./webassets

# Add healthcheck
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1

EXPOSE 8080

# Use exec form of ENTRYPOINT for proper signal handling
ENTRYPOINT ["./app"]