// ============================================================================
// MIT 8103: Advanced Database Systems
// Portfolio 4: MongoDB Document Model for Fraud Detection & Audit Logs
// Database: paysphere_nosql
// ============================================================================

// Connect / switch to paysphere_nosql
db = db.getSiblingDB('paysphere_nosql');

// Drop previous collection if re-running
db.fraud_telemetry_logs.drop();

// 1. Create collection with JSON Schema Validation
db.createCollection("fraud_telemetry_logs", {
   validator: {
      $jsonSchema: {
         bsonType: "object",
         required: ["transaction_id", "customer_id", "timestamp", "risk_evaluation", "device_telemetry"],
         properties: {
            transaction_id: {
               bsonType: "string",
               description: "Foreign UUID referencing relational transaction"
            },
            customer_id: {
               bsonType: "string",
               description: "Foreign UUID referencing relational customer"
            },
            timestamp: {
               bsonType: "date",
               description: "UTC event timestamp"
            },
            risk_evaluation: {
               bsonType: "object",
               required: ["risk_score", "risk_decision"],
               properties: {
                  risk_score: {
                     bsonType: "int",
                     minimum: 0,
                     maximum: 100,
                     description: "Calculated risk score 0-100"
                  },
                  risk_decision: {
                     enum: ["ALLOW", "CHALLENGE_2FA", "FLAG_AML", "BLOCK"],
                     description: "Automated engine decision"
                  },
                  flags_triggered: {
                     bsonType: "array",
                     items: { bsonType: "string" }
                  }
               }
            },
            device_telemetry: {
               bsonType: "object",
               required: ["ip_address", "client_platform"],
               properties: {
                  ip_address: { bsonType: "string" },
                  client_platform: { enum: ["iOS", "Android", "Web_Portal", "API_Gateway"] },
                  location: {
                     bsonType: "object",
                     properties: {
                        city: { bsonType: "string" },
                        country_code: { bsonType: "string" },
                        coordinates: {
                           bsonType: "array",
                           items: { bsonType: "double" },
                           minItems: 2,
                           maxItems: 2,
                           description: "[Longitude, Latitude]"
                        }
                     }
                  }
               }
            }
         }
      }
   }
});

// 2. Create Indexes for High-Velocity Queries
// Fast lookup by customer and transaction
db.fraud_telemetry_logs.createIndex({ customer_id: 1, timestamp: -1 });
db.fraud_telemetry_logs.createIndex({ transaction_id: 1 }, { unique: true });

// Partial Index: Fast indexing of high-risk suspicious events only
db.fraud_telemetry_logs.createIndex(
   { "risk_evaluation.risk_score": -1 },
   { partialFilterExpression: { "risk_evaluation.risk_score": { $gte: 75 } } }
);

// TTL Index: Automatically purge non-suspicious logs after 90 days (7,776,000 seconds)
db.fraud_telemetry_logs.createIndex(
   { "timestamp": 1 },
   { expireAfterSeconds: 7776000 }
);

// 3. Insert Realistic Audit Documents
db.fraud_telemetry_logs.insertMany([
   {
      transaction_id: "d0000000-0000-0000-0000-000000000001",
      customer_id: "a0000000-0000-0000-0000-000000000001",
      timestamp: new Date(),
      risk_evaluation: {
         risk_score: 12,
         risk_decision: "ALLOW",
         flags_triggered: []
      },
      device_telemetry: {
         ip_address: "102.89.23.4",
         client_platform: "Android",
         device_model: "Samsung SM-S918B",
         app_version: "v4.2.1",
         location: {
            city: "Lagos",
            country_code: "NG",
            coordinates: [3.3792, 6.5244] // [Lng, Lat]
         }
      }
   },
   {
      transaction_id: "d0000000-0000-0000-0000-000000000002",
      customer_id: "a0000000-0000-0000-0000-000000000002",
      timestamp: new Date(),
      risk_evaluation: {
         risk_score: 88,
         risk_decision: "CHALLENGE_2FA",
         flags_triggered: ["VELOCITY_EXCEEDED", "NEW_IP_GEOLOCATION", "VPN_DETECTED"]
      },
      device_telemetry: {
         ip_address: "185.220.101.5",
         client_platform: "Web_Portal",
         user_agent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64)",
         is_vpn_or_proxy: true,
         location: {
            city: "Frankfurt",
            country_code: "DE",
            coordinates: [8.6821, 50.1109]
         }
      }
   }
]);
