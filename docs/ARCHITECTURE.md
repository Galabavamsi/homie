# Architecture

```mermaid
flowchart TD
  A["Flutter App\nMaterial 3 + Riverpod + GoRouter"] --> B["Homie API\nExpress REST"]
  A --> C["Realtime Channel\nSocket.io"]
  B --> D["Room Service\nCollaboration data"]
  B --> E["Restaurant/Menu/Cart/Order/User Services"]
  C --> D
  D --> F["PostgreSQL\nrooms, participants, messages, votes"]
  C --> G["Redis\npresence, pub/sub, ephemeral sync"]
  E --> H["McpService boundary"]
  H --> I["Swiggy MCP\nOAuth, restaurants, menus, cart, checkout, orders"]
```

## Frontend Layers

```text
lib/
  core/                 theme and mock data
  domain/
    models/             room, participant, restaurant, menu, cart, order
    services/           service contracts for MCP-facing features
  data/
    mcp/                mock MCP implementation
    repositories/       reserved for remote/local repository implementations
  presentation/
    app.dart            router and app shell
    state/              Riverpod controller
    screens/            splash, login, home, room, checkout, tracking
    widgets/            glass panels, avatars, chips, price helpers
```

## Backend Layers

```text
src/
  config/               env, Postgres, Redis
  data/                 mock data
  routes/               REST API
  services/             use-case services and MCP adapter
  sockets/              Socket.io room events
  server.js             app bootstrap
```

## Production Replacement Plan

1. Keep Homie room APIs unchanged.
2. Replace `MockMcpService` in Flutter only if direct client MCP calls become approved.
3. Replace `apps/api/src/services/McpService.js` with authenticated server-side Swiggy MCP calls.
4. Move `rooms` in-memory data to PostgreSQL tables.
5. Use Redis for presence, typing state, Socket.io adapter, and rate-limit counters.
6. Add OAuth token storage with encryption, rotation, and least-privilege scopes.
7. Add audit logging and PII retention controls before production rollout.

## Security Notes

- Swiggy OAuth callback is explicitly configured as `https://api.humanslop.in/auth/callback`.
- The backend is the intended MCP caller, preventing Swiggy credentials from being shipped in the app.
- Homie should not store payment details or sensitive transaction payloads.
- MCP access is not resold or exposed to third parties.
- Swiggy attribution should remain visible anywhere MCP data is shown.
