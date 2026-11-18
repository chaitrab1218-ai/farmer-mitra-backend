require("dotenv").config();
const express  = require("express");
const cors     = require("cors");
const { Pool } = require("pg");
const { jwtVerify, createRemoteJWKSet } = require("jose");
const jwt      = require("jsonwebtoken");

const app  = express();
app.use(cors());
app.use(express.json());

const PORT           = Number(process.env.PORT || 5000);
const NEON_AUTH_BASE = process.env.NEON_AUTH_BASE_URL ||
  "https://ep-mute-bird-azaz0r2u.neonauth.c-3.ap-southeast-1.aws.neon.tech/neondb/auth";
const JWKS_URL       = `${NEON_AUTH_BASE}/.well-known/jwks.json`;
const JWT_SECRET     = process.env.JWT_SECRET || "krushi_mitra_jwt_secret_dev_key";

// Remote JWKS for Neon Auth tokens
const JWKS = createRemoteJWKSet(new URL(JWKS_URL));

// ── Neon DB ──────────────────────────────────────────────────────────────────
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

// ── Seed data ─────────────────────────────────────────────────────────────────
const SEED = [
  { name: "Urea",                    category: "Nitrogen",       brand: "IFFCO",      weight: "45 kg", price: 266.50, shop: "Demo Agro Centre",   district: "Bengaluru", phone: "", stock: 20 },
  { name: "Urea",                    category: "Nitrogen",       brand: "KRIBHCO",    weight: "45 kg", price: 268,    shop: "Demo Farmers Store", district: "Bengaluru", phone: "", stock: 12 },
  { name: "DAP",                     category: "Phosphatic",     brand: "IFFCO",      weight: "50 kg", price: 1350,   shop: "Demo Agro Centre",   district: "Bengaluru", phone: "", stock: 8  },
  { name: "DAP",                     category: "Phosphatic",     brand: "Coromandel", weight: "50 kg", price: 1380,   shop: "Demo Farmers Store", district: "Bengaluru", phone: "", stock: 0  },
  { name: "MOP",                     category: "Potassic",       brand: "IPL",        weight: "50 kg", price: 1700,   shop: "Demo Agro Centre",   district: "Bengaluru", phone: "", stock: 15 },
  { name: "NPK 10:26:26",            category: "Complex",        brand: "Coromandel", weight: "50 kg", price: 1500,   shop: "Demo Agro Centre",   district: "Bengaluru", phone: "", stock: 10 },
  { name: "NPK 12:32:16",            category: "Complex",        brand: "IFFCO",      weight: "50 kg", price: 1475,   shop: "Demo Farmers Store", district: "Bengaluru", phone: "", stock: 7  },
  { name: "NPK 19:19:19",            category: "Water Soluble",  brand: "IFFCO",      weight: "25 kg", price: 1400,   shop: "Demo Agro Centre",   district: "Bengaluru", phone: "", stock: 5  },
  { name: "SSP",                     category: "Phosphatic",     brand: "FACT",       weight: "50 kg", price: 520,    shop: "Demo Farmers Store", district: "Bengaluru", phone: "", stock: 18 },
  { name: "Ammonium Sulphate",       category: "Nitrogen",       brand: "FACT",       weight: "50 kg", price: 700,    shop: "Demo Agro Centre",   district: "Bengaluru", phone: "", stock: 9  },
  { name: "SOP",                     category: "Potassic",       brand: "Coromandel", weight: "25 kg", price: 1450,   shop: "Demo Farmers Store", district: "Bengaluru", phone: "", stock: 4  },
  { name: "Zinc Sulphate",           category: "Micronutrients", brand: "Multiplex",  weight: "5 kg",  price: 450,    shop: "Demo Agro Centre",   district: "Bengaluru", phone: "", stock: 11 },
  { name: "Boron",                   category: "Micronutrients", brand: "Multiplex",  weight: "1 kg",  price: 320,    shop: "Demo Farmers Store", district: "Bengaluru", phone: "", stock: 6  },
  { name: "Magnesium Sulphate",      category: "Micronutrients", brand: "Multiplex",  weight: "25 kg", price: 650,    shop: "Demo Agro Centre",   district: "Bengaluru", phone: "", stock: 13 },
  { name: "Ferrous Sulphate",        category: "Micronutrients", brand: "Generic",    weight: "5 kg",  price: 280,    shop: "Demo Farmers Store", district: "Bengaluru", phone: "", stock: 3  },
  { name: "Vermicompost",            category: "Organic",        brand: "Local",      weight: "25 kg", price: 250,    shop: "Demo Agro Centre",   district: "Bengaluru", phone: "", stock: 30 },
  { name: "Neem Cake",               category: "Organic",        brand: "Local",      weight: "25 kg", price: 500,    shop: "Demo Farmers Store", district: "Bengaluru", phone: "", stock: 14 },
  { name: "Rhizobium Biofertilizer", category: "Biofertilizer",  brand: "Bio-input",  weight: "1 kg",  price: 180,    shop: "Demo Agro Centre",   district: "Bengaluru", phone: "", stock: 16 },
  { name: "PSB Biofertilizer",       category: "Biofertilizer",  brand: "Bio-input",  weight: "1 kg",  price: 190,    shop: "Demo Farmers Store", district: "Bengaluru", phone: "", stock: 0  },
  { name: "Calcium Nitrate",         category: "Water Soluble",  brand: "Generic",    weight: "25 kg", price: 1250,   shop: "Demo Agro Centre",   district: "Bengaluru", phone: "", stock: 5  },
];

