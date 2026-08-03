# Homie Builders Club Demo Submission

## Files to Send

- Video: `docs/demo/homie-builders-club-demo.mp4`
- Cover image: `docs/demo/homie-builders-club-demo-cover.png`
- Repository: https://github.com/Galabavamsi/homie

## Reply Email

**Subject:** Homie demo - Swiggy Builders Club

Hi Swiggy Builders Club team,

Thank you for following Homie's progress, and apologies for the slightly delayed reply. I have attached the latest short walkthrough of the local MVP.

Homie adds a collaboration layer around Swiggy Food: users create a shared room, invite participants by link, code, or QR, discover and vote on restaurants, add individually owned items to one shared cart, see the live bill split, explicitly confirm checkout, and follow delivery together. Swiggy remains clearly attributed and remains the source of truth for restaurant data, pricing, cart validation, checkout, payment, and delivery.

Demo video: [attach `homie-builders-club-demo.mp4` or add a Drive link]

GitHub: https://github.com/Galabavamsi/homie

The current demo uses a deterministic mock adapter behind the same MCP service boundary. The backend is aligned to the Food MCP `tools/call` flow and can switch from mock to live mode when production or staging credentials are available.

I would also appreciate your guidance on a few implementation decisions:

1. For group ordering, should every room participant complete Swiggy OAuth, or may one host authorize the Swiggy cart and checkout while the other participants collaborate only inside Homie?
2. Is the recommended model to keep participant item ownership and voting in Homie, then send a consolidated cart through `update_food_cart` only after the restaurant is locked?
3. Is host-only explicit confirmation the preferred checkout pattern for a shared room?
4. Can you share the required Swiggy attribution assets or co-branding guidance for the production UI?
5. When the local demo is approved, should we validate the first real order in a staging environment before applying for gradual production access?

I would be happy to walk the engineering team through the architecture or adapt the flow to your recommended collaboration pattern.

Cheers,

Galaba Vamsi
Homie

## 50-Second Narration

> Homie makes ordering food together easier without replacing Swiggy. A host creates a room and invites friends, flatmates, family, or teammates using a QR code, link, or room code. Everyone can discover Swiggy restaurants, vote live, and add their own menu items. Homie tracks who owns each item and calculates the split while keeping the consolidated cart inside Swiggy's current local beta limit. Checkout requires explicit host confirmation, and Swiggy remains responsible for restaurant data, pricing, payment, fulfillment, and delivery. After checkout, the whole room follows the same delivery timeline. Homie owns collaboration; Swiggy remains the commerce platform.

## Re-record

Start the release web app on port 5100, then run:

```bash
cd apps/api
npm install
npm run record:demo
```

Override the default URL or Chrome executable when needed:

```bash
HOMIE_DEMO_URL=http://127.0.0.1:5100 CHROME_PATH=/path/to/chrome npm run record:demo
```
