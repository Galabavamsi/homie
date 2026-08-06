# Native Local MVP Runbook

This launches the real local collaboration stack and Flutter Android app. It does not use the web target.

## Prerequisites

- Docker Desktop running.
- Node.js 20 or newer.
- Flutter 3.24 or newer.
- Android SDK and one configured emulator.

## Fast Path

Terminal 1:

```powershell
cd D:\homie
.\scripts\start-local.ps1
```

Terminal 2:

```powershell
cd D:\homie
.\scripts\run-android.ps1
```

The first script starts PostgreSQL, Redis, runs migrations/seeds, and starts Express on port `4000`. The second finds or launches an emulator and runs Flutter with hot reload.

## Manual Path

```powershell
cd D:\homie
docker compose up -d --wait

cd apps\api
Copy-Item .env.example .env
npm install
npm start
```

In another terminal:

```powershell
cd D:\homie\apps\mobile
flutter pub get
flutter emulators
flutter emulators --launch fable_smoke
flutter run -d emulator-5554
```

The emulator uses `http://10.0.2.2:4000`; `localhost` inside Android is the emulator itself.

## Demo Flow

1. Enter a name to create a persisted local guest.
2. Open `HOMIE42` or create a room.
3. Join the same code from a second emulator/device.
4. Cast votes and chat; presence and snapshots update over Socket.IO.
5. Add menu items. Each participant controls their own cart lines.
6. Create your own room to demonstrate host-only checkout.
7. Confirm checkout; the room locks and all clients receive the timeline.

## Proof Commands

```powershell
Invoke-RestMethod http://127.0.0.1:4000/api/health
Invoke-RestMethod http://127.0.0.1:4000/api/ready
Invoke-RestMethod http://127.0.0.1:4000/api/rooms/HOMIE42
```

Expected health fields:

```json
{ "ok": true, "persistence": "postgres", "mcpMode": "mock" }
```

Run the two-client contract test:

```powershell
cd D:\homie\apps\api
npm test
```

## Build And Install APK

```powershell
cd D:\homie\apps\mobile
flutter build apk --debug
flutter install -d emulator-5554 --use-application-binary=build\app\outputs\flutter-apk\app-debug.apk
```

## Swiggy MCP Modes

`mock` is the honest default because Food MCP requires OAuth 2.1 with PKCE and issued access. Once Swiggy provides a development/staging token, set these only in `apps/api/.env`:

```text
SWIGGY_MCP_MODE=live
SWIGGY_MCP_FOOD_URL=https://mcp.swiggy.com/food
SWIGGY_TOKEN=<secret>
SWIGGY_ADDRESS_ID=<saved address returned by get_addresses>
```

Restart Node. Raw `/api/mcp/food` calls and live discovery can be validated without changing Flutter. The typed checkout path fails closed until Swiggy cart variants/add-ons and `get_food_cart` reconciliation are implemented.

## Troubleshooting

- `Cannot reach the Homie API`: verify `/api/health`; cleartext HTTP is enabled only for local Android development.
- Docker pipe missing: open Docker Desktop, then rerun `start-local.ps1`.
- Emulator is black: run `adb shell input keyevent 224` and `adb shell wm dismiss-keyguard`.
- Broken AVD image: launch an AVD whose API image exists or repair it in Device Manager.
- Port 4000 occupied: stop the old Homie Node process before another instance.

## Firecrawl MCP

Codex is configured to launch `firecrawl-mcp` through `npx`. Set the secret in your Windows user environment, then restart Codex:

```powershell
setx FIRECRAWL_API_KEY "your-key"
```

Do not paste or commit the key. The Swiggy docs already captured for this repository remain under `docs/swiggy-scrape/`.