// ── DB bootstrap ──────────────────────────────────────────────────────────────
async function bootstrap() {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS users (
      id           SERIAL PRIMARY KEY,
      neon_sub     TEXT UNIQUE NOT NULL,
      phone        TEXT DEFAULT '',
      email        TEXT DEFAULT '',
      display_name TEXT DEFAULT '',
      created_at   TIMESTAMPTZ DEFAULT NOW(),
      last_login   TIMESTAMPTZ DEFAULT NOW()
    );
  `);

  // Ensure columns exist for email & password auth
  await pool.query(`
    ALTER TABLE users ADD COLUMN IF NOT EXISTS phone TEXT DEFAULT '';
    ALTER TABLE users ADD COLUMN IF NOT EXISTS password TEXT DEFAULT '';
    ALTER TABLE users ALTER COLUMN email DROP NOT NULL;
    ALTER TABLE users ALTER COLUMN email SET DEFAULT '';
  `);

  await pool.query(`
    CREATE TABLE IF NOT EXISTS distributors (
      id         SERIAL PRIMARY KEY,
      name       TEXT NOT NULL,
      district   TEXT NOT NULL,
      phone      TEXT DEFAULT '',
      address    TEXT DEFAULT '',
      created_at TIMESTAMPTZ DEFAULT NOW()
    );
  `);

  await pool.query(`
    CREATE TABLE IF NOT EXISTS fertilizers (
      id             SERIAL PRIMARY KEY,
      distributor_id INTEGER REFERENCES distributors(id) ON DELETE SET NULL,
      name           TEXT NOT NULL,
      category       TEXT NOT NULL,
      brand          TEXT NOT NULL,
      weight         TEXT NOT NULL,
      price          NUMERIC(10,2) NOT NULL,
      shop           TEXT NOT NULL,
      district       TEXT NOT NULL,
      phone          TEXT DEFAULT '',
      stock          INTEGER DEFAULT 0,
      updated        TEXT DEFAULT 'Live data'
    );
  `);

  await pool.query(`
    ALTER TABLE fertilizers ADD COLUMN IF NOT EXISTS distributor_id INTEGER REFERENCES distributors(id) ON DELETE SET NULL;
  `);

  await pool.query(`
    CREATE TABLE IF NOT EXISTS orders (
      id               SERIAL PRIMARY KEY,
      user_id          INTEGER REFERENCES users(id) ON DELETE SET NULL,
      fertilizer_id    INTEGER REFERENCES fertilizers(id) ON DELETE SET NULL,
      fertilizer_name  TEXT NOT NULL,
      brand            TEXT DEFAULT '',
      quantity         INTEGER NOT NULL,
      total_price      NUMERIC(10,2) NOT NULL,
      customer_name    TEXT DEFAULT '',
      customer_mobile  TEXT DEFAULT '',
      customer_address TEXT DEFAULT '',
      status           TEXT DEFAULT 'placed',
      created_at       TIMESTAMPTZ DEFAULT NOW()
    );
  `);

  // Seed initial distributors if none exist
  const distCheck = await pool.query("SELECT COUNT(*) FROM distributors");
  if (Number(distCheck.rows[0].count) === 0) {
    console.log("Seeding distributors into Neon DB…");
    await pool.query(`
      INSERT INTO distributors (name, district, phone, address) VALUES
      ('Demo Agro Centre', 'Bengaluru', '+91 98765 43210', 'APMC Yard, Yeshwanthpur, Bengaluru - 560022'),
      ('Demo Farmers Store', 'Bengaluru', '+91 98765 43211', 'Main Road, Nelamangala, Bengaluru Rural - 562123');
    `);
  }

  // Link existing fertilizers to distributors
  await pool.query(`
    UPDATE fertilizers f
    SET distributor_id = d.id
    FROM distributors d
    WHERE (LOWER(f.shop) = LOWER(d.name) OR f.shop = '')
      AND f.distributor_id IS NULL;
  `);

  const { rows } = await pool.query("SELECT COUNT(*) FROM fertilizers");
  if (Number(rows[0].count) === 0) {
    console.log("Seeding fertilizers into Neon DB…");
    for (const f of SEED) {
      await pool.query(
        `INSERT INTO fertilizers (name,category,brand,weight,price,shop,district,phone,stock)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)`,
        [f.name, f.category, f.brand, f.weight, f.price, f.shop, f.district, f.phone, f.stock]
      );
    }
    console.log(`Seeded ${SEED.length} fertilizers.`);
  }
}

// ── Auth Middleware ───────────────────────────────────────────────────────────
async function requireAuth(req, res, next) {
  const header = req.headers.authorization || "";
  if (!header.startsWith("Bearer ")) {
    return res.status(401).json({ success: false, message: "No auth token provided." });
  }
  const token = header.slice(7);

  // Try verifying with Neon Auth JWKS first (if token was issued by Neon Auth)
  try {
    const { payload } = await jwtVerify(token, JWKS);
    req.neonUser = payload;
    return syncUser(req, res, next);
  } catch (_) {
    // If not Neon Auth JWT, verify with backend local secret
    try {
      const decoded = jwt.verify(token, JWT_SECRET);
      req.neonUser = { sub: decoded.sub || `phone_${decoded.phone}`, phone: decoded.phone, email: decoded.email || "" };
      return syncUser(req, res, next);
    } catch (err) {
      return res.status(401).json({ success: false, message: `Invalid token: ${err.message}` });
    }
  }
}

async function syncUser(req, res, next) {
  try {
    const { sub, email, phone, name } = req.neonUser;
    const { rows } = await pool.query(
      `INSERT INTO users (neon_sub, phone, email, display_name, last_login)
       VALUES ($1, $2, $3, $4, NOW())
       ON CONFLICT (neon_sub) DO UPDATE
         SET phone        = COALESCE(NULLIF(EXCLUDED.phone,''), users.phone),
             email        = COALESCE(NULLIF(EXCLUDED.email,''), users.email),
             display_name = COALESCE(NULLIF(EXCLUDED.display_name,''), users.display_name),
             last_login   = NOW()
       RETURNING *`,
      [sub, phone || "", email || "", name || ""]
    );
    req.dbUser = rows[0];
    next();
  } catch (err) {
    console.error("syncUser error:", err.message);
    res.status(500).json({ success: false, message: "Could not sync user." });
  }
}

// ── Health Check ──────────────────────────────────────────────────────────────
app.get("/", (_req, res) => {
  res.json({
    success: true,
    name: "Krushi Mitra Backend API",
    status: "online",
    version: "1.0.0",
    healthCheck: "/api/health",
  });
});

app.get("/api/health", (_req, res) => {
  res.json({ success: true, message: "Krushi Mitra API running (Neon DB + Email Auth)" });
});

// ── Email Authentication Routes (Sign Up & Login) ───────────────────────────

/**
 * POST /api/auth/register
 * Body: { email, password, displayName, phone }
 */
app.post("/api/auth/register", async (req, res) => {
  try {
    const { email, password, displayName, phone } = req.body || {};
    if (!email || !password) {
      return res.status(400).json({ success: false, message: "Email and password are required." });
    }

    const cleanEmail = String(email).trim().toLowerCase();
    if (password.length < 4) {
      return res.status(400).json({ success: false, message: "Password must be at least 4 characters long." });
    }

    // Check if user already exists
    const existing = await pool.query("SELECT id FROM users WHERE LOWER(email) = $1", [cleanEmail]);
    if (existing.rows.length > 0) {
      return res.status(400).json({ success: false, message: "An account with this email already exists." });
    }

    const name = displayName?.trim() || cleanEmail.split("@")[0];
    const userPhone = phone?.trim() || "";
    const sub = `email_${cleanEmail.replace(/[^a-zA-Z0-9]/g, "_")}`;

    const { rows } = await pool.query(
      `INSERT INTO users (neon_sub, email, password, display_name, phone, last_login)
       VALUES ($1, $2, $3, $4, $5, NOW())
       RETURNING id, neon_sub, email, display_name, phone, created_at`,
      [sub, cleanEmail, password, name, userPhone]
    );

    const user = rows[0];
    const token = jwt.sign(
      { sub: user.neon_sub, userId: user.id, email: user.email, phone: user.phone },
      JWT_SECRET,
      { expiresIn: "30d" }
    );

    console.log(`✅ [USER REGISTERED] Email: ${user.email}, Name: ${user.display_name}`);

    res.status(201).json({
      success: true,
      message: "Registration successful!",
      token,
      user: {
        id: user.id,
        email: user.email,
        displayName: user.display_name,
        phone: user.phone,
        createdAt: user.created_at,
      },
    });
  } catch (err) {
    console.error("Register error:", err.message);
    res.status(500).json({ success: false, message: "Server error during registration." });
  }
});

/**
 * POST /api/auth/login
 * Body: { email, password }
 */
app.post("/api/auth/login", async (req, res) => {
  try {
    const { email, password } = req.body || {};
    if (!email || !password) {
      return res.status(400).json({ success: false, message: "Email and password are required." });
    }

    const cleanEmail = String(email).trim().toLowerCase();

    const { rows } = await pool.query(
      "SELECT * FROM users WHERE LOWER(email) = $1",
      [cleanEmail]
    );

    if (rows.length === 0) {
      return res.status(401).json({ success: false, message: "No account found with this email." });
    }

    const user = rows[0];

    // Check password
    if (user.password !== password) {
      return res.status(401).json({ success: false, message: "Incorrect password." });
    }

    await pool.query("UPDATE users SET last_login = NOW() WHERE id = $1", [user.id]);

    const token = jwt.sign(
      { sub: user.neon_sub, userId: user.id, email: user.email, phone: user.phone },
      JWT_SECRET,
      { expiresIn: "30d" }
    );

    console.log(`✅ [USER LOGIN] Email: ${user.email}`);

    res.json({
      success: true,
      message: "Login successful!",
      token,
      user: {
        id: user.id,
        email: user.email,
        displayName: user.display_name,
        phone: user.phone,
        createdAt: user.created_at,
      },
    });
  } catch (err) {
    console.error("Login error:", err.message);
    res.status(500).json({ success: false, message: "Server error during login." });
  }
});

// ── Profile Route ─────────────────────────────────────────────────────────────
app.get("/api/auth/profile", requireAuth, async (req, res) => {
  try {
    const { rows: orders } = await pool.query(
      `SELECT id, fertilizer_name, brand, quantity, total_price, status, created_at
       FROM orders WHERE user_id=$1 ORDER BY created_at DESC`,
      [req.dbUser.id]
    );
    res.json({
      success: true,
      user: {
        id:          req.dbUser.id,
        phone:       req.dbUser.phone,
        email:       req.dbUser.email,
        displayName: req.dbUser.display_name,
        createdAt:   req.dbUser.created_at,
      },
      orders,
    });
  } catch (err) {
    console.error("GET /api/auth/profile error:", err.message);
    res.status(500).json({ success: false, message: "Could not fetch profile." });
  }
});

// ── Distributor Routes (Public) ──────────────────────────────────────────────
app.get("/api/distributors", async (_req, res) => {
  try {
    const { rows } = await pool.query(`
      SELECT d.*, COUNT(f.id)::int AS fertilizer_count
      FROM distributors d
      LEFT JOIN fertilizers f ON f.distributor_id = d.id
      GROUP BY d.id
      ORDER BY d.id ASC
    `);
    res.json({ success: true, count: rows.length, data: rows });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ── Fertilizer Routes (Public) ────────────────────────────────────────────────
app.get("/api/fertilizers", async (req, res) => {
  try {
    const q        = String(req.query.q        || "").toLowerCase().trim();
    const category = String(req.query.category || "").toLowerCase().trim();

    let sql = `
      SELECT f.*, d.name AS distributor_name, d.district AS distributor_district, d.phone AS distributor_phone, d.address AS distributor_address
      FROM fertilizers f
      LEFT JOIN distributors d ON f.distributor_id = d.id
      WHERE 1=1
    `;
    const params = [];

    if (category && category !== "all") {
      params.push(category);
      sql += ` AND LOWER(f.category) = $${params.length}`;
    }
    if (q) {
      params.push(`%${q}%`);
      const idx = params.length;
      sql += ` AND (LOWER(f.name) LIKE $${idx} OR LOWER(f.brand) LIKE $${idx}
               OR LOWER(f.category) LIKE $${idx} OR LOWER(f.shop) LIKE $${idx}
               OR LOWER(f.district) LIKE $${idx} OR LOWER(COALESCE(d.name, '')) LIKE $${idx})`;
    }
    sql += " ORDER BY f.id";

    const { rows } = await pool.query(sql, params);
    res.json({ success: true, count: rows.length, data: rows });
  } catch (err) {
    res.status(500).json({ success: false, message: "Database error" });
  }
});

// ── Dummy Payment Routes ──────────────────────────────────────────────────────
app.post("/api/payments/create-order", (req, res) => {
  const amount = Number(req.body.amount);
  res.json({ success: true, orderId: `DUMMY_${Date.now()}`, amount, currency: "INR", isDummy: true });
});

app.post("/api/payments/verify", (_req, res) => {
  res.json({ success: true, verified: true, message: "Dummy payment verified." });
});

// ── Order Routes (Protected) ──────────────────────────────────────────────────
app.post("/api/orders", requireAuth, async (req, res) => {
  try {
    const { fertilizer_id, fertilizer_name, brand, quantity, total_price,
            customer_name, customer_mobile, customer_address } = req.body;

    if (!fertilizer_name || !quantity || !total_price) {
      return res.status(400).json({ success: false, message: "Missing required order fields." });
    }

    const { rows } = await pool.query(
      `INSERT INTO orders
         (user_id, fertilizer_id, fertilizer_name, brand, quantity, total_price,
          customer_name, customer_mobile, customer_address)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9) RETURNING *`,
      [req.dbUser.id, fertilizer_id ?? null, fertilizer_name, brand ?? "",
       quantity, total_price, customer_name ?? "", customer_mobile ?? "", customer_address ?? ""]
    );

    res.json({ success: true, order: rows[0] });
  } catch (err) {
    console.error("POST /api/orders error:", err.message);
    res.status(500).json({ success: false, message: "Could not save order." });
  }
});

// User cancel order
app.put("/api/orders/:id/cancel", requireAuth, async (req, res) => {
  try {
    const orderId = Number(req.params.id);
    const { rows } = await pool.query(
      `UPDATE orders 
       SET status = 'cancelled' 
       WHERE id = $1 AND user_id = $2 
       RETURNING *`,
      [orderId, req.dbUser.id]
    );

    if (rows.length === 0) {
      return res.status(404).json({ success: false, message: "Order not found or unauthorized." });
    }

    res.json({ success: true, message: "Order cancelled successfully.", order: rows[0] });
  } catch (err) {
    console.error("PUT /api/orders/:id/cancel error:", err.message);
    res.status(500).json({ success: false, message: "Could not cancel order." });
  }
});

// ── Admin Routes ─────────────────────────────────────────────────────────────
const ADMIN_EMAIL = "admin@gmail.com";
const ADMIN_PASS  = "Admin@123";

// Admin Authentication Middleware
function requireAdmin(req, res, next) {
  const header = req.headers.authorization || "";
  if (!header.startsWith("Bearer ")) {
    return res.status(401).json({ success: false, message: "No admin token provided." });
  }
  const token = header.slice(7);
  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    if (decoded.role !== "admin") {
      return res.status(403).json({ success: false, message: "Access denied. Admin role required." });
    }
    req.admin = decoded;
    next();
  } catch (err) {
    return res.status(401).json({ success: false, message: "Invalid or expired admin token." });
  }
}

// POST /api/admin/login
app.post("/api/admin/login", (req, res) => {
  const { email, password } = req.body || {};
  if (email === ADMIN_EMAIL && password === ADMIN_PASS) {
    const token = jwt.sign(
      { role: "admin", email: ADMIN_EMAIL },
      JWT_SECRET,
      { expiresIn: "7d" }
    );
    return res.json({ success: true, token, message: "Admin login successful" });
  }
  return res.status(401).json({ success: false, message: "Invalid email or password." });
});

// ── Admin Distributor Management ─────────────────────────────────────────────
// GET /api/admin/distributors
app.get("/api/admin/distributors", requireAdmin, async (_req, res) => {
  try {
    const { rows } = await pool.query(`
      SELECT d.*, COUNT(f.id)::int AS fertilizer_count
      FROM distributors d
      LEFT JOIN fertilizers f ON f.distributor_id = d.id
      GROUP BY d.id
      ORDER BY d.id ASC
    `);
    res.json({ success: true, count: rows.length, data: rows });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// POST /api/admin/distributors
app.post("/api/admin/distributors", requireAdmin, async (req, res) => {
  try {
    const { name, district, phone, address } = req.body || {};
    if (!name || !district) {
      return res.status(400).json({ success: false, message: "Distributor name and district are required." });
    }
    const { rows } = await pool.query(
      `INSERT INTO distributors (name, district, phone, address)
       VALUES ($1, $2, $3, $4)
       RETURNING *`,
      [name.trim(), district.trim(), phone?.trim() || "", address?.trim() || ""]
    );
    res.status(201).json({ success: true, data: rows[0], message: "Distributor added successfully." });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// PUT /api/admin/distributors/:id
app.put("/api/admin/distributors/:id", requireAdmin, async (req, res) => {
  try {
    const id = Number(req.params.id);
    const { name, district, phone, address } = req.body || {};
    const { rows } = await pool.query(
      `UPDATE distributors
       SET name = COALESCE($1, name),
           district = COALESCE($2, district),
           phone = COALESCE($3, phone),
           address = COALESCE($4, address)
       WHERE id = $5
       RETURNING *`,
      [name?.trim(), district?.trim(), phone?.trim(), address?.trim(), id]
    );
    if (rows.length === 0) {
      return res.status(404).json({ success: false, message: "Distributor not found." });
    }
    // Also sync the shop name and district to its linked fertilizers
    if (name || district) {
      await pool.query(
        `UPDATE fertilizers 
         SET shop = COALESCE($1, shop), district = COALESCE($2, district)
         WHERE distributor_id = $3`,
        [name?.trim(), district?.trim(), id]
      );
    }
    res.json({ success: true, data: rows[0], message: "Distributor updated successfully." });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// DELETE /api/admin/distributors/:id
app.delete("/api/admin/distributors/:id", requireAdmin, async (req, res) => {
  try {
    const id = Number(req.params.id);
    // Check if there are linked fertilizers
    const check = await pool.query("SELECT COUNT(*)::int FROM fertilizers WHERE distributor_id = $1", [id]);
    if (check.rows[0].count > 0) {
      return res.status(400).json({
        success: false,
        message: `Cannot delete distributor. There are ${check.rows[0].count} fertilizers linked to this distributor. Please reassign or delete them first.`,
      });
    }

    const result = await pool.query("DELETE FROM distributors WHERE id = $1", [id]);
    if (result.rowCount === 0) {
      return res.status(404).json({ success: false, message: "Distributor not found." });
    }
    res.json({ success: true, message: "Distributor deleted successfully." });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// GET /api/admin/fertilizers
app.get("/api/admin/fertilizers", requireAdmin, async (_req, res) => {
  try {
    const { rows } = await pool.query(`
      SELECT f.*, d.name AS distributor_name, d.district AS distributor_district, d.phone AS distributor_phone
      FROM fertilizers f
      LEFT JOIN distributors d ON f.distributor_id = d.id
      ORDER BY f.id DESC
    `);
    res.json({ success: true, count: rows.length, data: rows });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// POST /api/admin/fertilizers
app.post("/api/admin/fertilizers", requireAdmin, async (req, res) => {
  try {
    const { distributor_id, name, category, brand, weight, price, stock } = req.body;
    
    // Distributor is strictly REQUIRED
    if (!distributor_id) {
      return res.status(400).json({ success: false, message: "Distributor is required. Every product must be under a distributor." });
    }
    if (!name || !category || !brand || !price) {
      return res.status(400).json({ success: false, message: "Name, category, brand, and price are required." });
    }

    // Lookup distributor
    const distRow = await pool.query("SELECT * FROM distributors WHERE id = $1", [distributor_id]);
    if (distRow.rows.length === 0) {
      return res.status(400).json({ success: false, message: "Selected distributor does not exist." });
    }
    const dist = distRow.rows[0];

    const { rows } = await pool.query(
      `INSERT INTO fertilizers (distributor_id, name, category, brand, weight, price, shop, district, phone, stock)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
       RETURNING *`,
      [dist.id, name.trim(), category.trim(), brand.trim(), weight || "", price, dist.name, dist.district, dist.phone || "", stock ?? 0]
    );
    res.status(201).json({ success: true, data: rows[0] });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// PUT /api/admin/fertilizers/:id
app.put("/api/admin/fertilizers/:id", requireAdmin, async (req, res) => {
  try {
    const id = Number(req.params.id);
    const { distributor_id, name, category, brand, weight, price, stock } = req.body;

    let dist = null;
    if (distributor_id) {
      const distRow = await pool.query("SELECT * FROM distributors WHERE id = $1", [distributor_id]);
      if (distRow.rows.length === 0) {
        return res.status(400).json({ success: false, message: "Selected distributor does not exist." });
      }
      dist = distRow.rows[0];
    }

    const { rows } = await pool.query(
      `UPDATE fertilizers
       SET distributor_id = COALESCE($1, distributor_id),
           name = COALESCE($2, name),
           category = COALESCE($3, category),
           brand = COALESCE($4, brand),
           weight = COALESCE($5, weight),
           price = COALESCE($6, price),
           shop = COALESCE($7, shop),
           district = COALESCE($8, district),
           phone = COALESCE($9, phone),
           stock = COALESCE($10, stock)
       WHERE id = $11
       RETURNING *`,
      [
        dist ? dist.id : null,
        name ? name.trim() : null,
        category ? category.trim() : null,
        brand ? brand.trim() : null,
        weight,
        price,
        dist ? dist.name : null,
        dist ? dist.district : null,
        dist ? dist.phone : null,
        stock,
        id
      ]
    );
    if (rows.length === 0) {
      return res.status(404).json({ success: false, message: "Fertilizer not found." });
    }
    res.json({ success: true, data: rows[0] });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// DELETE /api/admin/fertilizers/:id
app.delete("/api/admin/fertilizers/:id", requireAdmin, async (req, res) => {
  try {
    const id = Number(req.params.id);
    const result = await pool.query("DELETE FROM fertilizers WHERE id = $1", [id]);
    if (result.rowCount === 0) {
      return res.status(404).json({ success: false, message: "Fertilizer not found." });
    }
    res.json({ success: true, message: "Fertilizer deleted successfully." });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// GET /api/admin/orders
app.get("/api/admin/orders", requireAdmin, async (_req, res) => {
  try {
    const { rows } = await pool.query(`
      SELECT o.*, u.phone AS user_phone, u.email AS user_email
      FROM orders o
      LEFT JOIN users u ON o.user_id = u.id
      ORDER BY o.created_at DESC
    `);
    res.json({ success: true, count: rows.length, data: rows });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// Admin cancel order
app.put("/api/admin/orders/:id/cancel", requireAdmin, async (req, res) => {
  try {
    const orderId = Number(req.params.id);
    const { rows } = await pool.query(
      `UPDATE orders 
       SET status = 'cancelled' 
       WHERE id = $1 
       RETURNING *`,
      [orderId]
    );

    if (rows.length === 0) {
      return res.status(404).json({ success: false, message: "Order not found." });
    }

    res.json({ success: true, message: "Order cancelled by admin.", order: rows[0] });
  } catch (err) {
    console.error("PUT /api/admin/orders/:id/cancel error:", err.message);
    res.status(500).json({ success: false, message: "Could not cancel order." });
  }
});

// ── Start ─────────────────────────────────────────────────────────────────────
bootstrap()
  .then(() => {
    app.listen(PORT, "0.0.0.0", () => {
      console.log(`\n=======================================================`);
      console.log(`✅ Krushi Mitra API Running on http://localhost:${PORT}`);
      console.log(`   Auth Mode      : Email & Password (Login + Sign Up)`);
      console.log(`   Admin Login    : POST /api/admin/login`);
      console.log(`   Admin Creds    : admin@gmail.com / Admin@123`);
      console.log(`=======================================================\n`);
    });
  })
  .catch((err) => {
    console.error("Bootstrap failed:", err.message);
    process.exit(1);
  });
