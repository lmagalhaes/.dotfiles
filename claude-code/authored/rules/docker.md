# Docker Preferences

- Prefer Docker/containers over running services directly on host
- Each git worktree has isolated containers — no shared state between branches
- Use docker compose for multi-service setups; define services in compose.yml
- Development containers should mirror production environment as closely as possible
- Never store secrets in Dockerfiles or compose files — use env files or Docker secrets
- Pin image versions in production; :latest is acceptable for local dev tooling only
- Multi-stage builds for production images to minimise final image size
