# Admin Paneel (Web)

This is the dedicated web admin panel for Child Connect.

## Setup

1. Copy `config.js.example` to `config.js`.
2. Paste your Supabase URL and anon key into `config.js`.
3. Open `index.html` using a local web server.

## Note about .env

`.env.example` is provided for deployment environments.
For direct static HTML usage, `config.js` is the runtime config file read by browser JS.

## Scope

This admin panel controls:
- children profiles
- program catalog
- adoption request statuses
- volunteer application queue
- donor lead queue (auto-tagged from contact messages)
- general contact message statuses

The Flutter app reads the same shared database via RPC functions.
