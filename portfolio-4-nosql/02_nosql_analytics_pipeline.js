// ============================================================================
// MIT 8103: Advanced Database Systems
// Portfolio 4: NoSQL Analytical Aggregation Pipelines
// ============================================================================

db = db.getSiblingDB('paysphere_nosql');

// AGGREGATION 1: Real-Time High Risk & AML Alert Aggregation
// Groups events by decision, filters risk >= 75, unrolls flags array
printjson(
   db.fraud_telemetry_logs.aggregate([
      {
         $match: {
            "risk_evaluation.risk_score": { $gte: 70 }
         }
      },
      {
         $unwind: "$risk_evaluation.flags_triggered"
      },
      {
         $group: {
            _id: "$risk_evaluation.flags_triggered",
            incident_count: { $sum: 1 },
            avg_risk_score: { $avg: "$risk_evaluation.risk_score" },
            affected_customers: { $addToSet: "$customer_id" }
         }
      },
      {
         $sort: { incident_count: -1 }
      }
   ]).toArray()
);

// AGGREGATION 2: Platform & Country Threat Distribution
printjson(
   db.fraud_telemetry_logs.aggregate([
      {
         $group: {
            _id: {
               platform: "$device_telemetry.client_platform",
               country: "$device_telemetry.location.country_code"
            },
            total_requests: { $sum: 1 },
            max_risk: { $max: "$risk_evaluation.risk_score" }
         }
      }
   ]).toArray()
);
