# API

Local base URL:

```text
http://127.0.0.1:4000/api
```

Errors use one envelope:

```json
{
  "error": {
    "code": "mixed_restaurant_cart",
    "message": "A shared room can checkout from one restaurant at a time."
  }
}
```

## Service

```http
GET /health
GET /ready
GET /auth/swiggy
GET /auth/callback
```

`/health` reports active persistence and MCP modes. `/ready` verifies the repository connection.

## Local Identity

```http
POST /users/guest
```

```json
{ "name": "Vamsi" }
```

## Collaboration

```http
POST /rooms
GET  /rooms/:code
POST /rooms/:code/join
POST /rooms/:code/messages
PUT  /rooms/:code/vote
PUT  /rooms/:code/cart/items/:itemId
POST /rooms/:code/checkout
GET  /collaboration/orders/:orderId
```

Create a room:

```json
{
  "name": "Friday House Party",
  "budget": 2500,
  "hostUserId": "user-id"
}
```

Set a cart line. The backend retrieves the canonical item and price from `MenuService`:

```json
{
  "userId": "user-id",
  "restaurantId": "r0",
  "quantity": 2,
  "customization": "Regular",
  "operationId": "client-generated-uuid"
}
```

Checkout:

```json
{
  "userId": "host-user-id",
  "confirmed": true,
  "operationId": "client-generated-uuid"
}
```

Every retryable mutation accepts `operationId`. Reusing it returns the original snapshot instead of applying the mutation twice.

## Swiggy Adapter

```http
GET  /mcp/restaurants?q=pizza&tag=veg
GET  /mcp/menu/:restaurantId
POST /mcp/food
POST /demo/food-agent
```

`POST /mcp/food` models MCP JSON-RPC tool calls:

```json
{
  "jsonrpc": "2.0",
  "method": "tools/call",
  "params": {
    "name": "search_restaurants",
    "arguments": { "query": "biryani" }
  },
  "id": 1
}
```

In `SWIGGY_MCP_MODE=live`, the adapter calls `https://mcp.swiggy.com/food` with a server-side bearer token. Local mode returns deterministic fixtures.

## Socket.IO

Client mutations:

```text
room:join
chat:send
vote:cast
cart:set
typing:start
typing:stop
```

Server events:

```text
room:snapshot
room:presence
typing:changed
```

Mutation acknowledgement:

```json
{ "ok": true, "data": { "room": {}, "messages": [], "votes": {}, "cart": [] } }
```

Failures use `{ "ok": false, "error": { "code": "...", "message": "..." } }`. After each successful mutation, the server broadcasts a complete versioned room snapshot, avoiding client-side merge conflicts.
