const express = require("express");
const cors = require("cors");
const dotenv = require("dotenv");
const { Pool } = require("pg");
const crypto = require("crypto");

dotenv.config();

const app = express();

// ============================================================
// MIDDLEWARE
// ============================================================

app.use(cors());
app.use(express.json());

// ============================================================
// POSTGRESQL CONNECTION
// ============================================================

const pool = new Pool({
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
});

pool.on("error", (error) => {
  console.error("Unexpected PostgreSQL error:", error);
});

// ============================================================
// HEALTH CHECK
// ============================================================

app.get("/api/health", async (req, res) => {
  try {
    const result = await pool.query("SELECT NOW()");

    res.json({
      success: true,
      message:
        "QuickPark backend is connected to PostgreSQL",
      time: result.rows[0].now,
    });
  } catch (error) {
    console.error("Health check error:", error);

    res.status(500).json({
      success: false,
      message: "Database connection failed",
    });
  }
});

// ============================================================
// GET PROFILE
// ============================================================

app.get(
  "/api/profile/:firebaseUid",
  async (req, res) => {
    const { firebaseUid } = req.params;

    try {
      const result = await pool.query(
        `
        SELECT
          u.id,
          u.firebase_uid,
          u.full_name,
          u.phone_number,
          u.email,

          v.id AS vehicle_id,
          v.registration_number,
          v.car_model

        FROM users u

        LEFT JOIN vehicles v
          ON v.user_id = u.id

        WHERE u.firebase_uid = $1

        LIMIT 1
        `,
        [firebaseUid]
      );

      if (result.rows.length === 0) {
        return res.json({
          success: true,
          profileExists: false,
          profile: null,
        });
      }

      const row = result.rows[0];

      res.json({
        success: true,
        profileExists: true,

        profile: {
          userId: row.id,
          name: row.full_name || "",
          phoneNumber:
            row.phone_number || "",
          email: row.email || "",

          vehicleId:
            row.vehicle_id || null,

          carNumber:
            row.registration_number || "",

          carModel:
            row.car_model || "",
        },
      });
    } catch (error) {
      console.error(
        "Get profile error:",
        error
      );

      res.status(500).json({
        success: false,
        message:
          "Unable to load profile",
      });
    }
  }
);

// ============================================================
// SAVE / UPDATE PROFILE
// ============================================================

app.post(
  "/api/profile",
  async (req, res) => {
    const {
      firebaseUid,
      name,
      phoneNumber,
      email,
      carNumber,
      carModel,
    } = req.body;

    if (!firebaseUid) {
      return res.status(400).json({
        success: false,
        message:
          "Firebase UID is required",
      });
    }

    if (
      !name ||
      !phoneNumber ||
      !carNumber ||
      !carModel
    ) {
      return res.status(400).json({
        success: false,
        message:
          "All profile fields are required",
      });
    }

    const client =
      await pool.connect();

    try {
      await client.query("BEGIN");

      // ======================================================
      // USER
      // ======================================================

      const userResult =
        await client.query(
          `
          INSERT INTO users (
            firebase_uid,
            full_name,
            phone_number,
            email
          )

          VALUES (
            $1,
            $2,
            $3,
            $4
          )

          ON CONFLICT (firebase_uid)

          DO UPDATE SET
            full_name =
              EXCLUDED.full_name,

            phone_number =
              EXCLUDED.phone_number,

            email =
              EXCLUDED.email,

            updated_at =
              CURRENT_TIMESTAMP

          RETURNING id
          `,
          [
            firebaseUid,
            name.trim(),
            phoneNumber.trim(),
            email
                ? email.trim()
                : "",
          ]
        );

      const userId =
        userResult.rows[0].id;

      // ======================================================
      // VEHICLE
      // ======================================================

      const vehicleResult =
        await client.query(
          `
          SELECT id
          FROM vehicles
          WHERE user_id = $1
          LIMIT 1
          `,
          [userId]
        );

      if (
        vehicleResult.rows.length >
        0
      ) {
        await client.query(
          `
          UPDATE vehicles

          SET
            registration_number = $1,
            car_model = $2

          WHERE user_id = $3
          `,
          [
            carNumber
                .trim()
                .toUpperCase(),

            carModel.trim(),

            userId,
          ]
        );
      } else {
        await client.query(
          `
          INSERT INTO vehicles (
            user_id,
            registration_number,
            car_model
          )

          VALUES (
            $1,
            $2,
            $3
          )
          `,
          [
            userId,

            carNumber
                .trim()
                .toUpperCase(),

            carModel.trim(),
          ]
        );
      }

      await client.query("COMMIT");

      res.json({
        success: true,
        message:
          "Profile saved successfully",
      });
    } catch (error) {
      await client.query(
        "ROLLBACK"
      );

      console.error(
        "Save profile error:",
        error
      );

      res.status(500).json({
        success: false,
        message:
          "Unable to save profile",
      });
    } finally {
      client.release();
    }
  }
);

