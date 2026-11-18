# Krushi Mitra backend API (starter)

This is a starter Node.js + Express API. The fertilizer catalogue is demo data copied from the sample list in the Flutter code. The prices and shops are illustrative, not verified live offers.

## 1. Install Node.js
Install the current Node.js LTS version from https://nodejs.org/ and reopen VS Code.

## 2. Open this folder in VS Code
Open the `krushi_mitra_backend` folder, then Terminal > New Terminal.

## 3. Install dependencies and start
Run these commands one at a time:

```powershell
npm install
```

```powershell
npm start
```

You should see `Krushi Mitra API running on http://localhost:5000`.

## 4. Test in your laptop browser
Open:
- http://localhost:5000/api/health
- http://localhost:5000/api/fertilizers

The second URL should return 20 demo fertilizer records.

## 5. Connect an Android phone
Your phone and laptop must be on the same Wi-Fi network. Find the laptop IPv4 address using `ipconfig` in PowerShell. In Flutter, use:

`http://YOUR_LAPTOP_IPV4:5000/api/fertilizers`

Do not use `localhost` in the Android phone app: on the phone, localhost means the phone itself. For Android HTTP development testing, ensure the app permits cleartext HTTP; use HTTPS for production. Windows Firewall may ask permission for Node.js; allow access on your private network.

## API endpoints
- `GET /api/health`
- `GET /api/fertilizers`
- `GET /api/fertilizers?q=urea`
- `GET /api/fertilizers?category=Nitrogen`
- `GET /api/fertilizers/:id`
- `POST /api/payments/create-order` (requires Razorpay test keys in backend `.env`)
- `POST /api/payments/verify` (server-side signature verification)

## Razorpay test setup
Copy `.env.example` to `.env`, then add your Razorpay TEST Key ID and TEST Key Secret from your Razorpay dashboard. Never put the secret in Flutter. Never commit `.env` to Git.

The payment endpoints only create and verify a Razorpay payment. This starter does not yet save orders to a database, manage inventory, or provide production order fulfilment. Add a database and authenticated order records before going live.
