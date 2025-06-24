# Multi-stage Dockerfile for Mem0 MCP Server
# This builds both Python and Node.js components

# Stage 1: Python dependencies and setup
FROM python:3.12-slim-bookworm as python-base

# Set environment variables for Python
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install UV package manager
RUN pip install uv

# Set working directory
WORKDIR /app

# Copy Python project files
COPY pyproject.toml uv.lock ./

# Install Python dependencies
RUN uv venv && \
    uv pip install -e .

# Stage 2: Node.js dependencies and build
FROM node:20-alpine3.20 as node-base

# Install pnpm
RUN npm install -g pnpm

# Set working directory for Node.js app
WORKDIR /app/node/mem0

# Copy Node.js project files
COPY node/mem0/package.json node/mem0/pnpm-lock.yaml ./
COPY node/mem0/pnpm-workspace.yaml ./

# Install Node.js dependencies
RUN pnpm install --frozen-lockfile

# Copy Node.js source code
COPY node/mem0/src/ ./src/
COPY node/mem0/tsconfig.json node/mem0/tsup.config.ts ./

# Build the TypeScript project
RUN pnpm run build

# Stage 3: Production image
FROM python:3.12-slim-bookworm as production

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PATH="/app/.venv/bin:$PATH" \
    MEM0_API_KEY="" \
    HOST=0.0.0.0 \
    PORT=8080

# Install system dependencies for runtime
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Install Node.js in production image
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g pnpm

# Create non-root user
RUN groupadd -r mem0 && useradd -r -g mem0 mem0

# Set working directory
WORKDIR /app

# Copy Python virtual environment from python-base stage
COPY --from=python-base /app/.venv /app/.venv

# Copy Python source code
COPY main.py ./
COPY pyproject.toml ./

# Copy Node.js built application from node-base stage
COPY --from=node-base /app/node/mem0/dist ./node/mem0/dist/
COPY --from=node-base /app/node/mem0/package.json ./node/mem0/
COPY --from=node-base /app/node/mem0/node_modules ./node/mem0/node_modules/

# Change ownership to non-root user
RUN chown -R mem0:mem0 /app

# Switch to non-root user
USER mem0

# Expose the port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:${PORT:-8080}/sse || exit 1

# Default command - runs the Python SSE server
CMD ["python", "main.py", "--host", "0.0.0.0", "--port", "8080"]

# Alternative commands can be used:
# For Node.js MCP server: CMD ["node", "node/mem0/dist/index.js"]
# For Python with custom host/port: CMD ["python", "main.py", "--host", "0.0.0.0", "--port", "8000"]
