# Demo and Deployment

## Local Demo

Start the backend:

```bash
cd apps/api
npm install
npm run dev
```

Open these health/demo endpoints:

```text
http://localhost:4000/api/health
http://localhost:4000/api/mcp/restaurants
http://localhost:4000/api/mcp/menu/r0
```

Start the Flutter app:

```bash
cd apps/mobile
flutter pub get
flutter run -d chrome
```

The app currently uses mocked MCP data in the Flutter layer, so the visual demo works even if the backend is not running. The backend exists to show the production integration shape.

## Production DNS Shape

The existing `humanslop.in` website can remain unchanged.

Use subdomains:

```text
humanslop.in          existing website
api.humanslop.in      Homie Node.js backend
homie.humanslop.in    Homie Flutter web demo
```

Swiggy OAuth redirect URI:

```text
https://api.humanslop.in/auth/callback
```

## Backend Hosting

Recommended MVP hosting:

- Railway for Node.js, PostgreSQL, Redis, HTTPS, custom domains, and later static outbound IPs.
- Render is also fine for Node.js hosting and static outbound IPs on paid plans.

For Swiggy MCP production access, deploy the backend first, enable static outbound IPs if required, then share the final allowlist IPs with Swiggy.

## Builders Club Form Answers

Redirect URI:

```text
https://api.humanslop.in/auth/callback
```

Static IP ranges or gateway IPs:

```text
For the MVP demo, Homie uses mocked/local Swiggy MCP responses. For production MCP access, the backend will be deployed at api.humanslop.in with static outbound IPs enabled before go-live, and the final allowlist IPs will be shared with Swiggy during onboarding.
```

Architecture overview:

```text
Homie is a Flutter mobile app backed by a Node.js/Express API with Socket.io for real-time room collaboration. PostgreSQL stores rooms, participants, messages, votes, and cart ownership metadata, while Redis handles presence, typing indicators, and realtime sync. Swiggy MCP calls are isolated server-side behind an MCPService layer for restaurant discovery, menu retrieval, cart sync, checkout, and order tracking. Homie stores collaboration data only; Swiggy remains the source of truth for restaurants, pricing, payments, delivery, and tracking.
```
