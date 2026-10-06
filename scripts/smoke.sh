#!/usr/bin/env bash
set -euo pipefail
BASE="${1:-http://localhost:5000}"
curl -sf "$BASE/health" > /dev/null
ID=$(curl -s -X POST "$BASE/api/jobs" -H 'Content-Type: application/json' -d '{"title":"smoke","description":"d","requirements":"python"}' | python3 -c 'import sys,json;print(json.load(sys.stdin)["id"])')
curl -sf "$BASE/api/jobs/$ID/analytics" > /dev/null
echo "smoke OK: $ID"
