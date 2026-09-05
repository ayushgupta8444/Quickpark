# QuickPark

QuickPark is a Flutter mobile application for booking trusted valet
parking.

## Technology Stack

-   **Frontend:** Flutter / Dart
-   **Authentication:** Firebase Authentication + Google Sign-In
-   **Backend:** Node.js + Express.js
-   **Database:** PostgreSQL
-   **API communication:** HTTP REST API

Architecture:

``` text
Flutter App
    |
    | HTTP REST API
    v
Express.js Backend
    |
    | SQL
    v
PostgreSQL
```

Firebase handles authentication. Application data such as profiles,
vehicles, valets and bookings is handled by the Express + PostgreSQL
backend.

------------------------------------------------------------------------

## Prerequisites

Install:

1.  Flutter SDK
2.  Android Studio / Android SDK
3.  Node.js and npm
4.  PostgreSQL
5.  Git
6.  An Android emulator or Android phone

Check installations:

``` powershell
flutter --version
flutter doctor
node --version
npm --version
psql --version
adb devices
```

------------------------------------------------------------------------

## Project Structure

``` text
quickpark/
│
├── android/
├── assets/
│   └── images/
│       ├── quickpark_logo.png
│       └── quickpark_logo2.png
│
├── lib/
│   ├── profile/
│   ├── booking/
│   └── ...
│
├── backend/
│   ├── server.js
│   ├── package.json
│   └── .env
│
├── pubspec.yaml
├── pubspec.lock
└── README.md
```

------------------------------------------------------------------------

## Flutter Dependencies

The project uses these main packages:

``` yaml
permission_handler: ^13.0.1
firebase_core: ^4.14.0
firebase_auth: ^6.6.1
google_sign_in: ^7.2.0
cloud_firestore: ^6.9.0
http: ^1.6.0
```

Install them with:

``` powershell
flutter pub get
```

------------------------------------------------------------------------

## Backend Dependencies

The backend uses:

-   express
-   cors
-   dotenv
-   pg

Go to the backend:

``` powershell
cd backend
```

Install:

``` powershell
npm install
```

If dependencies have not been created yet:

``` powershell
npm install express cors dotenv pg
```

------------------------------------------------------------------------

# PostgreSQL Setup

Create the database:

``` sql
CREATE DATABASE quickpark;
```

Connect:

``` sql
\c quickpark
```

The database contains these main tables:

``` text
users
vehicles
valets
destinations
bookings
```

Check them:

``` sql
\dt
```

Check users:

``` sql
SELECT * FROM users;
```

Check vehicles:

``` sql
SELECT * FROM vehicles ORDER BY id DESC;
```

Check bookings:

``` sql
SELECT * FROM bookings ORDER BY id DESC;
```

Check users + vehicles:

``` sql
SELECT
    u.id AS user_id,
    u.firebase_uid,
    u.full_name,
    u.phone_number,
    u.email,
    v.id AS vehicle_id,
    v.registration_number,
    v.car_model,
    v.is_primary
FROM users u
LEFT JOIN vehicles v ON v.user_id = u.id
ORDER BY u.id, v.id;
```

------------------------------------------------------------------------

# Backend Configuration

Create:

``` text
backend/.env
```

Example:

``` env
PORT=3000

DB_HOST=localhost
DB_PORT=5432
DB_NAME=quickpark
DB_USER=postgres
DB_PASSWORD=YOUR_POSTGRES_PASSWORD
```

Replace `YOUR_POSTGRES_PASSWORD` with your PostgreSQL password.

**Never commit `.env` to GitHub.**

------------------------------------------------------------------------

# Firebase Setup

QuickPark uses Firebase Authentication.

The Android Firebase configuration file is:

``` text
android/app/google-services.json
```

Make sure the file belongs to the correct Firebase project and Android
application.

Firebase is used for authentication, while the Firebase UID is used by
the backend to associate the authenticated user with PostgreSQL data.

------------------------------------------------------------------------

# Run the Backend

Open Terminal 1:

``` powershell
cd "C:\Users\ayush\OneDrive\Desktop\quickpark\backend"
```

Install dependencies:

``` powershell
npm install
```

Start:

``` powershell
node server.js
```

Expected:

``` text
QuickPark backend running on port 3000
```

