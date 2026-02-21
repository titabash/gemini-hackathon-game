# Deployment Guide

This document describes the deployment procedures for each component of flutter-boilerplate.

## Table of Contents

- [Deployment Overview](#deployment-overview)
- [Environment Preparation](#environment-preparation)
- [Database Migration](#database-migration)
- [Edge Functions Deployment](#edge-functions-deployment)
- [Frontend Deployment](#frontend-deployment)
- [Backend Deployment (Optional)](#backend-deployment-optional)
- [CI/CD Pipeline](#cicd-pipeline)
- [Environment Variables Management](#environment-variables-management)
- [Rollback Procedures](#rollback-procedures)

## Deployment Overview

### Deployment Flow

```
┌─────────────────────────────────┐
│  1. Database Migration          │  ← supabase/migrations/
│     (Supabase CLI)              │
└────────────┬────────────────────┘
             │
┌────────────▼────────────────────┐
│  2. Edge Functions Deployment   │  ← supabase/functions/
│     (Supabase CLI)              │
└────────────┬────────────────────┘
             │
┌────────────▼────────────────────┐
│  3. Frontend Build & Deploy     │  ← frontend/apps/web/
│     (Flutter Web)               │
└─────────────────────────────────┘
             │
┌────────────▼────────────────────┐
│  4. Backend Deploy (Optional)   │  ← backend-py/
│     (Docker / Cloud Run)        │
└─────────────────────────────────┘
```

### Environments

This project assumes the following environments:

- **Development**: Local Supabase (Docker)
- **Staging**: Supabase Project (Staging)
- **Production**: Supabase Project (Production)

## Environment Preparation

### Creating Supabase Project

1. Create project at [Supabase Dashboard](https://supabase.com/dashboard)

2. Obtain project URL and keys
   - Project URL: `https://xxxxx.supabase.co`
   - Anon Key: `eyJhb...`
   - Service Role Key: `eyJhb...`

3. Link to local environment

```bash
# Check project ID
# Supabase Dashboard > Settings > General > Project ID

# Link
supabase link --project-ref your-project-id
```

### Setting Environment Variables

Configure environment variables for each environment:

```bash
# env/frontend/production.json
{
  "SUPABASE_URL": "https://xxxxx.supabase.co",
  "SUPABASE_ANON_KEY": "eyJhb..."
}

# env/backend/production.env
DATABASE_URL=postgresql://...
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJhb...
```

## Database Migration

### Migration to Production Environment

#### 1. Verify Migration Files

```bash
# Check locally generated migrations
ls supabase/migrations/

# Check migration history
make migrate-status
```

#### 2. Verify in Staging Environment

```bash
# Link to staging project
supabase link --project-ref staging-project-id

# Apply migrations
ENV=staging make migrate-deploy

# Verify
supabase db diff
```

#### 3. Deploy to Production Environment

```bash
# Link to production project
supabase link --project-ref production-project-id

# Backup (Important!)
# Create backup at Supabase Dashboard > Database > Backups

# Apply migrations
ENV=production make migrate-deploy

# Verify operation
# Test application to ensure it works properly
```

### Migration Best Practices

- ✅ Always create backup in advance
- ✅ Test in staging first
- ✅ Execute during maintenance window
- ✅ Prepare rollback plan
- ❌ Never execute SQL directly on production database

## Edge Functions Deployment

### Deploy All Functions

```bash
# Deploy all Edge Functions
make deploy-edge-functions

# Or deploy individually
supabase functions deploy function-name
```

### Deploy Individual Functions

```bash
cd supabase/functions

# Deploy specific function
supabase functions deploy helloworld

# Set secrets
supabase secrets set OPENAI_API_KEY=sk-...

# Check deployment logs
supabase functions logs helloworld
```

### Edge Functions Environment Variables

```bash
# List secrets
supabase secrets list

# Set multiple secrets at once
supabase secrets set \
  OPENAI_API_KEY=sk-... \
  ANTHROPIC_API_KEY=sk-... \
  DATABASE_URL=postgresql://...
```

### Verify Deployment

```bash
# Test function operation
curl -i --location --request POST \
  'https://xxxxx.supabase.co/functions/v1/helloworld' \
  --header 'Authorization: Bearer YOUR_ANON_KEY' \
  --header 'Content-Type: application/json' \
  --data '{"name":"Test"}'

# Check logs
supabase functions logs helloworld --tail
```

## Frontend Deployment

### Building Flutter Web

#### 1. Production Build

```bash
cd frontend/apps/web

# Production build with environment variables
flutter build web \
  --release \
  --dart-define=SUPABASE_URL=https://xxxxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhb...

# Build artifacts
# build/web/ is generated
```

#### 2. Check Build Size

```bash
# Analyze build size
flutter build web --release --analyze-size

# Verify tree shaking
flutter build web --release --tree-shake-icons
```

### Hosting Options

#### Option 1: Vercel

```bash
# Install Vercel CLI
npm i -g vercel

# Deploy
cd frontend/apps/web/build/web
vercel --prod
```

#### Option 2: Netlify

```bash
# Install Netlify CLI
npm i -g netlify-cli

# Deploy
cd frontend/apps/web/build/web
netlify deploy --prod --dir=.
```

#### Option 3: Firebase Hosting

```bash
# Install Firebase CLI
npm i -g firebase-tools

# Initialize
firebase init hosting

# Deploy
firebase deploy --only hosting
```

#### Option 4: Supabase Storage (Static Site)

```bash
# After build, upload to Supabase Storage
# Or, create bucket at Supabase Dashboard > Storage
# Create 'website' bucket and set to public
# Upload all files from build/web/*
```

### Building Flutter Mobile

#### Android

```bash
cd frontend/apps/web

# APK (Development)
flutter build apk --debug

# APK (Release)
flutter build apk --release

# App Bundle (Google Play Store)
flutter build appbundle --release
```

#### iOS

```bash
cd frontend/apps/web

# Development build
flutter build ios --debug

# Release build (App Store)
flutter build ios --release

# Sign and upload with Xcode
open ios/Runner.xcworkspace
```

## Backend Deployment (Optional)

Deploy Python backend only when complex transactions or Python-specific processing is required.

### Docker Build

```bash
cd backend-py

# Build Docker image
docker build -t flutter-boilerplate-backend:latest .

# Test locally
docker run -p 8000:8000 \
  -e DATABASE_URL=postgresql://... \
  -e SUPABASE_URL=https://xxxxx.supabase.co \
  flutter-boilerplate-backend:latest
```

### Google Cloud Run

```bash
# Install and authenticate Google Cloud SDK
gcloud auth login
gcloud config set project your-project-id

# Build and push image
gcloud builds submit --tag gcr.io/your-project-id/backend

# Deploy to Cloud Run
gcloud run deploy backend \
  --image gcr.io/your-project-id/backend \
  --platform managed \
  --region asia-northeast1 \
  --allow-unauthenticated \
  --set-env-vars DATABASE_URL=postgresql://...,SUPABASE_URL=https://...
```

### Other Options

- **AWS ECS/Fargate**: Docker container orchestration
- **Heroku**: Easy deployment with `git push heroku main`
- **Railway**: Automatic deployment integrated with GitHub repository

## CI/CD Pipeline

### GitHub Actions

`.github/workflows/deploy.yml`:

```yaml
name: Deploy

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.35.6'

      - name: Setup Supabase CLI
        uses: supabase/setup-cli@v1
        with:
          version: latest

      - name: Link Supabase Project
        run: supabase link --project-ref ${{ secrets.SUPABASE_PROJECT_ID }}
        env:
          SUPABASE_ACCESS_TOKEN: ${{ secrets.SUPABASE_ACCESS_TOKEN }}

      - name: Run Migrations
        run: ENV=production make migrate-deploy

      - name: Deploy Edge Functions
        run: make deploy-edge-functions

      - name: Build Frontend
        run: |
          cd frontend/apps/web
          flutter build web --release \
            --dart-define=SUPABASE_URL=${{ secrets.SUPABASE_URL }} \
            --dart-define=SUPABASE_ANON_KEY=${{ secrets.SUPABASE_ANON_KEY }}

      - name: Deploy to Vercel
        run: vercel --prod --token ${{ secrets.VERCEL_TOKEN }}
```

### Required GitHub Secrets

Configure at Settings > Secrets and variables > Actions:

- `SUPABASE_PROJECT_ID`
- `SUPABASE_ACCESS_TOKEN`
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `VERCEL_TOKEN` (when using Vercel)

## Environment Variables Management

### Management by Environment

```
env/
├── frontend/
│   ├── local.json
│   ├── staging.json
│   └── production.json
├── backend/
│   ├── local.env
│   ├── staging.env
│   └── production.env
└── secrets.env (gitignored)
```

### Secrets Management

**Recommended Tools**:
- **1Password**: Share secrets with team
- **AWS Secrets Manager**: When using AWS
- **Google Secret Manager**: When using GCP
- **GitHub Secrets**: For CI/CD

**Precautions**:
- ❌ Never commit secrets to Git
- ✅ Exclude secret files with `.gitignore`
- ✅ Store environment variables encrypted
- ✅ Rotate regularly

## Rollback Procedures

### Database Rollback

```bash
# 1. Restore from backup at Supabase Dashboard
# Dashboard > Database > Backups > Restore

# 2. Or create reverse migration and apply
# See DEVELOPMENT.md for details
```

### Edge Functions Rollback

```bash
# Revert to previous version code
git revert <commit-hash>

# Redeploy
make deploy-edge-functions
```

### Frontend Rollback

```bash
# Redeploy previous build
# (For Vercel/Netlify, can switch to previous deployment from Dashboard)

# Or build and redeploy previous version
git checkout <previous-tag>
cd frontend/apps/web
flutter build web --release
# Execute deployment command
```

## Deployment Checklist

### Before Deployment

- [ ] All tests pass (`make test-all`)
- [ ] Quality checks pass (`make check-quality`)
- [ ] Verify operation in staging environment
- [ ] Database backup
- [ ] Verify rollback procedures
- [ ] Verify environment variables
- [ ] Check dependency updates

### After Deployment

- [ ] Migrations completed successfully
- [ ] Edge Functions operational
- [ ] Frontend displays properly
- [ ] Authentication flow works
- [ ] API endpoints respond
- [ ] Check error logs
- [ ] Verify performance
- [ ] Security scan

## Troubleshooting

### Migration Errors

```bash
# Check error logs
supabase db remote commit

# Manual rollback
# Execute reverse operations at Supabase Dashboard > SQL Editor
```

### Edge Functions Errors

```bash
# Check logs
supabase functions logs function-name --tail

# Verify environment variables
supabase secrets list

# Redeploy
supabase functions deploy function-name
```

### Frontend Build Errors

```bash
# Clear cache
flutter clean
flutter pub get

# Check dependencies
cd frontend
melos bootstrap

# Rebuild
flutter build web --release
```

## Summary

### Deployment Flow

1. **Local Testing**: `make test-all`, `make check-quality`
2. **Staging Verification**: Deploy to staging environment and verify
3. **Backup**: Database backup
4. **Production Deployment**: Database → Edge Functions → Frontend
5. **Operation Verification**: Verify each feature's operation
6. **Monitoring**: Monitor error logs and performance

### Useful Commands

```bash
# Deployment related
make deploy-edge-functions     # Deploy Edge Functions
make migrate-deploy            # Apply migrations

# Verification
supabase functions logs        # Function logs
supabase db remote commit      # DB verification
```

For more details, refer to the following documents:
- [ARCHITECTURE.md](./ARCHITECTURE.md) - System architecture
- [DEVELOPMENT.md](./DEVELOPMENT.md) - Development workflow
- [TESTING.md](./TESTING.md) - Testing strategy
