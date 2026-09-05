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
// HELPER — GET USER BY FIREBASE UID
// ============================================================

async function getUserByFirebaseUid(firebaseUid, db = pool) {
  const result = await db.query(
    `
      SELECT
        id,
        firebase_uid,
        full_name,
        phone_number,
        email
      FROM users
      WHERE firebase_uid = $1
      LIMIT 1
    `,
    [firebaseUid]
  );

  return result.rows[0] || null;
}

// ============================================================
// HELPER — FORMAT VEHICLE
// ============================================================

function formatVehicle(row) {
  return {
    id: row.id,
    userId: row.user_id,
    registrationNumber: row.registration_number || "",
    carModel: row.car_model || "",
    isPrimary: Boolean(row.is_primary),
    createdAt: row.created_at,
  };
}

// ============================================================
// HEALTH CHECK
// ============================================================

app.get("/api/health", async (req, res) => {
  try {
    const result = await pool.query("SELECT NOW()");

    res.json({
      success: true,
      message: "QuickPark backend is connected to PostgreSQL",
      time: result.rows[0].now,
    });
  } catch (error) {
    console.error("Health check error:", error);

    res.status(500).json({
      success: false,
      message: "Database connection failed",
      error: error.message,
    });
  }
});

// ============================================================
// GET PROFILE
// IMPORTANT:
// Returns profile + ALL vehicles
// ============================================================

app.get("/api/profile/:firebaseUid", async (req, res) => {
  const { firebaseUid } = req.params;

  if (!firebaseUid) {
    return res.status(400).json({
      success: false,
      message: "Firebase UID is required",
    });
  }

  try {
    // ----------------------------------------------------------
    // GET USER
    // ----------------------------------------------------------

    const userResult = await pool.query(
      `
        SELECT
          id,
          firebase_uid,
          full_name,
          phone_number,
          email
        FROM users
        WHERE firebase_uid = $1
        LIMIT 1
      `,
      [firebaseUid]
    );

    if (userResult.rows.length === 0) {
      return res.json({
        success: true,
        profileExists: false,
        profile: null,
        vehicles: [],
      });
    }

    const user = userResult.rows[0];

    // ----------------------------------------------------------
    // GET ALL VEHICLES
    // ----------------------------------------------------------

    const vehiclesResult = await pool.query(
      `
        SELECT
          id,
          user_id,
          registration_number,
          car_model,
          is_primary,
          created_at
        FROM vehicles
        WHERE user_id = $1
        ORDER BY is_primary DESC, id ASC
      `,
      [user.id]
    );

    const vehicles = vehiclesResult.rows.map(formatVehicle);

    // ----------------------------------------------------------
    // PRIMARY VEHICLE
    // ----------------------------------------------------------

    const primaryVehicle =
      vehicles.find((vehicle) => vehicle.isPrimary) ||
      vehicles[0] ||
      null;

    // ----------------------------------------------------------
    // RESPONSE
    // ----------------------------------------------------------

    return res.json({
      success: true,
      profileExists: true,

      profile: {
        userId: user.id,
        firebaseUid: user.firebase_uid,
        name: user.full_name || "",
        phoneNumber: user.phone_number || "",
        email: user.email || "",

        vehicleId: primaryVehicle
          ? primaryVehicle.id
          : null,

        carNumber: primaryVehicle
          ? primaryVehicle.registrationNumber
          : "",

        carModel: primaryVehicle
          ? primaryVehicle.carModel
          : "",

        isPrimary: primaryVehicle
          ? primaryVehicle.isPrimary
          : false,
      },

      vehicles: vehicles,
    });
  } catch (error) {
    console.error("Get profile error:", error);

    res.status(500).json({
      success: false,
      message: "Unable to load profile",
      error: error.message,
    });
  }
});

// ============================================================
// SAVE / UPDATE PROFILE
// ============================================================

