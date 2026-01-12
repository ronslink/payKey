# PayKey Application Configuration

This guide details how to configure the PayKey mobile application for different environments (Development vs. Production).

## Overview

The application uses **Build-Time Configuration** via Dart's `--dart-define` flag. This allows us to inject secrets and environment-specific URLs during the build process without committing them to the source code.

## Configurable Variables

The following variables can be set at build time:

| Variable | Description | Default (Dev) |
| :--- | :--- | :--- |
| `APP_ENV` | Environment name ("dev", "prod") | `dev` |
| `API_URL` | Backend API Base URL | `http://10.0.2.2:3000` |
| `INTASEND_PUB_KEY` | IntaSend Publishable Key | *(Sandbox Default)* |
| `INTASEND_SECRET_KEY` | IntaSend Secret Key | *(Sandbox Default)* |
| `INTASEND_IS_LIVE` | Set to `true` for Production | `false` |

## How to Build

### 1. Development (Local)
For local development, you can simply run the app. It will fallback to the default internal configuration (Sandbox/Localhost).

```bash
flutter run
```

### 2. Production (Release)
To build a production release, you **MUST** provide the production secrets and configuration.

```bash
flutter build apk --release \
  --dart-define=APP_ENV=prod \
  --dart-define=API_URL=https://api.paydome.co \
  --dart-define=INTASEND_IS_LIVE=true \
  --dart-define=INTASEND_PUB_KEY=ISPubKey_live_YOUR_KEY_HERE \
  --dart-define=INTASEND_SECRET_KEY=ISSecretKey_live_YOUR_KEY_HERE
```

## Configuration File

The logic for reading these values is located in:
`lib/core/config/app_environment.dart`

This class abstracts the low-level `String.fromEnvironment` calls and exposes a clean API for the rest of the app to consume.

### Accessing Config in Code
```dart

## GitHub Actions (CI/CD)

The repository includes a workflow for building the production release automatically:
`.github/workflows/build_android_prod.yml`

### Setting up Secrets
To make this work, you must add the following **Actions Secrets** in your GitHub Repository settings:

| Secret Name | Description |
| :--- | :--- |
| `PROD_API_URL` | The live backend URL (e.g., https://api.paydome.co) |
| `INTASEND_PUB_KEY_PROD` | Your Live Publishable Key |
| `INTASEND_SECRET_KEY_PROD` | Your Live Secret Key |

### Triggering the Build
The build triggers automatically when you push a tag starting with `v` (e.g., `v1.0.0`) or can be run manually via the "Actions" tab.

