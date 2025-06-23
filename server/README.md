# Claude Usage Server

This is a local server that provides Claude usage data to the macOS app.
It uses the ccusage npm package directly, avoiding path issues with npx.

## Setup

```bash
cd server
npm install
```

## Run

```bash
npm start
```

The server will run on http://127.0.0.1:3456

## Auto-start (Optional)

To start the server automatically with the app, you can:

1. Add a LaunchAgent plist
2. Or start it from the Swift app using Process

## API

- GET /usage - Returns current usage data in the same format as `ccusage --json`