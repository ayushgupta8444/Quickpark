# QuickPark

QuickPark is a Flutter mobile application for discovering valet parking locations, selecting vehicles, making/scheduling bookings, viewing booking status, and managing bookings.

## Tech Stack

- **Frontend:** Flutter + Dart + Material UI
- **Backend:** Node.js + Express.js
- **Database:** PostgreSQL
- **Authentication:** Firebase Authentication (currently retained for development/testing)
- **HTTP:** REST APIs using Dart `http`
- **Payment:** Current payment screen is UI/testing only; no live payment gateway is included yet.

## Project Structure

```text
quickpark/
├── android/
├── ios/
├── lib/
│   ├── features/
│   │   ├── booking/
│   │   │   ├── booking_details_screen.dart
│   │   │   ├── payment_screen.dart
│   │   │   ├── booking_confirmed_screen.dart
│   │   │   ├── booking_scheduled_screen.dart
│   │   │   └── my_bookings_screen.dart
│   │   ├── destination/
│   │   │   └── destination_screen.dart
│   │   ├── valet/
│   │   │   └── valet_selection_screen.dart
│   │   └── profile/
│   │       └── profile_screen.dart
│   └── main.dart
├── assets/
│   └── images/
│       └── quickpark_logo.png
├── backend/
│   ├── server.js
│   ├── package.json
│   └── .env
├── pubspec.yaml
├── pubspec.lock
├── .gitignore
└── README.md
```

File names/locations may evolve as development continues.

---

## Requirements

Install:

1. Flutter SDK
2. Android Studio + Android SDK
3. Node.js (LTS recommended)
4. PostgreSQL
5. Git

Verify:

```bash
flutter --version
flutter doctor
dart --version
node --version
npm --version
psql --version
git --version
```

---

## Flutter Dependencies

The current project uses these important packages:

```yaml
dependencies:
  flutter:
    sdk: flutter

  permission_handler: ^13.0.1
  firebase_core: ^4.14.0
  firebase_auth: ^6.6.1
  google_sign_in: ^7.2.0
  cloud_firestore: ^6.9.0
  http: ^1.6.0
```

Install them with:

```bash
flutter pub get
```

### Package purpose

| Package | Purpose |
|---|---|
| `permission_handler` | Runtime permissions |
| `firebase_core` | Firebase initialization |
| `firebase_auth` | Login/authentication |
| `google_sign_in` | Google sign-in support |
| `cloud_firestore` | Existing/legacy Firestore functionality |
| `http` | Flutter → Express REST API communication |

> Keep `pubspec.yaml` as the source of truth for exact dependency versions.

---

# Firebase Setup

Firebase Authentication is currently retained for login/testing.

For Android, the Firebase configuration normally lives at:

```text
android/app/google-services.json
```

If cloning this repository on another machine, configure the Firebase Android app and add the required configuration file.

Do not commit private credentials or API secrets.

---

# PostgreSQL Setup

Create the database:

```sql
CREATE DATABASE quickpark;
```

Connect:

```bash
psql -U postgres
```

Then:

```sql
\c quickpark
\dt
```

The application database contains the main entities:

```text
users
vehicles
valets
destinations
bookings
```

If PostgreSQL-based OTP authentication is enabled later, an additional table can be used:

```text
otp_verifications
```

Inspect tables with:

```sql
\d users
\d vehicles
\d bookings
```

---

# Backend Setup

Backend location:

```text
backend/server.js
```

Install dependencies:

```bash
cd backend
npm install
```

Core backend packages are:

```bash
npm install express pg cors dotenv
```

If JWT authentication is added:

```bash
npm install jsonwebtoken
```

> Prefer the dependencies already declared in `backend/package.json`; only run the install commands above if those packages are missing.

---

# Environment Variables

Create:

```text
backend/.env
```

Example:

```env
PORT=3000

DB_HOST=localhost
DB_PORT=5432
DB_NAME=quickpark
DB_USER=postgres
DB_PASSWORD=YOUR_POSTGRES_PASSWORD
```

Replace `YOUR_POSTGRES_PASSWORD` with your local PostgreSQL password.

Add to `.gitignore`:

```gitignore
.env
*.env
```

Never commit database passwords, API keys, JWT secrets, SMS credentials, or payment secrets.

---

# Start the Backend

From the project root:

```bash
cd backend
node server.js
```

The API runs on:

```text
http://localhost:3000
```

Health check:

```text
GET /api/health
```

---

# Android Emulator Networking

An Android Emulator cannot normally access your PC backend using `localhost`.

Use:

```text
http://10.0.2.2:3000
```

Example:

```dart
const String baseUrl = 'http://10.0.2.2:3000';
```

For a physical Android device, use your computer's LAN IP:

```text
http://192.168.x.x:3000
```

The phone and computer must be on the same network.

---

# Run the Flutter App

From the project root:

```bash
flutter clean
flutter pub get
flutter run
```

See connected devices:

```bash
flutter devices
```

Run on a specific device:

```bash
flutter run -d DEVICE_ID
```

---

# Main App Flow

## Normal booking

```text
Login
  ↓
Destination
  ↓
Valet Selection
  ↓
Select Vehicle
  ↓
Confirm Booking
  ↓
Payment UI
  ↓
Booking Confirmed
  ↓
My Bookings
```

