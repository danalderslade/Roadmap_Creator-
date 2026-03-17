#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${1:-http://localhost:8000}"
CSV_PATH="${2:-samples/sample_jira_extract.csv}"

if [[ ! -f "$CSV_PATH" ]]; then
  echo "CSV file not found: $CSV_PATH"
  exit 1
fi

health_tmp="$(mktemp)"
upload_tmp="$(mktemp)"
trap 'rm -f "$health_tmp" "$upload_tmp"' EXIT

curl -fsS "$BASE_URL/healthz" > "$health_tmp"
python3 - "$health_tmp" <<'PY'
import json
import sys

with open(sys.argv[1], "r", encoding="utf-8") as f:
    payload = json.load(f)

if payload.get("status") != "ok":
    raise SystemExit(f"Health check failed: {payload}")
PY

echo "Health check passed"

http_code=$(curl -sS -o "$upload_tmp" -w "%{http_code}" \
  -F "file=@${CSV_PATH};type=text/csv" \
  "$BASE_URL/api/upload")

if [[ "$http_code" != "200" ]]; then
  echo "Upload endpoint failed with HTTP $http_code"
  cat "$upload_tmp"
  exit 1
fi

python3 - "$upload_tmp" <<'PY'
import json
import sys

required = {"application", "feature_name", "quarter", "month", "year"}

with open(sys.argv[1], "r", encoding="utf-8") as f:
    payload = json.load(f)

rows = payload.get("rows", [])
if not rows:
    raise SystemExit("No rows returned from upload endpoint")

missing = required - set(rows[0].keys())
if missing:
    raise SystemExit(f"Missing expected fields in roadmap rows: {sorted(missing)}")

if payload.get("total_rows", 0) <= 0:
    raise SystemExit(f"Unexpected total_rows value: {payload.get('total_rows')}")

print(f"Upload passed with {payload['total_rows']} rows")
PY

echo "Smoke test completed successfully"
