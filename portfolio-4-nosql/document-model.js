/**
 * ============================================================================
 * ShopEase E-Commerce Platform — MongoDB Document Data Model Implementation
 * ============================================================================
 * Course      : MIT 8103 Advanced Database Systems
 * Case Study  : ShopEase E-Commerce Platform
 * Engine      : MongoDB 6.0+ (Mongosh / Node.js)
 * Author      : Portfolio 4 — NoSQL and Advanced Data Models
 * Description : Production-grade MongoDB document schemas, CRUD operations,
 *               secondary and compound indexes, and aggregation pipelines
 *               demonstrating polymorphic product catalogs and embedded models.
 * ============================================================================
 */

// Connect and select database
use("shopease_nosql");

// ----------------------------------------------------------------------------
// 1. COLLECTION SCHEMA VALIDATION & CREATION
// ----------------------------------------------------------------------------

db.createCollection("products", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["sku", "title", "price", "category", "seller", "inventory"],
      properties: {
        sku: { bsonType: "string", description: "Unique stock keeping unit" },
        title: { bsonType: "string", description: "Product display title" },
        price: { bsonType: "number", minimum: 0, description: "Base retail price" },
        category: {
          bsonType: "object",
          required: ["slug", "name"],
          properties: {
            slug: { bsonType: "string" },
            name: { bsonType: "string" },
            path: { bsonType: "array", items: { bsonType: "string" } }
          }
        },
        seller: {
          bsonType: "object",
          required: ["sellerId", "companyName"],
          properties: {
            sellerId: { bsonType: "int" },
            companyName: { bsonType: "string" },
            rating: { bsonType: "number" }
          }
        },
        inventory: {
          bsonType: "object",
          required: ["stock", "reserved"],
          properties: {
            stock: { bsonType: "int", minimum: 0 },
            reserved: { bsonType: "int", minimum: 0 }
          }
        },
        attributes: { bsonType: "object", description: "Polymorphic dynamic product specs" },
        reviews: {
          bsonType: "array",
          items: {
            bsonType: "object",
            required: ["reviewId", "customerId", "rating", "createdAt"],
            properties: {
              reviewId: { bsonType: "string" },
              customerId: { bsonType: "int" },
              customerName: { bsonType: "string" },
              rating: { bsonType: "int", minimum: 1, maximum: 5 },
              comment: { bsonType: "string" },
              verifiedPurchase: { bsonType: "bool" },
              createdAt: { bsonType: "date" }
            }
          }
        }
      }
    }
  }
});

// ----------------------------------------------------------------------------
// 2. INDEX CREATION FOR QUERY OPTIMISATION
// ----------------------------------------------------------------------------

// Unique business key
db.products.createIndex({ sku: 1 }, { unique: true, name: "idx_products_sku_unique" });

// Compound index for catalog category filtering sorted by price
db.products.createIndex({ "category.slug": 1, price: 1 }, { name: "idx_cat_price" });

// Text index for search across product title, description, and tags
db.products.createIndex(
  { title: "text", description: "text", "tags": "text" },
  { weights: { title: 10, tags: 5, description: 1 }, name: "idx_catalog_fulltext" }
);

// Multikey index on embedded reviews rating
db.products.createIndex({ "reviews.rating": -1 }, { name: "idx_reviews_rating" });

// ----------------------------------------------------------------------------
// 3. SAMPLE DATA SEEDING (Polymorphic Documents)
// ----------------------------------------------------------------------------

