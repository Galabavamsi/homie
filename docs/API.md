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
POST /mcp/food
GET /mcp/restaurants?q=pizza&tag=veg
GET /mcp/menu/:restaurantId
POST /mcp/cart
POST /mcp/checkout
GET /mcp/orders/:orderId
```

### POST /mcp/food

This route mocks the real Swiggy Food MCP JSON-RPC `tools/call` shape.

```json
{
  "jsonrpc": "2.0",
  "method": "tools/call",
  "params": {
    "name": "search_restaurants",
    "arguments": {
      "addressId": "addr_home_001",
      "query": "pizza"
    }
  },
  "id": 1
}
```

Supported mock Food tools:

```text
get_addresses
search_restaurants
get_restaurant_menu
search_menu
update_food_cart
get_food_cart
fetch_food_coupons
apply_food_coupon
flush_food_cart
place_food_order
get_food_orders
track_food_order
```

The real Swiggy endpoint is modeled as:

```text
POST https://mcp.swiggy.com/food
Authorization: Bearer <SWIGGY_TOKEN>
Content-Type: application/json
```

Production order placement rules from the Swiggy docs:

- Call `get_food_cart` first.
- Show cart items, total, available payment methods, and delivery address.
- Wait for explicit user confirmation.
- Keep beta Food orders below `₹1000`.
- Do not blindly retry `place_food_order`; check existing orders first after network/5xx uncertainty.

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
