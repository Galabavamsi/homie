# Homie

Homie is a collaborative food-ordering MVP built on top of a mocked Swiggy MCP layer.

It does not replace Swiggy. Homie provides the collaboration experience around group ordering: rooms, invite links, QR codes, chat, restaurant voting, shared carts, bill splitting, AI suggestions, checkout handoff, and shared order tracking.

## Stack

- Flutter, Material 3, Riverpod, GoRouter
- Node.js, Express, Socket.io
- PostgreSQL and Redis placeholders
- Swiggy OAuth placeholder callback: `https://api.humanslop.in/auth/callback`
- Mocked Swiggy MCP service boundary

## Repository

```text
apps/
  mobile/   Flutter app
  api/      Node/Express/Socket.io API
docs/
  API.md
  ARCHITECTURE.md
  BUILDERS_CLUB.md
```

## Run the Mobile App

```bash
cd apps/mobile
flutter pub get
flutter run
```

For a browser demo:

```bash
cd apps/mobile
flutter run -d chrome
```

## Run the API

```bash
cd apps/api
cp .env.example .env
npm install
npm run dev
```

The API starts on `http://localhost:4000` and exposes MCP-shaped routes under `/api/mcp`.

Quick API checks:

```bash
curl http://localhost:4000/api/health
curl http://localhost:4000/api/mcp/restaurants
```

## Screenshots

| Login | Home |
| --- | --- |
| ![Homie login](docs/screenshots/01-login.png) | ![Homie home](docs/screenshots/02-home.png) |

| Room Discovery | Shared Cart |
| --- | --- |
| ![Homie room discovery](docs/screenshots/03-room-discovery.png) | ![Homie shared cart](docs/screenshots/04-shared-cart.png) |

| Checkout | Tracking |
| --- | --- |
| ![Homie checkout](docs/screenshots/05-checkout.png) | ![Homie tracking](docs/screenshots/06-tracking.png) |

| Mobile Room |
| --- |
| ![Homie mobile room](docs/screenshots/07-mobile-room.png) |

## MVP Features

- Splash, Swiggy OAuth placeholder login, home, create room, invite, room, checkout, tracking
- Room code, invite link, QR code
- Realtime-ready chat and activity feed
- Mock restaurant discovery with search and filters
- Live restaurant voting with progress bars
- Menu cards, item ownership, shared cart, and split totals
- Floating AI assistant with group-aware suggestions
- Mock Swiggy checkout and order tracking timeline
- Presence indicators, typing state, live cursors, recent rooms, favorites-ready structure

## Swiggy MCP Boundary

All Swiggy-facing behavior is isolated behind service interfaces:

- `RestaurantService`
- `MenuService`
- `CartService`
- `OrderService`
- `UserService`
- `McpService`

The mock implementations return realistic demo data today. Replacing them with real Swiggy MCP calls should not require changes to room collaboration, UI state, Socket.io events, or bill splitting logic.

## Data Ownership

Homie stores collaboration data only:

- Rooms
- Participants
- Messages
- Votes
- Cart ownership metadata
- Activity feed

Swiggy remains the source of truth for restaurant discovery, menus, pricing, cart validation, checkout, payments, delivery, and order tracking.
