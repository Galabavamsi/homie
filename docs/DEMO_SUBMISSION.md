# Homie Builders Club Demo Submission

## Reply Email

**Subject:** Homie Food MCP demo and integration questions

Hi Swiggy Builders Club team,

Thank you for the welcome. I have completed the latest local Android and browser builds of Homie and would be grateful if you could review the attached walkthrough or demo video.

Homie adds a collaboration layer around Swiggy Food. A host creates a shared room; friends, family, flatmates, or teammates join using a code, link, or QR; participants vote on a restaurant, chat in realtime, and add individually owned items to one shared cart. Homie calculates each person's subtotal and requires explicit host confirmation before handing commerce to Swiggy.

The current build has a Flutter Android and web client plus a Node.js/Express backend with Socket.IO, PostgreSQL, and Redis. Room creation, membership, chat, voting, cart ownership, retry deduplication, and checkout authorization run end to end locally. The latest integration adds the allowlisted OAuth 2.1 + PKCE flow, Dynamic Client Registration, server-side token handling, saved-address selection, and live `get_addresses`, `search_restaurants`, and `get_restaurant_menu` calls. The consolidated checkout remains intentionally gated until I complete variants/add-ons mapping, `get_food_cart` reconciliation, payment-method handling, and a safe staging order.

Demo video: [add Drive/YouTube link]

GitHub: https://github.com/Galabavamsi/homie

I would appreciate your engineering guidance on these integration decisions:

1. For a shared room, is it correct for the host to authorize with Swiggy and own the consolidated cart/order while other participants remain Homie-only collaborators, or must every participant authorize?
2. Is it acceptable to keep restaurant voting and per-person item ownership in Homie, then synchronize one consolidated cart through `update_food_cart` after the restaurant is chosen?
3. For stock, price, or add-on changes between selection and checkout, should Homie refresh the menu first, rely on `update_food_cart` errors, or always treat `get_food_cart` as the final canonical reconciliation step?
4. Does the development environment support safe end-to-end `place_food_order` testing, and what payment method, order-value, and delivery-address constraints should the first test follow?
5. After an uncertain timeout from `place_food_order`, which order-history or status tool and correlation field should we use before deciding whether a retry is safe?
6. Are tracking updates polling-only, and what polling interval do you recommend for a room with multiple viewers?
7. Can you share the required Swiggy attribution assets, wording, and co-branding rules for restaurant cards, cart confirmation, and tracking?
8. For a developer integration, should Homie continue using Dynamic Client Registration locally and receive a fixed client ID for production, or should both environments use issued credentials?

I am happy to share the API contract, architecture diagram, native screenshots, or walk your engineering team through the flow.

Cheers,

Galaba Vamsi
Homie

## 60-Second Walkthrough

1. Open the Android or browser build and create a local Homie identity.
2. Show the live-mode home screen with `Connect Swiggy` and the exact callback URI.
3. Complete Swiggy phone + OTP authorization, select a saved address, and show live restaurant/menu data.
4. Create a room and show its QR, share action, and code.
5. Join `HOMIE42`, then show presence, voting, chat, and participant-owned cart lines.
6. Show the checkout guard and explain that live ordering is gated pending cart reconciliation and staging confirmation.
7. Close on: “Homie owns collaboration; Swiggy remains the commerce and fulfillment platform.”

## Record From Android

Start the API and Android app, then use Android Studio's emulator recorder or ADB:

```powershell
adb shell screenrecord --time-limit 90 /sdcard/homie-native.mp4
# Walk through the app, then stop with Ctrl+C.
adb pull /sdcard/homie-native.mp4 docs\demo\homie-native.mp4
```

Keep the video under 90 seconds, hide terminal secrets and OTPs, and show the live/mock label clearly. Do not record access tokens, saved addresses, payment details, or personal account data.
