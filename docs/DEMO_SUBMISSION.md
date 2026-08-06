# Homie Builders Club Demo Submission

## Reply Email

**Subject:** Homie native MVP demo and Food MCP integration questions

Hi Swiggy Builders Club team,

Thank you for following up, and apologies for sending this after the requested date. I have completed the latest native Android MVP of Homie and would be grateful if you could still review it.

Homie adds a collaboration layer around Swiggy Food. A host creates a shared room; friends, family, flatmates, or teammates join using a code, link, or QR; participants vote on a restaurant, chat in realtime, and add individually owned items to one shared cart. Homie calculates each person's subtotal and requires explicit host confirmation before handing commerce to Swiggy.

The current build has a Flutter Android client and a Node.js/Express backend with Socket.IO, PostgreSQL, and Redis. Room creation, membership, chat, voting, cart ownership, retry deduplication, and checkout authorization are running end to end locally. Swiggy restaurant/menu/order calls remain behind a clearly labeled local MCP stub until OAuth development or staging access is issued.

Demo video: [add Drive/YouTube link]

GitHub: https://github.com/Galabavamsi/homie

I would appreciate your engineering guidance on these integration decisions:

1. Should a collaborative room use one host's Swiggy OAuth session for the consolidated cart and order, while other participants remain Homie-only collaborators, or must every participant authorize with Swiggy?
2. Is it acceptable to keep voting and per-person item ownership in Homie, then synchronize one consolidated cart through `update_food_cart` after the restaurant is chosen?
3. For stock, price, or add-on changes between participant selection and checkout, should Homie re-fetch the menu first, rely on `update_food_cart` errors, or always treat `get_food_cart` as the final canonical reconciliation step?
4. Does the staging/development environment support safe end-to-end `place_food_order` testing, and what payment method and delivery address constraints should the first test follow?
5. After an uncertain timeout from non-idempotent `place_food_order`, which order-history/status tool and correlation field should we use before deciding whether a retry is safe?
6. Are tracking updates polling-only, and what interval do you recommend for a room with multiple viewers?
7. Can you share required Swiggy attribution assets, wording, and co-branding rules for restaurant cards, cart confirmation, and tracking?
8. For a developer integration, should Homie use Dynamic Client Registration locally and receive a fixed client ID for production, or will both environments use issued credentials?

I am happy to share the API contract, architecture diagram, native screenshots, or walk your engineering team through the flow.

Cheers,

Galaba Vamsi
Homie

## 60-Second Walkthrough

1. Open the native Android app and create a local identity.
2. Show the home screen's honest `local Swiggy MCP stub` attribution.
3. Create a room and show its QR, share action, and code.
4. Join `HOMIE42`, then show presence and restaurant discovery.
5. Vote, add a dish, and show the participant-owned cart and split.
6. Send a chat message and briefly show it in a second client or the room API.
7. Open a host-created room, confirm checkout, and show the locked room/tracking state.
8. Close on: “Homie owns collaboration; Swiggy remains the commerce platform.”

## Record From Android

Start the API and Android app, then use Android Studio's emulator recorder or ADB:

```powershell
adb shell screenrecord --time-limit 90 /sdcard/homie-native.mp4
# Walk through the app, then stop with Ctrl+C.
adb pull /sdcard/homie-native.mp4 docs\demo\homie-native.mp4
```

Keep the video under 90 seconds, hide terminal secrets, and show the stub/live label so the demo does not imply unissued Swiggy access.