Keep this terminal open.

Test:

``` text
http://localhost:3000/api/health
```

------------------------------------------------------------------------

# Run the Flutter Application

Open Terminal 2 in the project root:

``` powershell
cd "C:\Users\ayush\OneDrive\Desktop\quickpark"
```

Install dependencies:

``` powershell
flutter pub get
```

Run:

``` powershell
flutter run
```

For a clean rebuild:

``` powershell
flutter clean
flutter pub get
flutter run
```

------------------------------------------------------------------------

# Android Emulator

For the Android Emulator, the computer running Node.js is accessed
using:

``` text
http://10.0.2.2:3000
```

Flutter backend URL:

``` dart
static const String baseUrl = 'http://10.0.2.2:3000';
```

Do **not** use `localhost` from the Android emulator to reach the
Windows backend.

------------------------------------------------------------------------

# Physical Android Phone

Find the computer's local IP:

``` powershell
ipconfig
```

Example:

``` text
192.168.1.10
```

Use:

``` text
http://192.168.1.10:3000
```

The phone and computer should be connected to the same network.

------------------------------------------------------------------------

# Backend API

## Health

``` http
GET /api/health
```

## Profile

``` http
GET /api/profile/:firebaseUid
POST /api/profile
```

The GET profile endpoint returns the profile and **all vehicles**.

## Vehicles

``` http
GET /api/vehicles/:firebaseUid
POST /api/vehicles
PUT /api/vehicles/:vehicleId
PATCH /api/vehicles/:vehicleId/primary
DELETE /api/vehicles/:vehicleId
```

## Valets

``` http
GET /api/valets
GET /api/valets/all
```

## Bookings

``` http
POST /api/bookings
GET /api/bookings/:firebaseUid
PATCH /api/bookings/:bookingId/cancel
```

------------------------------------------------------------------------

# Vehicle Management

Vehicle data is stored in PostgreSQL.

Main fields:

``` text
id
user_id
registration_number
car_model
is_primary
created_at
```

### Add Vehicle

Flutter sends:

``` http
POST /api/vehicles
```

The backend inserts the vehicle into PostgreSQL.

The first vehicle is automatically primary.

### Edit Vehicle

Flutter sends:

``` http
PUT /api/vehicles/:vehicleId
```

The backend updates the selected vehicle.

### Make Primary

Flutter sends:

``` http
PATCH /api/vehicles/:vehicleId/primary
```

The backend removes primary status from the user's other vehicles and
makes the selected vehicle primary.

### Remove Vehicle

Flutter sends:

``` http
DELETE /api/vehicles/:vehicleId
```

The vehicle is deleted from PostgreSQL.

If the removed vehicle was primary, another remaining vehicle is
automatically made primary.

------------------------------------------------------------------------

# Booking Flow

``` text
Destination
    ↓
Valet Location
    ↓
Pricing Tier
    ↓
Schedule
    ↓
Vehicle
    ↓
Booking Details
    ↓
Create Booking
    ↓
PostgreSQL
```

A booking can store:

-   User
-   Vehicle
-   Valet
-   Destination
-   Amount
-   Status
-   Created time
-   Updated time

The `vehicle_id` field connects a booking to the selected vehicle.

------------------------------------------------------------------------

# Schedule

The Schedule control allows the user to select:

1.  Date
2.  Time slot

The current UI uses fixed time slots rather than requiring manual time
entry.

Example:

``` text
6:00 PM
6:30 PM
7:00 PM
7:30 PM
8:00 PM
8:30 PM
9:00 PM
9:30 PM
```

If schedule information needs to be permanently stored in PostgreSQL,
the `bookings` table and booking API should contain dedicated scheduled
date/time fields.

------------------------------------------------------------------------

# Git Workflow

Check changes:

``` powershell
git status
```

Stage everything:

``` powershell
git add .
```

Commit:

``` powershell
git commit -m "Update QuickPark app"
```

Push:

``` powershell
git push
```

If required:

``` powershell
git push origin main
```

Verify:

``` powershell
git status
```

Expected:

``` text
nothing to commit, working tree clean
```

------------------------------------------------------------------------

# Recommended .gitignore

Do not commit secrets or generated files.

