QuickPark

QuickPark is a Flutter mobile application for booking trusted valet
parking.

Technology Stack

Frontend: Flutter / Dart

Authentication: Firebase Authentication + Google Sign-In

Backend: Node.js + Express.js

Database: PostgreSQL

API communication: HTTP REST API

Architecture:

Flutter App
    |
    | HTTP REST API
    v
Express.js Backend
    |
    | SQL
    v
PostgreSQL

Firebase handles authentication. Application data such as profiles,
vehicles, valets and bookings is handled by the Express + PostgreSQL
backend.

Prerequisites

Install:

Flutter SDK

Android Studio / Android SDK

Node.js and npm

PostgreSQL

Git

An Android emulator or Android phone

Check installations:

flutter --version
flutter doctor
node --version
npm --version
psql --version
adb devices

Project Structure

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

Flutter Dependencies

The project uses these main packages:

permission_handler: ^13.0.1
firebase_core: ^4.14.0
firebase_auth: ^6.6.1
google_sign_in: ^7.2.0
cloud_firestore: ^6.9.0
http: ^1.6.0

Install them with:

flutter pub get

Backend Dependencies

The backend uses:

express

cors

dotenv

pg

Go to the backend:

cd backend

Install:

npm install

If dependencies have not been created yet:

npm install express cors dotenv pg

PostgreSQL Setup

Create the database:

CREATE DATABASE quickpark;

Connect:

\c quickpark

The database contains these main tables:

users
vehicles
valets
destinations
bookings

Check them:

\dt

Check users:

SELECT * FROM users;

Check vehicles:

SELECT * FROM vehicles ORDER BY id DESC;

Check bookings:

SELECT * FROM bookings ORDER BY id DESC;

Check users + vehicles:

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

Backend Configuration

Create:

backend/.env

Example:

PORT=3000

DB_HOST=localhost
DB_PORT=5432
DB_NAME=quickpark
DB_USER=postgres
DB_PASSWORD=YOUR_POSTGRES_PASSWORD

Replace YOUR_POSTGRES_PASSWORD with your PostgreSQL password.

Never commit .env to GitHub.

Firebase Setup

QuickPark uses Firebase Authentication.

The Android Firebase configuration file is:

android/app/google-services.json

Make sure the file belongs to the correct Firebase project and Android
application.

Firebase is used for authentication, while the Firebase UID is used by
the backend to associate the authenticated user with PostgreSQL data.

Run the Backend

Open Terminal 1:

cd "C:\Users\ayush\OneDrive\Desktop\quickpark\backend"

Install dependencies:

npm install

Start:

node server.js

Expected:

QuickPark backend running on port 3000

Keep this terminal open.

Test:

http://localhost:3000/api/health

Run the Flutter Application

Open Terminal 2 in the project root:

cd "C:\Users\ayush\OneDrive\Desktop\quickpark"

Install dependencies:

flutter pub get

Run:

flutter run

For a clean rebuild:

flutter clean
flutter pub get
flutter run

Android Emulator

For the Android Emulator, the computer running Node.js is accessed
using:

http://10.0.2.2:3000

Flutter backend URL:

static const String baseUrl = 'http://10.0.2.2:3000';

Do not use localhost from the Android emulator to reach the
Windows backend.

Physical Android Phone

Find the computer's local IP:

ipconfig

Example:

192.168.1.10

Use:

http://192.168.1.10:3000

The phone and computer should be connected to the same network.

Backend API

Health

GET /api/health

Profile

GET /api/profile/:firebaseUid
POST /api/profile

The GET profile endpoint returns the profile and all vehicles.

Vehicles

GET /api/vehicles/:firebaseUid
POST /api/vehicles
PUT /api/vehicles/:vehicleId
PATCH /api/vehicles/:vehicleId/primary
DELETE /api/vehicles/:vehicleId

Valets

GET /api/valets
GET /api/valets/all