// ============================================================
// GET AVAILABLE VALETS
// ============================================================

app.get(
  "/api/valets",
  async (req, res) => {
    try {
      const result =
        await pool.query(
          `
          SELECT
            id,
            name,
            rating,
            distance_km,
            estimated_arrival_minutes,
            available_spots,
            starting_price,
            is_available

          FROM valets

          WHERE is_available = TRUE

          ORDER BY
            distance_km ASC,
            rating DESC
          `
        );

      res.json({
        success: true,
        valets: result.rows,
      });
    } catch (error) {
      console.error(
        "Get valets error:",
        error
      );

      res.status(500).json({
        success: false,
        message:
          "Unable to load valets",
      });
    }
  }
);

// ============================================================
// GET ALL VALETS
// ============================================================

app.get(
  "/api/valets/all",
  async (req, res) => {
    try {
      const result =
        await pool.query(
          `
          SELECT
            id,
            name,
            rating,
            distance_km,
            estimated_arrival_minutes,
            available_spots,
            starting_price,
            is_available

          FROM valets

          ORDER BY
            distance_km ASC
          `
        );

      res.json({
        success: true,
        valets: result.rows,
      });
    } catch (error) {
      console.error(
        "Get all valets error:",
        error
      );

      res.status(500).json({
        success: false,
        message:
          "Unable to load valets",
      });
    }
  }
);

// ============================================================
// CREATE BOOKING
// ============================================================