``` gitignore
# Flutter
.dart_tool/
.packages
build/
.flutter-plugins
.flutter-plugins-dependencies

# Android
android/.gradle/
android/local.properties

# Node
node_modules/

# Environment / secrets
.env
*.env

# IDE
.vscode/
.idea/

# OS
.DS_Store
Thumbs.db
```

------------------------------------------------------------------------

# Troubleshooting

## Backend module not found

Go to:

``` powershell
cd backend
```

Then:

``` powershell
npm install
node server.js
```

Use:

``` text
server.js
```

as the backend entry point.

## Backend is running but Flutter cannot connect

For Android Emulator:

``` text
http://10.0.2.2:3000
```

For a physical phone:

``` text
http://YOUR_PC_LAN_IP:3000
```

Check:

``` powershell
adb devices
```

## PostgreSQL data exists but app does not show it

Check:

``` sql
SELECT
    u.id AS user_id,
    u.firebase_uid,
    u.full_name,
    v.id AS vehicle_id,
    v.registration_number,
    v.car_model,
    v.is_primary
FROM users u
LEFT JOIN vehicles v ON v.user_id = u.id
ORDER BY u.id, v.id;
```

Then verify that the Firebase UID used by Flutter matches
`users.firebase_uid`.

## App is showing old code

Run:

``` powershell
flutter clean
flutter pub get
flutter run
```

## PostgreSQL connection error

Check:

-   PostgreSQL service is running.
-   Database name is `quickpark`.
-   Username is correct.
-   Password in `backend/.env` is correct.
-   Port is normally `5432`.

------------------------------------------------------------------------

# Development Checklist

Before running:

``` text
[ ] PostgreSQL is running
[ ] quickpark database exists
[ ] users table exists
[ ] vehicles table exists
[ ] valets table exists
[ ] destinations table exists
[ ] bookings table exists
[ ] backend/.env is configured
[ ] npm dependencies installed
[ ] backend/server.js is running
[ ] Firebase configuration exists
[ ] Flutter dependencies installed
[ ] Android emulator/phone connected
```

Start backend:

``` powershell
cd backend
node server.js
```

Start Flutter in another terminal:

``` powershell
flutter pub get
flutter run
```

------------------------------------------------------------------------

# Architecture Summary

``` text
                    QuickPark
                       |
              +--------+--------+
              |                 |
              v                 v
        Firebase Auth       Flutter App
              |                 |
              | Firebase UID    |
              +--------+--------+
                       |
                       v
                 Express.js API
                       |
                       v
                  PostgreSQL
                       |
          +------------+------------+
          |            |            |
          v            v            v
        Users       Vehicles      Bookings
                       |
                       v
                     Valets
                       |
                       v
                 Destinations
```

## Responsibility of Each Part

### Flutter

Handles:

-   UI
-   Navigation
-   User interactions
-   Firebase authentication
-   REST API requests
-   Profile screens
-   Vehicle management UI
-   Valet selection
-   Booking UI
-   Schedule selection

### Firebase

Handles:

-   Authentication
-   Google Sign-In
-   Phone/OTP authentication where configured

### Express.js

Handles:

-   REST API
-   PostgreSQL queries
-   Profile operations
-   Vehicle CRUD
-   Primary vehicle logic
-   Valet data
-   Booking creation
-   Booking retrieval
-   Booking cancellation

### PostgreSQL

Stores:

-   Users
-   Vehicles
-   Valets
-   Destinations
-   Bookings

------------------------------------------------------------------------

# Quick Start

### Terminal 1

``` powershell
cd "C:\Users\ayush\OneDrive\Desktop\quickpark\backend"
npm install
node server.js
```

### Terminal 2

``` powershell
cd "C:\Users\ayush\OneDrive\Desktop\quickpark"
flutter pub get
flutter run
```

For Android Emulator:

``` text
http://10.0.2.2:3000
```

For PostgreSQL:

``` powershell
psql -U postgres
```

Then:

``` sql
\c quickpark
```

Check:

``` sql
\dt
```

------------------------------------------------------------------------

## Important Architecture Rule

Keep database communication in this form:

``` text
Flutter → Express API → PostgreSQL
```

Do not put PostgreSQL credentials inside the Flutter application and do
not connect Flutter directly to PostgreSQL.
