# Development Setup

## Prerequisites

Before getting started, ensure you have the following installed:

- **Node.js**: v18+ (for backend and website)
- **Dart/Flutter**: 3.10+ (for mobile app)
- **PostgreSQL**: 14+ (for database)
- **Git**: 2.30+ (version control)

## Environment Setup

### 1. Clone the Repository

```bash
git clone https://github.com/TrendySloth1001/keepit.git
cd keepit
```

### 2. Backend Setup

Navigate to the backend directory:

```bash
cd backend
```

#### Install Dependencies
```bash
npm install
```

#### Configure Environment
Create a `.env` file in the backend directory:

```env
# Database
DATABASE_URL="postgresql://user:password@localhost:5432/keepit_dev"

# Google OAuth
GOOGLE_CLIENT_ID="your-client-id.apps.googleusercontent.com"
GOOGLE_CLIENT_SECRET="your-secret"

# Server
PORT=3000
NODE_ENV="development"

# JWT
JWT_SECRET="your-jwt-secret-change-this"
JWT_EXPIRY="1h"

# CORS
CORS_ORIGIN="http://localhost:3030"
```

#### Setup Database

```bash
# Create database (if not exists)
createdb keepit_dev

# Run migrations
npx prisma migrate deploy

# Generate Prisma client
npx prisma generate
```

#### Start Backend

```bash
npm run dev
```

Backend will be available at `http://localhost:3000`

### 3. Frontend Setup

Navigate to the frontend directory:

```bash
cd ../frontend
```

#### Install Dependencies
```bash
flutter pub get
```

#### Configure Google Sign-In

Update `lib/constants/env.ts`:

```dart
const String GOOGLE_CLIENT_ID = "your-client-id.apps.googleusercontent.com";
const String BACKEND_URL = "http://localhost:3000";
```

#### Run on Android Emulator

```bash
# Start emulator first
emulator -avd Pixel_4_API_30

# Run app
flutter run
```

#### Build APK

```bash
flutter build apk --release
```

### 4. Website Setup

Navigate to the website directory:

```bash
cd ../website
```

#### Install Dependencies
```bash
npm install
```

#### Start Development Server

```bash
npm run dev
```

Website will be available at `http://localhost:3030`

#### Build for Production

```bash
npm run build
npm start
```

## Development Workflow

### Backend Development

```bash
cd backend

# Watch mode (auto-restart on changes)
npm run dev

# Run tests
npm test

# Lint and format
npm run lint
npm run format

# Build for production
npm run build
```

### Flutter Development

```bash
cd frontend

# Run with verbose output
flutter run -v

# Hot reload
# Press 'R' in terminal

# Hot restart
# Press 'r' in terminal

# Run tests
flutter test

# Format code
dart format lib/
```

### Website Development

```bash
cd website

# Development server with hot reload
npm run dev

# Production build
npm run build

# Run production build locally
npm start

# Lint TypeScript
npm run lint
```

## Database Management

### Prisma Studio

Visual database explorer:

```bash
cd backend
npx prisma studio
```

Access at `http://localhost:5555`

### Database Commands

```bash
# View current state
npx prisma db status

# Create a migration
npx prisma migrate dev --name "add_new_feature"

# Reset database (development only!)
npx prisma migrate reset

# Seed database
npx prisma db seed
```

## Debugging

### Backend Debugging

#### VS Code Debug Configuration

Add to `.vscode/launch.json`:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "type": "node",
      "request": "launch",
      "name": "Launch Backend",
      "program": "${workspaceFolder}/backend/src/server.ts",
      "preLaunchTask": "tsc: build",
      "outFiles": ["${workspaceFolder}/backend/dist/**/*.js"]
    }
  ]
}
```

#### Environment Debugging

```bash
cd backend

# Check environment variables
node -e "console.log(process.env)"

# Test database connection
npx prisma db execute --stdin < test.sql
```

### Frontend Debugging

#### Flutter DevTools

```bash
flutter pub global activate devtools
flutter pub global run devtools

# In another terminal
flutter run
```

Then press 'd' to open DevTools in browser.

### Website Debugging

Use browser DevTools (F12) with source maps enabled in development mode.

## Testing

### Backend Tests

```bash
cd backend
npm test
npm test -- --watch
npm test -- --coverage
```

### Flutter Tests

```bash
cd frontend
flutter test
flutter test --coverage
```

### Website Tests

```bash
cd website
npm test
```

## Code Quality

### Linting

```bash
# Backend
cd backend && npm run lint

# Frontend
cd frontend && flutter analyze

# Website
cd website && npm run lint
```

### Formatting

```bash
# Backend
cd backend && npm run format

# Frontend
cd frontend && dart format lib/ test/

# Website
cd website && prettier --write .
```

## Common Issues

### Database Connection Failed

**Problem**: Cannot connect to PostgreSQL

**Solution**:
1. Verify PostgreSQL is running: `pg_isready`
2. Check connection string in `.env`
3. Verify database exists: `psql -l | grep keepit`

### Port Already in Use

**Problem**: `EADDRINUSE: address already in use :::3000`

**Solution**:
```bash
# Find process using port
lsof -i :3000

# Kill process
kill -9 <PID>
```

### Flutter Build Issues

**Problem**: Build fails with Gradle errors

**Solution**:
```bash
flutter clean
flutter pub get
flutter pub upgrade
```

### Node Module Issues

**Problem**: Module not found errors

**Solution**:
```bash
rm -rf node_modules package-lock.json
npm install
```

## Performance Tips

1. **Backend**: Use `NODE_ENV=development` for development logging
2. **Frontend**: Enable breakpoints in Chrome DevTools for debugging
3. **Database**: Create indexes for frequently queried fields
4. **Website**: Use Next.js ISR for static content caching

## Getting Help

- Check existing [Issues](../ISSUES.md)
- Read the [Wiki](.)
- Open a new GitHub issue with:
  - Clear description
  - Steps to reproduce
  - Environment details
  - Error messages/logs