db.products.insertMany([
  {
    sku: "LAP-APL-MBP16",
    title: "Apple MacBook Pro 16-inch M3 Max",
    brand: "Apple",
    description: "High-performance laptop featuring 16-core CPU, 40-core GPU, and 48GB Unified Memory.",
    price: 3499.00,
    tags: ["apple", "macbook", "laptop", "m3", "pro"],
    category: {
      slug: "laptops",
      name: "Laptops & Computers",
      path: ["Electronics", "Computers", "Laptops"]
    },
    seller: {
      sellerId: 1,
      companyName: "Apex Digital Direct",
      rating: 4.85
    },
    inventory: {
      stock: 45,
      reserved: 3,
      warehouse: "LON-01"
    },
    // Polymorphic hardware attributes
    attributes: {
      processor: "Apple M3 Max",
      ramGb: 48,
      storageGb: 1024,
      displayResolution: "3456x2234 Liquid Retina XDR",
      color: "Space Black",
      weightKg: 2.14
    },
    images: [
      { url: "https://cdn.shopease.co.uk/p/mbp16-front.webp", isPrimary: true },
      { url: "https://cdn.shopease.co.uk/p/mbp16-side.webp", isPrimary: false }
    ],
    reviews: [
      {
        reviewId: "rev-001",
        customerId: 101,
        customerName: "Sarah Jenkins",
        rating: 5,
        title: "Unmatched performance",
        comment: "Compilation times in Rust and Docker are instantaneous. Battery lasts all day.",
        verifiedPurchase: true,
        createdAt: new Date("2026-02-14T10:30:00Z")
      },
      {
        reviewId: "rev-002",
        customerId: 104,
        customerName: "David Miller",
        rating: 4,
        title: "Heavy but powerful",
        comment: "Power brick and unit are substantial, but the thermal efficiency is remarkable.",
        verifiedPurchase: true,
        createdAt: new Date("2026-02-18T16:15:00Z")
      }
    ],
    avgRating: 4.5,
    reviewCount: 2,
    createdAt: new Date("2026-01-10T09:00:00Z")
  },
  {
    sku: "APP-NIK-AF1-09",
    title: "Nike Air Force 1 '07 Triple White",
    brand: "Nike",
    description: "The radiance lives on in the Nike Air Force 1 '07, the b-ball icon that puts a fresh spin on what you know best.",
    price: 109.99,
    tags: ["nike", "sneakers", "footwear", "white", "streetwear"],
    category: {
      slug: "mens-footwear",
      name: "Men's Footwear",
      path: ["Fashion", "Men", "Footwear"]
    },
    seller: {
      sellerId: 3,
      companyName: "Urban Style Direct",
      rating: 4.60
    },
    inventory: {
      stock: 120,
      reserved: 8,
      warehouse: "MAN-02"
    },
    // Polymorphic apparel attributes (notice completely different schema than laptop)
    attributes: {
      gender: "Unisex",
      sizesAvailable: ["UK 7", "UK 8", "UK 9", "UK 10", "UK 11"],
      upperMaterial: "Full-grain Leather",
      soleMaterial: "Non-marking Rubber",
      origin: "Vietnam"
    },
    images: [
      { url: "https://cdn.shopease.co.uk/p/af1-side.webp", isPrimary: true }
    ],
    reviews: [
      {
        reviewId: "rev-003",
        customerId: 108,
        customerName: "Michael Evans",
        rating: 5,
        title: "Classic staple",
        comment: "Goes with literally everything. Fits true to size.",
        verifiedPurchase: true,
        createdAt: new Date("2026-02-20T12:00:00Z")
      }
    ],
    avgRating: 5.0,
    reviewCount: 1,
    createdAt: new Date("2026-01-15T11:20:00Z")
  },
  {
    sku: "HOM-NES-VERT-BLK",
    title: "Nespresso Vertuo Pop Coffee Machine",
    brand: "Nespresso",
    description: "Compact single-serve pod espresso and coffee maker using Centrifusion technology.",
    price: 99.00,
    tags: ["coffee", "kitchen", "espresso", "appliances"],
    category: {
      slug: "kitchen-appliances",
      name: "Kitchen Appliances",
      path: ["Home", "Kitchen", "Coffee & Tea"]
    },
    seller: {
      sellerId: 1,
      companyName: "Apex Digital Direct",
      rating: 4.85
    },
    inventory: {
      stock: 65,
      reserved: 0,
      warehouse: "LON-01"
    },
    // Polymorphic appliance attributes
    attributes: {
      waterTankCapacityLitres: 0.6,
      heatingTimeSeconds: 30,
      powerWatts: 1260,
      podCompatibility: "Nespresso Vertuo",
      autoShutOffMinutes: 2
    },
    images: [
      { url: "https://cdn.shopease.co.uk/p/nespresso-pop.webp", isPrimary: true }
    ],
    reviews: [],
    avgRating: 0.0,
    reviewCount: 0,
    createdAt: new Date("2026-01-20T14:45:00Z")
  }
]);

