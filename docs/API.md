# API Documentation

Base URL in local development:

```text
http://localhost:4000/api
```

## Health

```http
GET /health
```

## Authentication

```http
GET /auth/swiggy
GET /auth/callback
```

`/auth/swiggy` returns a placeholder OAuth authorization URL and the production callback URI:

```text
https://api.humanslop.in/auth/callback
```

## Mock Swiggy MCP Routes

```http
GET /mcp/restaurants?q=pizza&tag=veg
GET /mcp/menu/:restaurantId
POST /mcp/cart
POST /mcp/checkout
GET /mcp/orders/:orderId
```

### POST /mcp/cart

```json
{
  "roomCode": "HOMIE42",
  "cart": [
    {
      "menuItemId": "r0_m1",
      "ownerUserId": "u2",
      "quantity": 1,
      "customization": "Regular"
    }
  ]
}
```

### POST /mcp/checkout

```json
{
  "roomId": "room_1",
  "cart": []
}
```

## Room Routes

```http
POST /rooms
GET /rooms/:code
POST /rooms/:code/join
GET /users/me
```

### POST /rooms

```json
{
  "name": "Friday House Party",
  "budget": 2500
}
```

## Socket.io Events

Client emits:

```text
room:join
chat:message
cart:update
restaurant:vote
typing:start
typing:stop
```

Server emits:

```text
room:presence
room:error
chat:message
cart:update
restaurant:votes
typing:start
typing:stop
```

Example join payload:

```json
{
  "roomCode": "HOMIE42",
  "userId": "u1"
}
```