app.post("/api/profile", async (req, res) => {
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
      message: "Firebase UID is required",
    });
  }

  if (!name || !phoneNumber) {
    return res.status(400).json({
      success: false,
      message: "Name and phone number are required",
    });
  }

  const client = await pool.connect();

  try {
    await client.query("BEGIN");

    // ----------------------------------------------------------
    // SAVE USER
    // ----------------------------------------------------------

    const userResult = await client.query(
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
          full_name = EXCLUDED.full_name,
          phone_number = EXCLUDED.phone_number,
          email = EXCLUDED.email,
          updated_at = CURRENT_TIMESTAMP

        RETURNING id
      `,
      [
        firebaseUid,
        name.trim(),
        phoneNumber.trim(),
        email ? email.trim() : "",
      ]
    );

    const userId = userResult.rows[0].id;

    // ----------------------------------------------------------
    // OPTIONAL FIRST VEHICLE
    // ----------------------------------------------------------

    if (carNumber && carModel) {
      const vehicleResult = await client.query(
        `
          SELECT id
          FROM vehicles
          WHERE user_id = $1
          ORDER BY is_primary DESC, id ASC
          LIMIT 1
        `,
        [userId]
      );

      if (vehicleResult.rows.length > 0) {
        await client.query(
          `
            UPDATE vehicles
            SET
              registration_number = $1,
              car_model = $2
            WHERE id = $3
          `,
          [
            carNumber.trim().toUpperCase(),
            carModel.trim(),
            vehicleResult.rows[0].id,
          ]
        );
      } else {
        await client.query(
          `
            INSERT INTO vehicles (
              user_id,
              registration_number,
              car_model,
              is_primary
            )
            VALUES (
              $1,
              $2,
              $3,
              TRUE
            )
          `,
          [
            userId,
            carNumber.trim().toUpperCase(),
            carModel.trim(),
          ]
        );
      }
    }

    await client.query("COMMIT");

    res.json({
      success: true,
      message: "Profile saved successfully",
    });
  } catch (error) {
    await client.query("ROLLBACK");

    console.error("Save profile error:", error);

    res.status(500).json({
      success: false,
      message: "Unable to save profile",
      error: error.message,
    });
  } finally {
    client.release();
  }
});

// ============================================================
// GET ALL VEHICLES
// ============================================================

app.get("/api/vehicles/:firebaseUid", async (req, res) => {
  const { firebaseUid } = req.params;

  if (!firebaseUid) {
    return res.status(400).json({
      success: false,
      message: "Firebase UID is required",
    });
  }

  try {
    const user = await getUserByFirebaseUid(firebaseUid);

    if (!user) {
      return res.status(404).json({
        success: false,
        message: "User profile not found",
      });
    }

    const result = await pool.query(
      `
        SELECT
          id,
          user_id,
          registration_number,
          car_model,
          is_primary,
          created_at
        FROM vehicles
        WHERE user_id = $1
        ORDER BY is_primary DESC, id ASC
      `,
      [user.id]
    );

    res.json({
      success: true,
      vehicles: result.rows.map(formatVehicle),
    });
  } catch (error) {
    console.error("Get vehicles error:", error);

    res.status(500).json({
      success: false,
      message: "Unable to load vehicles",
      error: error.message,
    });
  }
});

// ============================================================
// ADD VEHICLE
// ============================================================

app.post("/api/vehicles", async (req, res) => {
  const {
    firebaseUid,
    registrationNumber,
    carModel,
  } = req.body;

  if (!firebaseUid) {
    return res.status(400).json({
      success: false,
      message: "Firebase UID is required",
    });
  }

  if (!registrationNumber || !carModel) {
    return res.status(400).json({
      success: false,
      message:
        "Registration number and car model are required",
    });
  }

  const client = await pool.connect();

  try {
    await client.query("BEGIN");

    const user = await getUserByFirebaseUid(
      firebaseUid,
      client
    );

    if (!user) {
      await client.query("ROLLBACK");

      return res.status(404).json({
        success: false,
        message: "User profile not found",
      });
    }

    // ----------------------------------------------------------
    // DUPLICATE VEHICLE CHECK
    // ----------------------------------------------------------

    const duplicate = await client.query(
      `
        SELECT id
        FROM vehicles
        WHERE user_id = $1
          AND UPPER(registration_number) = UPPER($2)
        LIMIT 1
      `,
      [
        user.id,
        registrationNumber.trim(),
      ]
    );

    if (duplicate.rows.length > 0) {
      await client.query("ROLLBACK");

      return res.status(409).json({
        success: false,
        message: "This vehicle is already added",
      });
    }

    // ----------------------------------------------------------
    // CHECK EXISTING VEHICLES
    // ----------------------------------------------------------

    const countResult = await client.query(
      `
        SELECT COUNT(*)::int AS count
        FROM vehicles
        WHERE user_id = $1
      `,
      [user.id]
    );

    const isFirstVehicle =
      countResult.rows[0].count === 0;

    // ----------------------------------------------------------
    // INSERT VEHICLE
    // ----------------------------------------------------------

    const result = await client.query(
      `
        INSERT INTO vehicles (
          user_id,
          registration_number,
          car_model,
          is_primary
        )
        VALUES (
          $1,
          $2,
          $3,
          $4
        )
        RETURNING
          id,
          user_id,
          registration_number,
          car_model,
          is_primary,
          created_at
      `,
      [
        user.id,
        registrationNumber.trim().toUpperCase(),
        carModel.trim(),
        isFirstVehicle,
      ]
    );

    await client.query("COMMIT");

    res.status(201).json({
      success: true,
      message: "Vehicle added successfully",
      vehicle: formatVehicle(result.rows[0]),
    });
  } catch (error) {
    await client.query("ROLLBACK");

    console.error("Add vehicle error:", error);

    res.status(500).json({
      success: false,
      message: "Unable to add vehicle",
      error: error.message,
    });
  } finally {
    client.release();
  }
});

// ============================================================
// EDIT VEHICLE
// ============================================================

app.put("/api/vehicles/:vehicleId", async (req, res) => {
  const vehicleId = Number(req.params.vehicleId);

  const {
    firebaseUid,
    registrationNumber,
    carModel,
  } = req.body;

  if (!Number.isInteger(vehicleId)) {
    return res.status(400).json({
      success: false,
      message: "Invalid vehicle ID",
    });
  }

  if (!firebaseUid) {
    return res.status(400).json({
      success: false,
      message: "Firebase UID is required",
    });
  }

  if (!registrationNumber || !carModel) {
    return res.status(400).json({
      success: false,
      message:
        "Registration number and car model are required",
    });
  }

  try {
    const user = await getUserByFirebaseUid(firebaseUid);

    if (!user) {
      return res.status(404).json({
        success: false,
        message: "User profile not found",
      });
    }

    // ----------------------------------------------------------
    // DUPLICATE REGISTRATION CHECK
    // ----------------------------------------------------------

    const duplicate = await pool.query(
      `
        SELECT id
        FROM vehicles
        WHERE user_id = $1
          AND UPPER(registration_number) = UPPER($2)
          AND id <> $3
        LIMIT 1
      `,
      [
        user.id,
        registrationNumber.trim(),
        vehicleId,
      ]
    );

    if (duplicate.rows.length > 0) {
      return res.status(409).json({
        success: false,
        message:
          "Another vehicle already uses this registration number",
      });
    }

    // ----------------------------------------------------------
    // UPDATE
    // ----------------------------------------------------------

    const result = await pool.query(
      `
        UPDATE vehicles
        SET
          registration_number = $1,
          car_model = $2
        WHERE id = $3
          AND user_id = $4
        RETURNING
          id,
          user_id,
          registration_number,
          car_model,
          is_primary,
          created_at
      `,
      [
        registrationNumber.trim().toUpperCase(),
        carModel.trim(),
        vehicleId,
        user.id,
      ]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Vehicle not found",
      });
    }

    res.json({
      success: true,
      message: "Vehicle updated successfully",
      vehicle: formatVehicle(result.rows[0]),
    });
  } catch (error) {
    console.error("Edit vehicle error:", error);

    res.status(500).json({
      success: false,
      message: "Unable to edit vehicle",
      error: error.message,
    });
  }
});

// ============================================================
// SET PRIMARY VEHICLE
// ============================================================

app.patch(
  "/api/vehicles/:vehicleId/primary",
  async (req, res) => {
    const vehicleId = Number(req.params.vehicleId);
    const { firebaseUid } = req.body;

    if (!Number.isInteger(vehicleId)) {
      return res.status(400).json({
        success: false,
        message: "Invalid vehicle ID",
      });
    }

    if (!firebaseUid) {
      return res.status(400).json({
        success: false,
        message: "Firebase UID is required",
      });
    }

    const client = await pool.connect();

    try {
      await client.query("BEGIN");

      const user = await getUserByFirebaseUid(
        firebaseUid,
        client
      );

      if (!user) {
        await client.query("ROLLBACK");

        return res.status(404).json({
          success: false,
          message: "User profile not found",
        });
      }

      // --------------------------------------------------------
      // CHECK VEHICLE BELONGS TO USER
      // --------------------------------------------------------

      const vehicleCheck = await client.query(
        `
          SELECT
            id,
            registration_number,
            car_model
          FROM vehicles
          WHERE id = $1
            AND user_id = $2
          LIMIT 1
        `,
        [
          vehicleId,
          user.id,
        ]
      );

      if (vehicleCheck.rows.length === 0) {
        await client.query("ROLLBACK");

        return res.status(404).json({
          success: false,
          message: "Vehicle not found",
        });
      }

      // --------------------------------------------------------
      // REMOVE PRIMARY FROM ALL VEHICLES
      // --------------------------------------------------------

      await client.query(
        `
          UPDATE vehicles
          SET is_primary = FALSE
          WHERE user_id = $1
        `,
        [user.id]
      );

      // --------------------------------------------------------
      // MAKE SELECTED VEHICLE PRIMARY
      // --------------------------------------------------------

      const result = await client.query(
        `
          UPDATE vehicles
          SET is_primary = TRUE
          WHERE id = $1
            AND user_id = $2
          RETURNING
            id,
            user_id,
            registration_number,
            car_model,
            is_primary,
            created_at
        `,
        [
          vehicleId,
          user.id,
        ]
      );

      await client.query("COMMIT");

      res.json({
        success: true,
        message: "Primary vehicle updated successfully",
        vehicle: formatVehicle(result.rows[0]),
      });
    } catch (error) {
      await client.query("ROLLBACK");

      console.error(
        "Set primary vehicle error:",
        error
      );

      res.status(500).json({
        success: false,
        message: "Unable to set primary vehicle",
        error: error.message,
      });
    } finally {
      client.release();
    }
  }
);

// ============================================================
// REMOVE VEHICLE
// ============================================================

app.delete(
  "/api/vehicles/:vehicleId",
  async (req, res) => {
    const vehicleId = Number(req.params.vehicleId);
    const { firebaseUid } = req.body;

    if (!Number.isInteger(vehicleId)) {
      return res.status(400).json({
        success: false,
        message: "Invalid vehicle ID",
      });
    }

    if (!firebaseUid) {
      return res.status(400).json({
        success: false,
        message: "Firebase UID is required",
      });
    }

    const client = await pool.connect();

    try {
      await client.query("BEGIN");

      const user = await getUserByFirebaseUid(
        firebaseUid,
        client
      );

      if (!user) {
        await client.query("ROLLBACK");

        return res.status(404).json({
          success: false,
          message: "User profile not found",
        });
      }

      // --------------------------------------------------------
      // GET VEHICLE
      // --------------------------------------------------------

      const vehicleResult = await client.query(
        `
          SELECT
            id,
            is_primary
          FROM vehicles
          WHERE id = $1
            AND user_id = $2
          FOR UPDATE
        `,
        [
          vehicleId,
          user.id,
        ]
      );

      if (vehicleResult.rows.length === 0) {
        await client.query("ROLLBACK");

        return res.status(404).json({
          success: false,
          message: "Vehicle not found",
        });
      }

      const wasPrimary =
        Boolean(vehicleResult.rows[0].is_primary);

      // --------------------------------------------------------
      // DELETE VEHICLE
      // --------------------------------------------------------

      await client.query(
        `
          DELETE FROM vehicles
          WHERE id = $1
            AND user_id = $2
        `,
        [
          vehicleId,
          user.id,
        ]
      );

      // --------------------------------------------------------
      // IF PRIMARY WAS DELETED,
      // MAKE ANOTHER VEHICLE PRIMARY
      // --------------------------------------------------------

      if (wasPrimary) {
        await client.query(
          `
            UPDATE vehicles
            SET is_primary = TRUE
            WHERE id = (
              SELECT id
              FROM vehicles
              WHERE user_id = $1
              ORDER BY id ASC
              LIMIT 1
            )
          `,
          [user.id]
        );
      }

      await client.query("COMMIT");

      res.json({
        success: true,
        message: "Vehicle removed successfully",
      });
    } catch (error) {
      await client.query("ROLLBACK");

      console.error(
        "Remove vehicle error:",
        error
      );

      res.status(500).json({
        success: false,
        message: "Unable to remove vehicle",
        error: error.message,
      });
    } finally {
      client.release();
    }
  }
);

// ============================================================
// GET AVAILABLE VALETS
// ============================================================

app.get("/api/valets", async (req, res) => {
  try {
    const result = await pool.query(
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
    console.error("Get valets error:", error);

    res.status(500).json({
      success: false,
      message: "Unable to load valets",
      error: error.message,
    });
  }
});

// ============================================================
// GET ALL VALETS
// ============================================================

app.get("/api/valets/all", async (req, res) => {
  try {
    const result = await pool.query(
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
        ORDER BY distance_km ASC
      `
    );

    res.json({
      success: true,
      valets: result.rows,
    });
  } catch (error) {
    console.error("Get all valets error:", error);

    res.status(500).json({
      success: false,
      message: "Unable to load valets",
      error: error.message,
    });
  }
});