## Scheduled booking

```text
Destination
  ↓
Valet Selection
  ↓
Schedule Booking
  ↓
Select Date
  ↓
Select Time Slot
  ↓
Confirm Schedule
  ↓
Booking Scheduled
```

---

# Booking Screens

### `booking_details_screen.dart`

Displays:

- Valet information
- Destination
- ETA
- User's vehicles
- Selected vehicle
- Estimated total
- Confirm Booking action

### `payment_screen.dart`

Current UI includes:

- UPI
- Credit/Debit Card
- Cash / Pay at Valet
- Booking summary
- Total amount
- Pay button

The current payment screen is a **development/testing UI**. It is not a real payment gateway.

### `booking_confirmed_screen.dart`

Displays successful booking information including:

- Booking ID
- Valet
- Vehicle
- Destination
- Amount
- Tracking action

### `booking_scheduled_screen.dart`

Displays:

- Booking Scheduled
- 6-digit booking ID
- Vehicle
- Destination
- Scheduled date/time
- Duration
- Amount
- Assigned valet
- Edit Time
- Cancel Schedule

### `my_bookings_screen.dart`

Displays booking history and separates bookings into states such as:

- Active Service
- Upcoming

---

# Backend API

The current backend contains REST endpoints for major operations.

Common routes include:

```text
GET    /api/health

GET    /api/profile/:firebaseUid
POST   /api/profile

GET    /api/vehicles/:firebaseUid
POST   /api/vehicles
PUT    /api/vehicles/:vehicleId
PATCH  /api/vehicles/:vehicleId/primary
DELETE /api/vehicles/:vehicleId

GET    /api/valets
GET    /api/valets/all

POST   /api/bookings
GET    /api/bookings/:firebaseUid
```

The project also contains PostgreSQL-oriented profile, vehicle, and booking API implementations using user ID/phone-number based routes.

When changing API contracts, update both:

```text
Flutter client
      ↕
Express routes
      ↕
PostgreSQL
```

---

# Booking Statuses

The UI can handle statuses such as:

```text
confirmed
in_progress
arriving
arrived
vehicle_received
parking
parked
retrieving
ready_for_pickup
completed
cancelled
```

Keep backend/database status values consistent with the Flutter filtering logic.

---

# Development Authentication

Firebase Authentication is currently used for login while the application is being built/tested.

The longer-term architecture can migrate authentication to PostgreSQL + Express + OTP if required.

Until that migration is complete:

```text
Firebase Authentication
        ↓
Flutter
        ↓
Express REST API
        ↓
PostgreSQL application data
```

Do not remove Firebase packages/configuration until every Firebase-dependent screen has been migrated.

---

# Payment

The payment page is currently only a UI/testing layer.

Current flow:

```text
Confirm Booking
      ↓
Payment Screen
      ↓
Pay
      ↓
Booking creation / confirmation
```

A production payment gateway should later be added with:

- Server-side payment verification
- Order creation
- Payment signature/webhook verification
- Secure API keys
- Failed-payment handling
- Refund handling

Never put secret payment credentials inside Flutter code.

---

# Troubleshooting

## Flutter dependencies

```bash
flutter clean
flutter pub get
flutter analyze
flutter run
```

## Backend not reachable

Check:

1. PostgreSQL is running.
2. `quickpark` database exists.
3. `backend/.env` is correct.
4. Express is running.
5. Flutter uses the correct base URL.
6. Android emulator uses `10.0.2.2`, not `localhost`.

## PostgreSQL

```bash
psql -U postgres
```

Then:

```sql
\l
\c quickpark
\dt
```

## Android

Run:

```bash
flutter doctor
```

Then:

```bash
flutter clean
flutter pub get
flutter run
```

Avoid randomly changing Gradle/Kotlin/AGP versions. Inspect the versions currently configured by the Flutter project first.

---

# Fresh Clone Installation

Clone:

```bash
git clone YOUR_GITHUB_REPOSITORY_URL
cd quickpark
```

Install Flutter dependencies:

```bash
flutter pub get
```

Configure Firebase for authentication if required.

Create PostgreSQL database:

```sql
CREATE DATABASE quickpark;
```

Configure:

```text
backend/.env
```

Install backend dependencies:

```bash
cd backend
npm install
```

Start backend:

```bash
node server.js
```

Open another terminal:

```bash
cd quickpark
flutter run
```

---

# Recommended Development Order

1. Start PostgreSQL
2. Start Express
3. Verify `/api/health`
4. Start Flutter
5. Test login
6. Test destination selection
7. Test valet selection
8. Test vehicle selection
9. Test normal booking
10. Test payment UI
11. Test booking confirmation
12. Test scheduled booking
13. Test My Bookings
14. Integrate production payment gateway later

---

# Git Workflow

Check changes:

```bash
git status
```

Add:

```bash
git add .
```

Commit:

```bash
git commit -m "Update QuickPark app"
```

Push:

```bash
git push origin main
```

Before pushing, make sure secrets are ignored:

```bash
git status
```

Never commit:

```text
.env
database passwords
API keys
private credentials
payment secrets
SMS provider credentials
```

---

# License

QuickPark is currently a private/development project.

Add an appropriate open-source license before publicly distributing the source code.