app.post(
  "/api/bookings",
  async (req, res) => {
    const {
      firebaseUid,
      valetId,
      destinationName,
    } = req.body;

    // ========================================================
    // VALIDATION
    // ========================================================

    if (!firebaseUid) {
      return res.status(400).json({
        success: false,
        message:
          "Firebase UID is required",
      });
    }

    if (!valetId) {
      return res.status(400).json({
        success: false,
        message:
          "Valet ID is required",
      });
    }

    if (!destinationName) {
      return res.status(400).json({
        success: false,
        message:
          "Destination is required",
      });
    }

    const client =
      await pool.connect();

    try {
      await client.query("BEGIN");

      // ======================================================
      // GET USER
      // ======================================================

      const userResult =
        await client.query(
          `
          SELECT id
          FROM users
          WHERE firebase_uid = $1
          LIMIT 1
          `,
          [firebaseUid]
        );

      if (
        userResult.rows.length ===
        0
      ) {
        await client.query(
          "ROLLBACK"
        );

        return res.status(404).json({
          success: false,
          message:
            "User profile not found. Please complete your profile first.",
        });
      }

      const userId =
        userResult.rows[0].id;

      // ======================================================
      // GET VEHICLE
      // ======================================================

      const vehicleResult =
        await client.query(
          `
          SELECT
            id,
            registration_number,
            car_model

          FROM vehicles

          WHERE user_id = $1

          LIMIT 1
          `,
          [userId]
        );

      if (
        vehicleResult.rows.length ===
        0
      ) {
        await client.query(
          "ROLLBACK"
        );

        return res.status(400).json({
          success: false,
          message:
            "Vehicle profile not found.",
        });
      }

      const vehicleId =
        vehicleResult.rows[0].id;

      // ======================================================
      // GET DESTINATION
      // ======================================================

      const destinationResult =
        await client.query(
          `
          SELECT id, name
          FROM destinations

          WHERE LOWER(name) =
                LOWER($1)

          LIMIT 1
          `,
          [destinationName.trim()]
        );

      if (
        destinationResult.rows
          .length === 0
      ) {
        await client.query(
          "ROLLBACK"
        );

        return res.status(404).json({
          success: false,
          message:
            "Destination not found.",
        });
      }

      const destinationId =
        destinationResult
          .rows[0].id;

      // ======================================================
      // GET VALET
      // ======================================================

      const valetResult =
        await client.query(
          `
          SELECT
            id,
            name,
            starting_price,
            available_spots,
            is_available

          FROM valets

          WHERE id = $1

          FOR UPDATE
          `,
          [valetId]
        );

      if (
        valetResult.rows.length ===
        0
      ) {
        await client.query(
          "ROLLBACK"
        );

        return res.status(404).json({
          success: false,
          message:
            "Valet not found.",
        });
      }

      const valet =
        valetResult.rows[0];

      // ======================================================
      // CHECK AVAILABILITY
      // ======================================================

      if (!valet.is_available) {
        await client.query(
          "ROLLBACK"
        );

        return res.status(400).json({
          success: false,
          message:
            "This valet is currently unavailable.",
        });
      }

      if (
        Number(valet.available_spots) <=
        0
      ) {
        await client.query(
          "ROLLBACK"
        );

        return res.status(400).json({
          success: false,
          message:
            "No parking spots are available.",
        });
      }

      // ======================================================
      // GENERATE BOOKING ID
      // ======================================================

      const bookingId =
        crypto
          .randomUUID()
          .split("-")
          .join("")
          .substring(0, 8)
          .toUpperCase();

      // ======================================================
      // AMOUNT
      // ======================================================

      const amount =
        Number(valet.starting_price);

      // ======================================================
      // INSERT BOOKING
      // ======================================================

      const bookingResult =
        await client.query(
          `
          INSERT INTO bookings (
            booking_id,
            user_id,
            vehicle_id,
            valet_id,
            destination_id,
            amount,
            status
          )

          VALUES (
            $1,
            $2,
            $3,
            $4,
            $5,
            $6,
            $7
          )

          RETURNING
            id,
            booking_id,
            user_id,
            vehicle_id,
            valet_id,
            destination_id,
            amount,
            status,
            created_at,
            updated_at
          `,
          [
            bookingId,
            userId,
            vehicleId,
            valetId,
            destinationId,
            amount,
            "confirmed",
          ]
        );

      // ======================================================
      // DECREASE AVAILABLE SPOTS
      // ======================================================

      await client.query(
        `
        UPDATE valets

        SET
          available_spots =
            available_spots - 1

        WHERE id = $1
        `,
        [valetId]
      );

      // ======================================================
      // COMMIT
      // ======================================================

      await client.query(
        "COMMIT"
      );

      const booking =
        bookingResult.rows[0];

      res.status(201).json({
        success: true,

        message:
          "Booking created successfully",

        booking: {
          id: booking.id,

          bookingId:
            booking.booking_id,

          userId:
            booking.user_id,

          vehicleId:
            booking.vehicle_id,

          valetId:
            booking.valet_id,

          destinationId:
            booking.destination_id,

          amount:
            booking.amount,

          status:
            booking.status,

          valetName:
            valet.name,

          destination:
            destinationResult
              .rows[0].name,

          carNumber:
            vehicleResult
              .rows[0]
              .registration_number,

          carModel:
            vehicleResult
              .rows[0]
              .car_model,

          createdAt:
            booking.created_at,

          updatedAt:
            booking.updated_at,
        },
      });
    } catch (error) {
      await client.query(
        "ROLLBACK"
      );

      console.error(
        "Create booking error:",
        error
      );

      res.status(500).json({
        success: false,
        message:
          "Unable to create booking",
        error:
          process.env.NODE_ENV ===
          "development"
            ? error.message
            : undefined,
      });
    } finally {
      client.release();
    }
  }
);

// ============================================================
// GET USER BOOKINGS
// ============================================================

