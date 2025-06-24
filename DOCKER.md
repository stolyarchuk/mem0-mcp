# Docker Usage Guide

## Quick Start with Docker

### Using Docker Compose (Recommended)

1. Clone the repository:

```bash
git clone <repository-url>
cd mem0-mcp
```

2. Create environment file:

```bash
cp .env.example .env
# Edit .env and add your MEM0_API_KEY
```

3. Run with Docker Compose:

```bash
# Run the Python SSE server (default)
docker-compose up -d

# Or run the Node.js MCP server
docker-compose --profile node up mem0-mcp-node -d
```

### Using Docker directly

1. Build the image:

```bash
docker build -t mem0-mcp .
```

2. Run the Python SSE server:

```bash
docker run -d \
  --name mem0-mcp \
  -p 8080:8080 \
  -e MEM0_API_KEY=your_api_key_here \
  mem0-mcp
```

3. Or run the Node.js MCP server:

```bash
docker run -d \
  --name mem0-mcp-node \
  -e MEM0_API_KEY=your_api_key_here \
  mem0-mcp \
  node node/mem0/dist/index.js
```

### Using the pre-built image from GitHub Container Registry

```bash
# Pull and run the latest image
docker run -d \
  --name mem0-mcp \
  -p 8080:8080 \
  -e MEM0_API_KEY=your_api_key_here \
  ghcr.io/yourusername/mem0-mcp:latest
```

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `MEM0_API_KEY` | Your Mem0 API key (required) | - |
| `HOST` | Server host | `0.0.0.0` |
| `PORT` | Server port | `8080` |
| `DEBUG` | Enable debug mode | `false` |
| `DEFAULT_USER_ID` | Default user ID for memory storage | `cursor_mcp` |

## Health Checks

The Docker image includes health checks that verify the server is running properly:

```bash
# Check container health
docker ps

# View health check logs
docker inspect --format='{{.State.Health.Status}}' mem0-mcp
```

## Development with Docker

For development, you can mount your source code:

```bash
docker run -d \
  --name mem0-mcp-dev \
  -p 8080:8080 \
  -e MEM0_API_KEY=your_api_key_here \
  -v $(pwd)/main.py:/app/main.py:ro \
  mem0-mcp
```

## Multi-Architecture Support

The Docker image supports both AMD64 and ARM64 architectures:

```bash
# Specific platform
docker run --platform linux/amd64 ghcr.io/yourusername/mem0-mcp:latest
docker run --platform linux/arm64 ghcr.io/yourusername/mem0-mcp:latest
```

## Security Considerations

- The container runs as a non-root user (`mem0`)
- Minimal base images are used to reduce attack surface
- Regular security scans are performed in CI/CD
- SBOM (Software Bill of Materials) is generated for transparency

## Troubleshooting

### Common Issues

1. **API Key not working**:

   ```bash
   docker logs mem0-mcp
   ```

2. **Port already in use**:

   ```bash
   docker run -p 8081:8080 mem0-mcp
   ```

3. **Memory issues**:

   ```bash
   docker run --memory=1g mem0-mcp
   ```

### Accessing Logs

```bash
# View container logs
docker logs mem0-mcp

# Follow logs in real-time
docker logs -f mem0-mcp
```
