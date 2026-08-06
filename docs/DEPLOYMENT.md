# Demo And Deployment

## Local Demo

Use [LOCAL_MVP.md](LOCAL_MVP.md). The Flutter app requires the Homie API; it no longer mutates an isolated in-process demo cart.

```powershell
.\scripts\start-local.ps1
.\scripts\run-android.ps1
```

## DNS Shape

The existing `humanslop.in` site can stay unchanged. DNS records are independent by hostname:

```text
humanslop.in          existing website
api.humanslop.in      Homie Node.js API and OAuth callback
homie.humanslop.in    optional invite/deep-link landing page
```

Point only `api.humanslop.in` to the backend provider. Configure TLS there, then register the exact callback:

```text
https://api.humanslop.in/auth/callback
```

DNS alone is not enough: the backend must expose that route over HTTPS, and Swiggy must allowlist the exact URI.

## Backend Requirements

- Always-on Node.js/Express service with WebSocket support.
- Managed PostgreSQL.
- Managed Redis for the Socket.IO adapter.
- TLS and custom domain support.
- Stable outbound IP/gateway if Swiggy requires IP allowlisting.
- Secret manager for OAuth client material and encrypted refresh tokens.
- Health checks against `/api/health` and `/api/ready`.

Render, Railway, Fly.io, or a small cloud VM can host this shape; select the provider only after confirming static egress, WebSocket, region, and database requirements with Swiggy.

## Builders Club Architecture Answer

```text
Homie is a native Flutter application backed by a Node.js/Express API. Socket.IO provides acknowledged realtime room updates, PostgreSQL stores users, rooms, participants, messages, votes, participant-owned cart lines, activity, and order references, and Redis provides cross-instance Socket.IO pub/sub. Swiggy Food MCP is isolated server-side behind an MCPService using OAuth 2.1 with PKCE. Homie stores collaboration metadata only; Swiggy remains the source of truth for restaurant availability, menus, prices, cart validation, checkout, payment, fulfillment, and tracking.
```

## Production Checklist

1. Obtain Swiggy development/staging OAuth details and attribution guidance.
2. Implement authorization-code + PKCE token exchange, encrypted storage, refresh, and revocation.
3. Validate the live Food response schemas in the adapter.
4. Reconcile the consolidated cart with `get_food_cart` before explicit host confirmation.
5. Test uncertain `place_food_order` outcomes without blind retries.
6. Add API rate limiting, structured correlation logs, alerts, backups, and retention jobs.
7. Complete a staging order and gradual production rollout with Swiggy.