// ============================================================
// CREATE BOOKING
// ============================================================

app.post("/api/bookings", async (req, res) => {
  const {
    firebaseUid,
    valetId,
    destinationName,
    vehicleId,
  } = req.body;

  if (!firebaseUid) {
    return res.status(400).json({
      success: false,
      message: "Firebase UID is required",
    });
  }

  if (!valetId) {
    return res.status(400).json({
      success: false,
      message: "Valet ID is required",
    });
  }

  if (!destinationName) {
    return res.status(400).json({
      success: false,
      message: "Destination is required",
    });
  }

  const client = await pool.connect();

  try {
    await client.query("BEGIN");

    // ----------------------------------------------------------
    // GET USER
    // ----------------------------------------------------------

    const userResult = await client.query(
      `
        SELECT id
        FROM users
        WHERE firebase_uid = $1
        LIMIT 1
      `,
      [firebaseUid]
    );

    if (userResult.rows.length === 0) {
      await client.query("ROLLBACK");

      return res.status(404).json({
        success: false,
        message:
          "User profile not found. Please complete your profile first.",
      });
    }

    const userId = userResult.rows[0].id;

    // ----------------------------------------------------------
    // GET VEHICLE
    // ----------------------------------------------------------

    let vehicleResult;

    if (vehicleId) {
      vehicleResult = await client.query(
        `
          SELECT
            id,
            registration_number,
            car_model,
            is_primary
          FROM vehicles
          WHERE id = $1
            AND user_id = $2
          LIMIT 1
        `,
        [
          vehicleId,
          userId,
        ]
      );
    } else {
      vehicleResult = await client.query(
        `
          SELECT
            id,
            registration_number,
            car_model,
            is_primary
          FROM vehicles
          WHERE user_id = $1
          ORDER BY
            is_primary DESC,
            id ASC
          LIMIT 1
        `,
        [userId]
      );
    }

    if (vehicleResult.rows.length === 0) {
      await client.query("ROLLBACK");

      return res.status(400).json({
        success: false,
        message: "Vehicle profile not found.",
      });
    }

    const vehicle = vehicleResult.rows[0];

    // ----------------------------------------------------------
    // GET DESTINATION
    // ----------------------------------------------------------

    const destinationResult = await client.query(
      `
        SELECT
          id,
          name,
          address
        FROM destinations
        WHERE LOWER(name) = LOWER($1)
        LIMIT 1
      `,
      [destinationName.trim()]
    );

    if (destinationResult.rows.length === 0) {
      await client.query("ROLLBACK");

      return res.status(404).json({
        success: false,
        message: "Destination not found.",
      });
    }

    const destinationId =
      destinationResult.rows[0].id;

    // ----------------------------------------------------------
    // GET VALET
    // ----------------------------------------------------------

    const valetResult = await client.query(
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

    if (valetResult.rows.length === 0) {
      await client.query("ROLLBACK");

      return res.status(404).json({
        success: false,
        message: "Valet not found.",
      });
    }

    const valet = valetResult.rows[0];

    // ----------------------------------------------------------
    // CHECK AVAILABILITY
    // ----------------------------------------------------------

    if (!valet.is_available) {
      await client.query("ROLLBACK");

      return res.status(400).json({
        success: false,
        message:
          "This valet is currently unavailable.",
      });
    }

    if (Number(valet.available_spots) <= 0) {
      await client.query("ROLLBACK");

      return res.status(400).json({
        success: false,
        message:
          "No parking spots are available.",
      });
    }

    // ----------------------------------------------------------
    // GENERATE BOOKING ID
    // ----------------------------------------------------------

    const bookingId = crypto
      .randomUUID()
      .replace(/-/g, "")
      .substring(0, 8)
      .toUpperCase();

    // ----------------------------------------------------------
    // AMOUNT
    // ----------------------------------------------------------

    const amount =
      Number(valet.starting_price);

    // ----------------------------------------------------------
    // INSERT BOOKING
    // ----------------------------------------------------------

    const bookingResult = await client.query(
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
        vehicle.id,
        valetId,
        destinationId,
        amount,
        "confirmed",
      ]
    );

    // ----------------------------------------------------------
    // DECREASE AVAILABLE SPOTS
    // ----------------------------------------------------------

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

    await client.query("COMMIT");

    const booking =
      bookingResult.rows[0];

    res.status(201).json({
      success: true,
      message: "Booking created successfully",

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
          destinationResult.rows[0].name,

        carNumber:
          vehicle.registration_number,

        carModel:
          vehicle.car_model,

        createdAt:
          booking.created_at,

        updatedAt:
          booking.updated_at,
      },
    });
  } catch (error) {
    await client.query("ROLLBACK");

    console.error(
      "Create booking error:",
      error
    );

    res.status(500).json({
      success: false,
      message: "Unable to create booking",
      error:
        process.env.NODE_ENV === "development"
          ? error.message
          : undefined,
    });
  } finally {
    client.release();
  }
});