Bookings

POST /api/bookings
GET /api/bookings/:firebaseUid
PATCH /api/bookings/:bookingId/cancel

Vehicle Management

Vehicle data is stored in PostgreSQL.

Main fields:

id
user_id
registration_number
car_model
is_primary
created_at

Add Vehicle

Flutter sends:

POST /api/vehicles

The backend inserts the vehicle into PostgreSQL.

The first vehicle is automatically primary.

Edit Vehicle

Flutter sends:

PUT /api/vehicles/:vehicleId

The backend updates the selected vehicle.

Make Primary

Flutter sends:

PATCH /api/vehicles/:vehicleId/primary

The backend removes primary status from the user's other vehicles and
makes the selected vehicle primary.

Remove Vehicle

Flutter sends:

DELETE /api/vehicles/:vehicleId

The vehicle is deleted from PostgreSQL.

If the removed vehicle was primary, another remaining vehicle is
automatically made primary.

Booking Flow

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

A booking can store:

User

Vehicle

Valet

Destination

Amount

Status

Created time

Updated time

The vehicle_id field connects a booking to the selected vehicle.

Schedule

The Schedule control allows the user to select:

Date

Time slot

The current UI uses fixed time slots rather than requiring manual time
entry.

Example:

6:00 PM
6:30 PM
7:00 PM
7:30 PM
8:00 PM
8:30 PM
9:00 PM
9:30 PM

If schedule information needs to be permanently stored in PostgreSQL,
the bookings table and booking API should contain dedicated scheduled
date/time fields.

Git Workflow

Check changes:

git status

Stage everything:

git add .

Commit:

git commit -m "Update QuickPark app"

Push:

git push

If required:

git push origin main

Verify:

git status

Expected:

nothing to commit, working tree clean

Recommended .gitignore

Do not commit secrets or generated files.

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

Troubleshooting

Backend module not found

Go to:

cd backend

Then:

npm install
node server.js

Use:

server.js

as the backend entry point.

Backend is running but Flutter cannot connect

For Android Emulator:

http://10.0.2.2:3000

For a physical phone:

http://YOUR_PC_LAN_IP:3000

Check:

adb devices

PostgreSQL data exists but app does not show it

Check:

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

Then verify that the Firebase UID used by Flutter matches
users.firebase_uid.

App is showing old code

Run:

flutter clean
flutter pub get
flutter run

PostgreSQL connection error

Check:

PostgreSQL service is running.

Database name is quickpark.

Username is correct.

Password in backend/.env is correct.

Port is normally 5432.

Development Checklist

Before running:

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

Start backend:

cd backend
node server.js

Start Flutter in another terminal:

flutter pub get
flutter run

Architecture Summary

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

Responsibility of Each Part

Flutter

Handles:

UI

Navigation

User interactions

Firebase authentication

REST API requests

Profile screens

Vehicle management UI

Valet selection

Booking UI

Schedule selection

Firebase

Handles:

Authentication

Google Sign-In

Phone/OTP authentication where configured

Express.js

Handles:

REST API

PostgreSQL queries

Profile operations

Vehicle CRUD

Primary vehicle logic

Valet data

Booking creation

Booking retrieval

Booking cancellation

PostgreSQL

Stores:

Users

Vehicles

Valets

Destinations

Bookings

Quick Start

Terminal 1

cd "C:\Users\ayush\OneDrive\Desktop\quickpark\backend"
npm install
node server.js

Terminal 2

cd "C:\Users\ayush\OneDrive\Desktop\quickpark"
flutter pub get
flutter run

For Android Emulator:

http://10.0.2.2:3000

For PostgreSQL:

psql -U postgres

Then:

\c quickpark

Check:

\dt

Important Architecture Rule

Keep database communication in this form:

Flutter → Express API → PostgreSQL

Do not put PostgreSQL credentials inside the Flutter application and do
not connect Flutter directly to PostgreSQL
