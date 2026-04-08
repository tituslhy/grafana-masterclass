# Loki Query Examples & Metrics

This document contains example PromQL and LogQL queries to validate and test your Loki setup.

## Loki API Endpoints Reference

| Endpoint | Purpose | Method |
|----------|---------|--------|
| `/ready` | Check if Loki is ready | GET |
| `/loki/api/v1/push` | Send logs to Loki | POST |
| `/loki/api/v1/query_range` | Query logs over a time range | GET/POST |
| `/loki/api/v1/query` | Instant log query | GET/POST |
| `/metrics` | Prometheus metrics from Loki | GET |

---

## LogQL Queries (Retrieve Logs)

Use these queries to retrieve logs from Loki. You can test them via curl or in Grafana.

### 1. Basic Label Query - Find All Test Logs
```
{job="test-validation"}
```
**What it does:** Retrieves all logs with the label `job=test-validation`

### 2. Query with Multiple Labels
```
{job="test-validation", test_id="loki-validation-1234567890"}
```
**What it does:** Filters logs by multiple labels (like AND operator)

### 3. Text Filter - Search in Log Content
```
{job="test-validation"} |= "entry"
```
**What it does:** Returns logs containing the word "entry"

### 4. Exclude Matches
```
{job="test-validation"} != "final"
```
**What it does:** Returns logs that do NOT contain the word "final"

### 5. Pattern Matching
```
{job="test-validation"} |= "Test log entry [0-9]"
```
**What it does:** Returns logs matching a pattern (regex)

---

## Testing Each Query via curl

### Test Query 1: Get all test logs
```bash
curl -s "http://localhost:3100/loki/api/v1/query_range" \
  --data-urlencode 'query={job="test-validation"}' \
  --data-urlencode 'start='$(date -u -v-1H +%s%N)'' \
  --data-urlencode 'end='$(date +%s%N)'' | jq .
```

### Test Query 2: Get specific test run logs
```bash
TEST_ID="loki-validation-1234567890"  # Replace with actual test_id
curl -s "http://localhost:3100/loki/api/v1/query_range" \
  --data-urlencode 'query={job="test-validation", test_id="'$TEST_ID'"}' \
  --data-urlencode 'start='$(date -u -v-1H +%s%N)'' \
  --data-urlencode 'end='$(date +%s%N)'' | jq .
```

### Test Query 3: Search for specific text in logs
```bash
curl -s "http://localhost:3100/loki/api/v1/query_range" \
  --data-urlencode 'query={job="test-validation"} |= "entry 2"' \
  --data-urlencode 'start='$(date -u -v-1H +%s%N)'' \
  --data-urlencode 'end='$(date +%s%N)'' | jq .
```

---

## PromQL Queries (Loki Metrics)

These queries show metrics **about** Loki itself (not log content). Run these against Prometheus which scrapes Loki.

### 1. Loki Ingestion Rate
```
rate(loki_ingester_chunks_created_total[5m])
```
**What it shows:** How many chunks Loki is creating per second

### 2. Loki Lines Received
```
rate(loki_distributor_lines_received_total[5m])
```
**What it shows:** Number of log lines received per second

### 3. Loki Query Latency
```
histogram_quantile(0.95, rate(loki_request_duration_seconds_bucket[5m]))
```
**What it shows:** 95th percentile of query response time

### 4. Loki Disk Usage (filesystem)
```
node_filesystem_avail_bytes{mountpoint="/loki"}
```
**What it shows:** Available disk space for Loki storage

### 5. Loki Cache Hit Rate
```
rate(loki_cache_hits_total[5m]) / (rate(loki_cache_hits_total[5m]) + rate(loki_cache_misses_total[5m]))
```
**What it shows:** What percentage of cache requests are hits (0-1)

---

## Testing Loki Metrics via curl

### Get all Loki metrics (formatted)
```bash
curl -s http://localhost:3100/metrics | grep -i loki | head -20
```

### Get specific metric
```bash
curl -s http://localhost:3100/metrics | grep "loki_distributor_lines_received_total"
```

---

## Quick Troubleshooting

| Issue | Query to Debug | Expected Result |
|-------|----------------|-----------------|
| Loki not receiving logs | `{job="test-validation"}` | Should return recent entries |
| Loki storage full | `rate(loki_distributor_lines_received_total[5m])` > 0 but no logs returned | Check Loki logs: `docker logs loki` |
| Slow queries | `histogram_quantile(0.99, rate(loki_request_duration_seconds_bucket[1m]))` | Should be < 1 second |
| Memory issues | Look for Loki container memory usage | If > 1GB, increase Docker memory limit |

---

## Key Concepts for Beginners

### Labels vs Content
- **Labels** (like `{job="test"}`) are indexed - queries are fast ✅
- **Log Content** is not indexed - queries scan all text, slower ⚠️

### LogQL vs PromQL
- **LogQL** - Queries log data itself (what's in the logs)
- **PromQL** - Queries metrics about services (how services are performing)

### Time Format
- Loki uses **nanoseconds** since epoch: `date +%s%N`
- On Mac: `date -u -v-1H +%s%N` for 1 hour ago
- Example: `1712000000000000000` = one second past epoch

### Chunk
A chunk is how Loki stores logs internally. Multiple log lines are compressed together into chunks to save disk space.

---

## Next Steps

1. Run the validation script: `./loki-validate.sh`
2. Query your test logs using curl examples above
3. View logs in Grafana Explore → Select Loki datasource
4. Clean up when done: `./loki-cleanup.sh`
