# Swiggy MCP Notes

These notes summarize the Swiggy Builders Club docs scraped from:

```text
https://mcp.swiggy.com/builders/docs/
```

The raw local scrape is in `docs/swiggy-scrape/`.

## Authentication

- Swiggy MCP uses OAuth 2.1 with PKCE.
- Redirect URIs must be exact-match allowlisted URLs.
- HTTPS is required for production redirect URIs.
- `http://localhost` is allowed for local development.
- Authorization codes are single-use and short-lived.
- Access tokens should be treated as expiring/revocable; on 401, re-run authorization.

Homie callback:

```text
https://api.humanslop.in/auth/callback
```

## Food MCP Tool Flow

The canonical Food ordering journey is:

```text
get_addresses
search_restaurants
get_restaurant_menu or search_menu
update_food_cart
fetch_food_coupons / apply_food_coupon
get_food_cart
place_food_order
track_food_order
```

Homie's backend now includes a mock JSON-RPC endpoint:

```text
POST /api/mcp/food
```

Example:

```json
{
  "jsonrpc": "2.0",
  "method": "tools/call",
  "params": {
    "name": "search_restaurants",
    "arguments": {
      "addressId": "addr_home_001",
      "query": "biryani"
    }
  },
  "id": 1
}
```

## Food-Specific Product Constraints

- Use `get_addresses` before restaurant search.
- `search_restaurants` requires an `addressId` and query.
- Recommend only restaurants whose `availabilityStatus` is `OPEN`.
- Food cart is tied to a single restaurant; switching restaurants should flush/rebuild the cart.
- Call `get_food_cart` before placing an order.
- Show the cart, bill total, available payment method, and delivery address before placing an order.
- Wait for explicit user confirmation before `place_food_order`.
- Builders Club Food orders are beta-limited to cart values below `₹1000`.
- `place_food_order` is non-idempotent. On uncertain failure, check order history/status before retrying.
- Tracking should not be polled faster than the documented delivery update cadence.

## Production Readiness

Homie should implement these before real MCP production traffic:

- OAuth 2.1 PKCE with exact redirect allowlisting.
- Server-side token handling; no Swiggy tokens in the Flutter app.
- Retry wrapper for read-only tools and idempotent cart/coupon tools.
- Check-then-retry guard for non-idempotent order placement.
- User-visible cart confirmation before order placement.
- Session id/correlation id logging without plaintext Food MCP payload dumps.
- Handling for 401 auth failures, upstream 5xx/timeouts, and future 429 rate limits.
- DPDP-conscious data minimization: collaboration metadata only, no unnecessary Swiggy-originated PII retention.
