#!/bin/bash

# Loki Cleanup Script
# This script deletes test log entries from Loki using the delete API
#
# Note: The Loki delete API is a more advanced feature that requires
# labels to be specified. This ensures you're only deleting test data.

set -e

LOKI_URL="http://localhost:3100"

echo "🧹 Starting Loki Cleanup..."
echo "================================"

# Check if Loki is alive
echo ""
echo "Checking Loki health..."
if ! curl -s "$LOKI_URL/ready" > /dev/null; then
    echo "❌ Loki is not responding on $LOKI_URL"
    exit 1
fi
echo "✅ Loki is ready"

# Delete logs with the test-validation label
echo ""
echo "Deleting test logs (job=test-validation)..."

DELETE_RESPONSE=$(curl -s -X POST "$LOKI_URL/loki/api/v1/delete" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode 'query={job="test-validation"}' \
  --data-urlencode 'start='$(date +%s%N)'' \
  --data-urlencode 'end='$(($(date +%s) + 86400))000000000'')

if echo "$DELETE_RESPONSE" | grep -q "request_id"; then
    echo "✅ Delete request submitted successfully"
    echo "   Note: Deletion is asynchronous. Data may take a few moments to be removed."
else
    echo "ℹ️  Delete API response: $DELETE_RESPONSE"
    echo ""
    echo "💡 Tip for Mac users: If you need a faster cleanup, you can:"
    echo "   1. Stop Loki: docker compose -f compose.prod.yaml stop loki"
    echo "   2. Remove Loki volume: docker volume rm loki-data"
    echo "   3. Remove Loki cache: docker volume rm loki-wal"
    echo "   4. Restart Loki: docker compose -f compose.prod.yaml up -d loki"
fi

echo ""
echo "================================"
echo "✅ Cleanup Complete!"
