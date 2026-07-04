# Local MVP Runbook

This is the quickest path to record a Swiggy Builders Club local demo.

## 1. Start The Homie API

```bash
cd apps/api
npm install
npm run dev
```

Health check:

```bash
curl http://localhost:4000/api/health
```

## 2. Run The Food Agent Demo

Dry-run mode stops before order placement, matching Swiggy's explicit-confirmation requirement:

```bash
cd apps/api
npm run demo:food -- pizza
```

Expected transcript:

```text
get_addresses
search_restaurants
get_restaurant_menu
update_food_cart
get_food_cart
```

Confirmed mock order mode:

```bash
cd apps/api
npm run demo:food -- pizza --confirm
```

Expected transcript includes:

```text
place_food_order
track_food_order
```

## 3. Run The Flutter Demo

```bash
cd apps/mobile
flutter pub get
flutter run -d chrome
```

Suggested video flow:

```text
Login
Home
Join demo room HOMIE42
Restaurant discovery
Voting
Menu
Shared cart and split
Checkout
Order tracking
```

## 4. Mock vs Live MCP Mode

Default local mode is mock:

```text
SWIGGY_MCP_MODE=mock
```

When you have a valid local OAuth bearer token/session, you can switch the API adapter to proxy Food MCP:

```text
SWIGGY_MCP_MODE=live
SWIGGY_MCP_FOOD_URL=https://mcp.swiggy.com/food
SWIGGY_TOKEN=<your-local-token>
```

Then the same local endpoint proxies the Food MCP JSON-RPC shape:

```text
POST http://localhost:4000/api/mcp/food
```

You can also pass an `Authorization: Bearer <token>` header to that endpoint.

## 5. Builders Club Guardrails Reflected Locally

- OAuth is modeled as OAuth 2.1 with PKCE.
- Production redirect URI remains `https://api.humanslop.in/auth/callback`.
- Food MCP calls use JSON-RPC `tools/call`.
- Dry-run agent mode stops before `place_food_order`.
- Confirmed mock mode demonstrates order placement and tracking.
- Checkout UI shows COD, explicit confirmation, and the current `₹1000` local beta cap.
- Homie stores collaboration data only; Swiggy remains source of truth for commerce.