// ----------------------------------------------------------------------------
// 4. CRUD OPERATIONS DEMONSTRATION
// ----------------------------------------------------------------------------

// READ: Find electronics under £500 in stock with projection
db.products.find(
  {
    "category.path": "Electronics",
    price: { $lte: 500.00 },
    "inventory.stock": { $gt: 0 }
  },
  {
    title: 1,
    price: 1,
    "seller.companyName": 1,
    "inventory.stock": 1,
    _id: 0
  }
).sort({ price: 1 });

// UPDATE: Add a verified customer review and recalculate summary metrics atomically
const newReview = {
  reviewId: "rev-004",
  customerId: 115,
  customerName: "Emma Watson",
  rating: 5,
  title: "Game changer for morning routine",
  comment: "Brews piping hot coffee with a thick crema in under 40 seconds.",
  verifiedPurchase: true,
  createdAt: new Date()
};

db.products.updateOne(
  { sku: "HOM-NES-VERT-BLK" },
  {
    $push: { reviews: newReview },
    $inc: { reviewCount: 1 },
    $set: { avgRating: 5.0, updatedAt: new Date() }
  }
);

// UPDATE: Atomic inventory decrement during checkout with optimistic check
db.products.updateOne(
  {
    sku: "LAP-APL-MBP16",
    "inventory.stock": { $gte: 1 } // Precondition guarantees no overselling
  },
  {
    $inc: {
      "inventory.stock": -1,
      "inventory.reserved": 1
    }
  }
);

// ----------------------------------------------------------------------------
// 5. ADVANCED AGGREGATION PIPELINES
// ----------------------------------------------------------------------------

// Pipeline 1: Category Revenue & Catalog Health Metrics
db.products.aggregate([
  {
    $group: {
      _id: "$category.name",
      totalProductsListed: { $sum: 1 },
      avgProductPrice: { $avg: "$price" },
      minPrice: { $min: "$price" },
      maxPrice: { $max: "$price" },
      totalInventoryUnits: { $sum: "$inventory.stock" },
      totalInventoryAssetValue: { $sum: { $multiply: ["$price", "$inventory.stock"] } }
    }
  },
  {
    $project: {
      category: "$_id",
      totalProductsListed: 1,
      avgProductPrice: { $round: ["$avgProductPrice", 2] },
      priceSpread: { $subtract: ["$maxPrice", "$minPrice"] },
      totalInventoryUnits: 1,
      totalInventoryAssetValue: { $round: ["$totalInventoryAssetValue", 2] },
      _id: 0
    }
  },
  { $sort: { totalInventoryAssetValue: -1 } }
]);

// Pipeline 2: Top-Rated Products with Verified Review Filtering
db.products.aggregate([
  // Unwind the embedded reviews array
  { $unwind: "$reviews" },
  // Filter for verified purchase reviews only
  { $match: { "reviews.verifiedPurchase": true } },
  // Group back by product to compute verified score
  {
    $group: {
      _id: { sku: "$sku", title: "$title", brand: "$brand" },
      verifiedRating: { $avg: "$reviews.rating" },
      verifiedCount: { $sum: 1 }
    }
  },
  { $match: { verifiedCount: { $gte: 1 } } },
  {
    $project: {
      sku: "$_id.sku",
      title: "$_id.title",
      brand: "$_id.brand",
      verifiedRating: { $round: ["$verifiedRating", 2] },
      verifiedCount: 1,
      _id: 0
    }
  },
  { $sort: { verifiedRating: -1, verifiedCount: -1 } }
]);