// ============================================================
// GET USER BOOKINGS
// ============================================================

app.get(
  "/api/bookings/:firebaseUid",
  async (req, res) => {
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

            v.id AS vehicle_id,
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
        message: "Unable to load bookings",
        error: error.message,
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
    const { bookingId } = req.params;

    const client = await pool.connect();

    try {
      await client.query("BEGIN");

      // --------------------------------------------------------
      // GET BOOKING
      // --------------------------------------------------------

      const bookingResult = await client.query(
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

      if (bookingResult.rows.length === 0) {
        await client.query("ROLLBACK");

        return res.status(404).json({
          success: false,
          message: "Booking not found",
        });
      }

      const booking =
        bookingResult.rows[0];

      // --------------------------------------------------------
      // CHECK STATUS
      // --------------------------------------------------------

      if (booking.status !== "confirmed") {
        await client.query("ROLLBACK");

        return res.status(400).json({
          success: false,
          message:
            "Only confirmed bookings can be cancelled.",
        });
      }

      // --------------------------------------------------------
      // CANCEL BOOKING
      // --------------------------------------------------------

      await client.query(
        `
          UPDATE bookings
          SET
            status = 'cancelled',
            updated_at = CURRENT_TIMESTAMP
          WHERE id = $1
        `,
        [booking.id]
      );

      // --------------------------------------------------------
      // RETURN PARKING SPOT
      // --------------------------------------------------------

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

      await client.query("COMMIT");

      res.json({
        success: true,
        message: "Booking cancelled successfully",
      });
    } catch (error) {
      await client.query("ROLLBACK");

      console.error(
        "Cancel booking error:",
        error
      );

      res.status(500).json({
        success: false,
        message: "Unable to cancel booking",
        error: error.message,
      });
    } finally {
      client.release();
    }
  }
);

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