app.get(
  "/api/bookings/:firebaseUid",
  async (req, res) => {
    const {
      firebaseUid,
    } = req.params;

    try {
      const result =
        await pool.query(
          `
          SELECT
            b.id,
            b.booking_id,
            b.amount,
            b.status,
            b.created_at,
            b.updated_at,

            v.name AS valet_name,

            d.name AS destination_name,
            d.address AS destination_address,

            vh.registration_number,
            vh.car_model

          FROM bookings b

          INNER JOIN users u
            ON u.id = b.user_id

          LEFT JOIN valets v
            ON v.id = b.valet_id

          LEFT JOIN destinations d
            ON d.id = b.destination_id

          LEFT JOIN vehicles vh
            ON vh.id = b.vehicle_id

          WHERE u.firebase_uid = $1

          ORDER BY
            b.created_at DESC
          `,
          [firebaseUid]
        );

      res.json({
        success: true,
        bookings: result.rows,
      });
    } catch (error) {
      console.error(
        "Get bookings error:",
        error
      );

      res.status(500).json({
        success: false,
        message:
          "Unable to load bookings",
      });
    }
  }
);

// ============================================================
// CANCEL BOOKING
// ============================================================

app.patch(
  "/api/bookings/:bookingId/cancel",
  async (req, res) => {
    const {
      bookingId,
    } = req.params;

    const client =
      await pool.connect();

    try {
      await client.query("BEGIN");

      const bookingResult =
        await client.query(
          `
          SELECT
            id,
            valet_id,
            status

          FROM bookings

          WHERE booking_id = $1

          FOR UPDATE
          `,
          [bookingId]
        );

      if (
        bookingResult.rows.length ===
        0
      ) {
        await client.query(
          "ROLLBACK"
        );

        return res.status(404).json({
          success: false,
          message:
            "Booking not found",
        });
      }

      const booking =
        bookingResult.rows[0];

      if (
        booking.status !==
        "confirmed"
      ) {
        await client.query(
          "ROLLBACK"
        );

        return res.status(400).json({
          success: false,
          message:
            "Only confirmed bookings can be cancelled.",
        });
      }

      await client.query(
        `
        UPDATE bookings

        SET
          status = 'cancelled',
          updated_at =
            CURRENT_TIMESTAMP

        WHERE id = $1
        `,
        [booking.id]
      );

      await client.query(
        `
        UPDATE valets

        SET
          available_spots =
            available_spots + 1

        WHERE id = $1
        `,
        [booking.valet_id]
      );

      await client.query(
        "COMMIT"
      );

      res.json({
        success: true,
        message:
          "Booking cancelled successfully",
      });
    } catch (error) {
      await client.query(
        "ROLLBACK"
      );

      console.error(
        "Cancel booking error:",
        error
      );

      res.status(500).json({
        success: false,
        message:
          "Unable to cancel booking",
      });
    } finally {
      client.release();
    }
  }
);
// ============================================================
// GET USER BOOKINGS
// ============================================================

app.get("/api/bookings/:firebaseUid", async (req, res) => {
  const { firebaseUid } = req.params;

  if (!firebaseUid) {
    return res.status(400).json({
      success: false,
      message: "Firebase UID is required",
    });
  }

  try {
    const result = await pool.query(
      `
      SELECT
        b.id,
        b.booking_id,
        b.amount,
        b.status,
        b.created_at,
        b.updated_at,

        u.firebase_uid,

        v.registration_number,
        v.car_model,

        va.id AS valet_id,
        va.name AS valet_name,
        va.rating AS valet_rating,

        d.id AS destination_id,
        d.name AS destination_name,
        d.address AS destination_address

      FROM bookings b

      INNER JOIN users u
        ON u.id = b.user_id

      LEFT JOIN vehicles v
        ON v.id = b.vehicle_id

      LEFT JOIN valets va
        ON va.id = b.valet_id

      LEFT JOIN destinations d
        ON d.id = b.destination_id

      WHERE u.firebase_uid = $1

      ORDER BY b.created_at DESC
      `,
      [firebaseUid]
    );

    res.json({
      success: true,
      bookings: result.rows,
    });
  } catch (error) {
    console.error("Get bookings error:", error);

    res.status(500).json({
      success: false,
      message: "Unable to load bookings",
    });
  }
});

// ============================================================
// START SERVER
// ============================================================

const PORT =
  process.env.PORT || 3000;

app.listen(
  PORT,
  "0.0.0.0",
  () => {
    console.log(
      `QuickPark backend running on port ${PORT}`
    );
  }
);