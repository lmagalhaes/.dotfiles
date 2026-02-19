---
description: Update all Workyard projects (crew-api, web-app, web-app-v2) with latest changes and dependencies
---

Update all Workyard projects by following these steps:

1. **Pull latest changes** for all repositories:
   - Navigate to crew-api, web-app, and web-app-v2 directories
   - Run `git pull origin main` (or appropriate branch) for each

2. **Stop all services** to avoid file locking issues:
   - Run `task stop:all` from the dev-env root

3. **Clean build artifacts and dependencies**:
   - crew-api: `rm -rf workyard-api/crew-api/vendor`
   - web-app: `rm -rf workyard-app/web-app/node_modules workyard-app/web-app/build workyard-app/web-app/.cache`
   - web-app-v2: `rm -rf workyard-app2/web-app-v2/node_modules workyard-app2/web-app-v2/.next workyard-app2/web-app-v2/.cache`

4. **Reinstall dependencies** for all projects:
   - crew-api: `task install-dep:api`
   - web-app V1: `task install-dep:v1` (handles git HTTPS config automatically)
   - web-app V2: `task install-dep:v2` (uses AWS CodeArtifact)

5. **Run database migrations**:
   - `docker exec workyard-api php artisan migrate --force`

6. **Restart all services**:
   - Run `task start:all`

7. **Verify services** are working:
   - Check containers: `docker ps | grep workyard`
   - Test API: `curl -I https://api.workyard.test`
   - Test app: `curl -I https://app.workyard.test/login`

Notes:
- Requires AWS credentials configured for web-app-v2
- API containers may show "unhealthy" but work through Traefik
- Execute all commands from `/Users/lmagalhaes/workspace/workyard/dev-env` directory