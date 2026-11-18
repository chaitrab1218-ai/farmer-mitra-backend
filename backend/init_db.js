require("dotenv").config();
const { Pool } = require("pg");

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

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

async function init() {
  console.log("Connecting to Neon DB...");
  await pool.query(`
    CREATE TABLE IF NOT EXISTS users (
      id           SERIAL PRIMARY KEY,
      neon_sub     TEXT UNIQUE NOT NULL,
      email        TEXT NOT NULL,
      display_name TEXT DEFAULT '',
      created_at   TIMESTAMPTZ DEFAULT NOW(),
      last_login   TIMESTAMPTZ DEFAULT NOW()
    );
  `);
  console.log("Users table ensured.");

  await pool.query(`
    CREATE TABLE IF NOT EXISTS fertilizers (
      id       SERIAL PRIMARY KEY,
      name     TEXT NOT NULL,
      category TEXT NOT NULL,
      brand    TEXT NOT NULL,
      weight   TEXT NOT NULL,
      price    NUMERIC(10,2) NOT NULL,
      shop     TEXT NOT NULL,
      district TEXT NOT NULL,
      phone    TEXT DEFAULT '',
      stock    INTEGER DEFAULT 0,
      updated  TEXT DEFAULT 'Live data'
    );
  `);
  console.log("Fertilizers table ensured.");

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
  console.log("Orders table ensured.");

  const { rows } = await pool.query("SELECT COUNT(*) FROM fertilizers");
  if (Number(rows[0].count) === 0) {
    console.log("Seeding fertilizers into Neon DB...");
    for (const f of SEED) {
      await pool.query(
        `INSERT INTO fertilizers (name,category,brand,weight,price,shop,district,phone,stock)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)`,
        [f.name, f.category, f.brand, f.weight, f.price, f.shop, f.district, f.phone, f.stock]
      );
    }
    console.log(`Seeded ${SEED.length} fertilizers.`);
  } else {
    console.log(`Fertilizers table already has ${rows[0].count} items.`);
  }

  await pool.end();
  console.log("Neon DB initialization complete!");
}

init().catch((e) => {
  console.error("Init failed:", e);
  process.exit(1);
});
