# GitHub Secrets Setup Guide for PayKey Testing Framework

## Overview
This guide covers setting up all required GitHub repository secrets for the PayKey CI/CD testing pipeline.

## Required Secrets

### 1. Security & Vulnerability Scanning
```bash
# Snyk Token - for dependency vulnerability scanning
SNYK_TOKEN=<your_snyk_token>

# SonarQube/Cloud Token - for code quality analysis  
SONAR_TOKEN=<your_sonar_token>
```

### 2. Code Coverage Reporting
```bash
# Codecov Token - for test coverage reporting
CODECOV_TOKEN=<your_codecov_token>
```

### 3. Container Registry Access
```bash
# Docker Hub credentials for building/pushing images
DOCKER_USERNAME=<your_docker_username>
DOCKER_PASSWORD=<your_docker_password_or_token>
```

### 4. Database (Optional - if using external DB)
```bash
# Test database password
POSTGRES_PASSWORD=<secure_test_password>
```

## Service Registration Steps

### Step 1: Codecov Setup
1. Visit [codecov.io](https://codecov.io)
2. Sign up with GitHub OAuth
3. Click "Add new repository"
4. Select your PayKey repository
5. Copy the token from repository settings

### Step 2: Snyk Security Setup
1. Visit [snyk.io](https://snyk.io)
2. Sign up for free account
3. Click "Add new project"
4. Connect your GitHub repository
5. Go to Settings → API Token
6. Copy the generated token

### Step 3: SonarCloud Setup
1. Visit [sonarcloud.io](https://sonarcloud.io)
2. Sign up with GitHub
3. Click "Create Organization" → "Import Organization"
4. Select your GitHub account
5. Add your repository
6. Go to My Account → Security
7. Generate and copy token

### Step 4: Docker Hub Setup
1. Visit [hub.docker.com](https://hub.docker.com)
2. Create account or login
3. Go to Account Settings → Security
4. Create access token if preferred over password

### Step 5: GitHub Repository Secrets
1. Go to your repository on GitHub
2. Settings → Secrets and variables → Actions
3. Click "New repository secret"
4. Add each secret individually:

```bash
# Add these one by one:
Name: SNYK_TOKEN
Value: <paste_snyk_token>

Name: CODECOV_TOKEN  
Value: <paste_codecov_token>

Name: SONAR_TOKEN
Value: <paste_sonar_token>

Name: DOCKER_USERNAME
Value: <your_docker_username>

Name: DOCKER_PASSWORD
Value: <your_docker_password>
```

## Verification Commands

After setting up secrets, test your CI/CD pipeline:

```bash
# Check if secrets are properly configured
git status
git add .
git commit -m "feat: Add comprehensive testing framework with CI/CD"
git push origin main

# Check GitHub Actions tab for workflow execution
```

## Next Steps
1. ✅ Set up GitHub secrets
2. ✅ Configure service accounts
3. ✅ Run full test suite via GitHub Actions
4. ✅ Monitor coverage and security reports
5. ✅ Set up branch protection rules

## Troubleshooting

### Common Issues:
- **Secret not found**: Check secret name matches exactly (case-sensitive)
- **Permission denied**: Ensure GitHub Actions has repository access
- **Service authentication**: Verify API tokens are active and have correct permissions

### Contact Support:
- GitHub Actions: [docs.github.com](https://docs.github.com/en/actions)
- Service-specific documentation for each platform

---
*Generated for PayKey Testing Framework Implementation*