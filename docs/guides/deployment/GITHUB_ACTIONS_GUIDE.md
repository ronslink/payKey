# GitHub Actions Workflows & Secrets Guide

## Overview
This guide details the CI/CD pipelines configured in `/.github/workflows/`, the secrets required for them to function, and the environment strategies.

## 1. Environments & Deployment Structure

We use GitHub Environments to manage secrets and deployment rules.

| Environment | Branch | Description | Secrets Storage |
|-------------|--------|-------------|-----------------|
| **DEV** | `develop` (future) | Staging environment | Repo Secrets / `DEV` Env |
| **PROD** | `main` | Production environment (DigitalOcean) | `PROD` Environment Secrets |

> [!NOTE] 
> The `deploy-prod.yml` workflow targets the **PROD** environment. Ensure you create this environment in your GitHub repository settings.

## 2. Workflows Breakdown

### Backend CI (`backend-ci.yml`)
- **Trigger**: Push/PR to `main` or `develop`
- **Purpose**: Lint, Build, Unit Test, E2E Test, and (on `main`) build Docker image.
- **Services**: Spins up temporary PostgreSQL and Redis containers for testing.
- **Docker Build**: Pushes to Docker Hub if tests pass.

### Deploy Production (`deploy-prod.yml`)
- **Trigger**: Manual dispatch (for safety) or Push to `main` (if configured)
- **Purpose**: Deploys the entire stack (Infra, Backend, Website) to DigitalOcean via SSH.
- **Key Step**: Generates a secure `.env` file on the server using injected secrets.

### Mobile Android (`mobile-android.yml`)
- **Trigger**: Push/PR to `mobile/**`
- **Purpose**: Runs Flutter analysis, tests, and builds a release APK.
- **Artifact**: Uploads `app-release.apk` for testing.

### Mobile iOS (`mobile-ios.yml`)
- **Trigger**: Push/PR to `mobile/**`
- **Purpose**: Runs Flutter analysis, tests, and builds a release iOS app (unsigned).
- **Artifact**: Uploads `ios-app-bundle`.

## 3. Required Secrets

Configure these secrets in **Settings > Secrets and variables > Actions**.

### Repository Secrets (Global)
These are available to all workflows.

| Secret Name | Description | Used In |
|-------------|-------------|---------|
| `DOCKER_USERNAME` | Docker Hub username | `backend-ci.yml` |
| `DOCKER_PASSWORD` | Docker Hub access token | `backend-ci.yml` |

### PROD Environment Secrets
These are specific to the production production environment.

| Secret Name | Description | Used In |
|-------------|-------------|---------|
| `DO_HOST` | DigitalOcean Droplet IP | `deploy-prod.yml` |
| `DO_USERNAME` | SSH Username (e.g., `root`) | `deploy-prod.yml` |
| `DO_SSH_KEY` | SSH Private Key | `deploy-prod.yml` |
| `DATABASE_URL` | Production DB Connection String | `deploy-prod.yml` |
| `JWT_SECRET` | Production JWT Secret | `deploy-prod.yml` |
| `INTASEND_PUBLISHABLE_KEY` | IntaSend Live Public Key | `deploy-prod.yml` |
| `INTASEND_SECRET` | IntaSend Live Secret Key | `deploy-prod.yml` |
| `STRIPE_SECRET_KEY` | Stripe Live Secret Key | `deploy-prod.yml` |
| `STRIPE_WEBHOOK_SECRET` | Stripe Webhook Secret | `deploy-prod.yml` |
| `CR_PAT` | Container Registry Token (if using GHCR) | `deploy-prod.yml` |

## 4. Mobile Secrets (Future)
When configuring automated store release (Fastlane), you will need:

| Secret Name | Description |
|-------------|-------------|
| `ANDROID_KEYSTORE_BASE64` | Base64 encoded upload keystore |
| `ANDROID_KEY_PASSWORD` | Key password |
| `ANDROID_STORE_PASSWORD` | Keystore password |
| `APP_STORE_CONNECT_API_KEY` | For iOS distribution |

## 5. Troubleshooting Common Issues

### "Docker Login Failed"
- **Cause**: Incorrect `DOCKER_USERNAME` or `DOCKER_PASSWORD`.
- **Fix**: Verify credentials in Repo Secrets.

### "Host key verification failed" (Deployment)
- **Cause**: The GitHub runner doesn't recognize the DO server.
- **Fix**: The `appleboy/ssh-action` handles this mostly, but ensure `DO_HOST` is correct.

### "Database Connection Refused" (CI)
- **Cause**: The `backend-ci.yml` services aren't fully ready.
- **Fix**: The workflow has a health-check loop (`Wait for PostgreSQL`), ensure it isn't timing out.
