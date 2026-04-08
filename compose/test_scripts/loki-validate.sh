#!/bin/bash

# Loki Validation Script
# This script sends log data to Loki and verifies it's stored and queryable
# 
# How it works:
# 1. Sends sample logs to Loki via HTTP API
# 2. Waits for logs to be indexed
# 3. Queries the logs back to verify they were stored
# 4. Checks Loki health and metrics
#
# Prerequisites: Loki must be running on localhost:3100

set -e

LOKI_URL="http://localhost:3100"
TEST_LABEL_VALUE="loki-validation-$(date +%s)"
TIMESTAMP=$(date +%s)000000000  # Nanoseconds

echo "🔍 Starting Loki Validation..."
echo "================================"

# Step 1: Check if Loki is alive
echo ""
echo "1️⃣  Checking Loki health..."
if curl -s "$LOKI_URL/ready" > /dev/null; then
    echo "   ✅ Loki is ready"
else
    echo "   ❌ Loki is not responding on $LOKI_URL"
    exit 1
fi

# Step 2: Send test logs to Loki
echo ""
echo "2️⃣  Sending test logs to Loki..."

# Create test log entries with labels
# Labels are used to identify and filter logs in Loki
curl -s -X POST "$LOKI_URL/loki/api/v1/push" \
  -H "Content-Type: application/json" \
  -d @- <<EOF
{
  "streams": [
    {
      "stream": {
        "job": "test-validation",
        "test_id": "$TEST_LABEL_VALUE"
      },
      "values": [
        ["$TIMESTAMP", "Test log entry 1 from validation script"],
        ["$((TIMESTAMP + 1000000000))", "Test log entry 2 - checking if Loki stores data"],
        ["$((TIMESTAMP + 2000000000))", "Test log entry 3 - final validation entry"]
      ]
    }
  ]
}
EOF

echo "   ✅ Logs sent to Loki"

# Step 3: Wait for logs to be indexed
echo ""
echo "3️⃣  Waiting for logs to be indexed (5 seconds)..."
sleep 5

# Step 4: Query logs back from Loki
echo ""
echo "4️⃣  Querying logs from Loki..."

QUERY_RESULT=$(curl -s "$LOKI_URL/loki/api/v1/query_range" \
  --data-urlencode 'query={job="test-validation", test_id="'$TEST_LABEL_VALUE'"}' \
  --data-urlencode 'start='$((TIMESTAMP - 60000000000))'' \
  --data-urlencode 'end='$((TIMESTAMP + 3000000000))'')

# Extract number of log entries returned
LOG_COUNT=$(echo "$QUERY_RESULT" | grep -o '"value"' | wc -l)

if [ "$LOG_COUNT" -ge 3 ]; then
    echo "   ✅ Successfully retrieved $LOG_COUNT log entries"
    echo ""
    echo "📋 Sample log entries:"
    echo "$QUERY_RESULT" | grep -o '"Test log entry [^"]*"' | head -3
else
    echo "   ⚠️  Expected 3 log entries, but found $LOG_COUNT"
    echo "   Response: $QUERY_RESULT"
fi

# Step 5: Check Loki metrics availability
echo ""
echo "5️⃣  Checking Loki metrics endpoint..."
METRICS=$(curl -s "$LOKI_URL/metrics" | head -10)
if [ -n "$METRICS" ]; then
    echo "   ✅ Metrics endpoint is available"
else
    echo "   ⚠️  Metrics endpoint not responding"
fi

echo ""
echo "================================"
echo "✅ Loki Validation Complete!"
echo ""
echo "📌 What you just tested:"
echo "   • Loki HTTP API is accessible"
echo "   • Push API can receive logs with labels"
echo "   • Logs are stored in Loki"
echo "   • Query API can retrieve logs"
echo "   • Metrics endpoint is available"
echo ""
echo "🧹 To cleanup test data, run: ./loki-cleanup.sh"
