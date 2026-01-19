# Payments & Authentication Development Guide

This guide explains how to set up and test the payment and authentication systems in the PayDome development environment.

## 1. Webhook Tunneling (ngrok)

To receive webhooks from payment providers (IntaSend, M-Pesa, Stripe) on your local machine, we use **ngrok**.

### Setup
1.  Ensure your `NGROK_AUTHTOKEN` is set in `backend/.env`.
2.  Start the project using Docker: `docker-compose up`.
3.  Ngrok will automatically start a tunnel to your backend container at port 3000.
4.  Monitor incoming webhooks at [http://localhost:4040](http://localhost:4040).

> [!TIP]
> Make sure the `API_URL` in your `.env` matches your active ngrok URL so the backend generates correct callback links.

---

## 2. Stripe Webhooks

While ngrok works, the **Stripe CLI** is the preferred way to test Stripe events locally.

### Setup
1.  Open a new terminal.
2.  Run the helper script: `./backend/scripts/stripe-listen.sh`.
3.  Copy the `whsec_...` key from the output.
4.  Update `STRIPE_WEBHOOK_SECRET` in `backend/.env`.

---

## 3. Social Login Verification

The backend is configured to verify social login tokens from Apple and Google.

- **Google**: Uses `GOOGLE_CLIENT_ID` from `.env`. This must match the ID in the mobile app's `GoogleService-Info.plist`.
- **Apple**: Uses `APPLE_BUNDLE_ID`, `APPLE_TEAM_ID`, and `APPLE_KEY_ID`. In development, it reads the private key from the path specified in `APPLE_KEY_PATH`.

---

## 4. iOS Media & Documents

To support the latest document loading and avatar features on iOS, the following project configurations are essential:

- **Permissions**: `NSPhotoLibraryUsageDescription`, `NSPhotoLibraryAddUsageDescription`, and `NSCameraUsageDescription` are required in `Info.plist`.
- **File Sharing**: `UIFileSharingEnabled` and `LSSupportsOpeningDocumentsInPlace` are enabled. This allows exported files to be visible in the iOS **Files** app.
- **URL Schemes**: `LSApplicationQueriesSchemes` is configured for `https`, `tel`, and `mailto` to support external links.

---

## 5. Technical Documentation

For deep dives into implementation logic:
- [Payment Payouts & FX Logic](../../docs/technical/payment_payouts_and_fx.md)
