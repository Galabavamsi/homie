# Swiggy Builders Club Application Summary

## What Homie Builds

Homie is a collaboration layer for group food ordering. It helps friends, families, flatmates, house parties, hostel rooms, and office teams decide together before checkout.

Swiggy remains the commerce and fulfillment platform. Homie uses Swiggy MCP for restaurant discovery, menus, cart validation, checkout, payments, delivery, and tracking.

## Integration Architecture

- Flutter app for mobile-first collaboration.
- Node.js API as the server-side Swiggy MCP integration point.
- Socket.io for live room state, chat, votes, typing, presence, and cart updates.
- PostgreSQL for durable collaboration data.
- Redis for presence, pub/sub, and ephemeral realtime state.
- Swiggy OAuth callback: `https://api.humanslop.in/auth/callback`.

## Data Handling

Homie stores only collaboration metadata:

- Room details
- Participants
- Messages
- Votes
- Cart ownership mapping
- Activity feed

Homie does not store Swiggy payment credentials, raw payment information, or sensitive transaction data.

## Expected Traffic

Initial demo and private beta: under 1K requests/day.

The backend is designed so MCP request volume can be rate-limited and monitored centrally.

## Use Case Fit

Homie improves ordering, discovery, and dining workflows without obscuring Swiggy's role. Swiggy attribution remains visible in the app and API docs, and all commerce actions are modeled as Swiggy-owned.
