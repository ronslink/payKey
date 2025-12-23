# Redis Integration Guide

## Overview
PayKey uses Redis for caching and rate limiting with a **plug-and-play** architecture. The application works without Redis, falling back to in-memory cache.

---

## Quick Start

### Enable Redis
```env
REDIS_HOST=redis      # Or localhost
REDIS_PORT=6379       # Default
REDIS_PASSWORD=       # Optional
```

### Without Redis
Simply don't set `REDIS_HOST` - app uses in-memory fallback automatically.

---

## Features

| Feature | TTL | Description |
|---------|-----|-------------|
| **Tax Config Cache** | 24hr | Caches tax rates (rarely change) |
| **M-Pesa Token** | 55min | OAuth token cache (valid 1hr) |
| **Payslip PDFs** | 5min | Avoid regenerating same PDF |
| **Rate Limiting** | Multi-tier | 10/sec, 100/min, 1000/hr |
| **Reports** | 5-60min | Dashboard and P9 reports |

---

## Architecture

```
┌─────────────────┐
│  NestJS App     │
├─────────────────┤
│  AppCacheModule │ ──► Redis (if REDIS_HOST set)
│  (global)       │ ──► In-memory Map (fallback)
└─────────────────┘
```

### Key Files
- `src/modules/cache/cache.module.ts` - Cache configuration
- `src/modules/throttler/throttler.module.ts` - Rate limiting

---

## Usage in Services

```typescript
import { CACHE_MANAGER } from '@nestjs/cache-manager';
import type { Cache } from 'cache-manager';

@Injectable()
export class MyService {
  constructor(
    @Optional() @Inject(CACHE_MANAGER) private cacheManager?: Cache,
  ) {}

  async getData() {
    const cacheKey = 'my:data:key';
    
    // Try cache first
    if (this.cacheManager) {
      const cached = await this.cacheManager.get<MyType>(cacheKey);
      if (cached) return cached;
    }

    // Fetch and cache
    const data = await this.fetchFromDb();
    if (this.cacheManager) {
      await this.cacheManager.set(cacheKey, data, 60000); // 1min TTL
    }
    return data;
  }
}
```

---

## Docker Compose

```yaml
services:
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data

  backend:
    environment:
      - REDIS_HOST=redis
      - REDIS_PORT=6379

volumes:
  redis_data:
```

---

## Rate Limiting

Applied globally via `AppThrottlerModule`:

| Tier | Window | Limit |
|------|--------|-------|
| Short | 1 second | 10 requests |
| Medium | 1 minute | 100 requests |
| Long | 1 hour | 1000 requests |

Bypassed in development when needed.

---

## Monitoring

Check Redis connection in logs:
```
[AppCacheModule] Connected to Redis at redis:6379
```

Or fallback:
```
[AppCacheModule] Redis not configured, using in-memory cache
```
