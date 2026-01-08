# Multi-stage Dockerfile for Fabric RTI MCP Server
# Optimized for AKS deployment with security best practices

# Build stage
FROM python:3.10-slim as builder

# Install build dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /build

# Copy dependency files first for better layer caching
COPY pyproject.toml setup.cfg MANIFEST.in ./
COPY README.md LICENSE ./

# Copy source code
COPY fabric_rti_mcp/ ./fabric_rti_mcp/

# Install dependencies and build wheel
RUN pip install --no-cache-dir --upgrade pip setuptools wheel setuptools_scm && \
    pip wheel --no-cache-dir --wheel-dir /build/wheels .

# Runtime stage
FROM python:3.10-slim

# Add metadata labels
LABEL maintainer="Microsoft Fabric RTI MCP Team"
LABEL description="MCP Server for Microsoft Fabric Real-Time Intelligence"
LABEL version="0.2.0"

# Install runtime dependencies only
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user for security
RUN groupadd -r mcpuser && \
    useradd -r -g mcpuser -u 1000 -d /app -s /sbin/nologin mcpuser

# Set working directory
WORKDIR /app

# Copy wheels from builder
COPY --from=builder /build/wheels /tmp/wheels

# Install the application from wheels
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir /tmp/wheels/*.whl && \
    rm -rf /tmp/wheels

# Switch to non-root user
USER mcpuser

# Expose port for HTTP transport
EXPOSE 3000

# Health check endpoint
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:3000/health').read()" || exit 1

# Set default environment variables
ENV FABRIC_RTI_TRANSPORT=http \
    FABRIC_RTI_HTTP_HOST=0.0.0.0 \
    FABRIC_RTI_HTTP_PORT=3000 \
    FABRIC_RTI_HTTP_PATH=/mcp \
    FABRIC_RTI_STATELESS_HTTP=true \
    PYTHONUNBUFFERED=1

# Run the server
CMD ["python", "-m", "fabric_rti_mcp.server"]
