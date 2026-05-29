#!/bin/bash

FECHA=$(date +"%Y%m%d_%H%M")

BASE_DIR="/home/administrator"
OUT_DIR="$BASE_DIR/trivy-reports"
STATE_DIR="$BASE_DIR/trivy-state"

TRIVY="/usr/local/bin/trivy"

SEEN_FILE="$STATE_DIR/seen_vulns.txt"
CURRENT_FILE="$STATE_DIR/current_vulns.txt"
NEW_FILE="$STATE_DIR/new_vulns.txt"

JSON="$OUT_DIR/trivy_host_high_critical_$FECHA.json"
TXT="$OUT_DIR/trivy_host_high_critical_$FECHA.txt"

mkdir -p "$OUT_DIR"
mkdir -p "$STATE_DIR"
touch "$SEEN_FILE"

$TRIVY fs "$BASE_DIR" \
  --skip-db-update \
  --scanners vuln \
  --timeout 30m \
  --severity HIGH,CRITICAL \
  --skip-dirs "$BASE_DIR/influxdb3/data" \
  --skip-dirs "$BASE_DIR/trivy-reports" \
  --skip-dirs "$BASE_DIR/trivy-state" \
  --skip-dirs "$BASE_DIR/trivy_script" \
  --skip-dirs "$BASE_DIR/portainer" \
  --skip-dirs "$BASE_DIR/semaphore" \
  --skip-dirs "$BASE_DIR/telegraf" \
  --format json \
  -o "$JSON"

$TRIVY fs "$BASE_DIR" \
  --skip-db-update \
  --scanners vuln \
  --timeout 30m \
  --severity HIGH,CRITICAL \
  --skip-dirs "$BASE_DIR/influxdb3/data" \
  --skip-dirs "$BASE_DIR/trivy-reports" \
  --skip-dirs "$BASE_DIR/trivy-state" \
  --skip-dirs "$BASE_DIR/trivy_script" \
  --skip-dirs "$BASE_DIR/portainer" \
  --skip-dirs "$BASE_DIR/semaphore" \
  --skip-dirs "$BASE_DIR/telegraf" \
  --format table \
  -o "$TXT"

CRITICAL=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity=="CRITICAL")] | length' "$JSON")
HIGH=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity=="HIGH")] | length' "$JSON")
TOTAL=$((CRITICAL + HIGH))

jq -r '
.Results[]?.Vulnerabilities[]?
| select(.Severity=="HIGH" or .Severity=="CRITICAL")
| "\(.Severity)|\(.PkgName)|\(.VulnerabilityID)"
' "$JSON" | sort -u > "$CURRENT_FILE"

comm -23 "$CURRENT_FILE" "$SEEN_FILE" > "$NEW_FILE"

NEW_TOTAL=$(wc -l < "$NEW_FILE")
TOP_NEW=$(head -10 "$NEW_FILE" | sed 's/|/ | /g')

echo "🚨 TRIVY SECURITY REPORT"
echo "Host=$(hostname)"
echo "HIGH=$HIGH"
echo "CRITICAL=$CRITICAL"
echo "TOTAL=$TOTAL"
echo "NUEVAS=$NEW_TOTAL"
echo ""

if [ "$NEW_TOTAL" -gt 0 ]; then
  echo "🆕 Nuevas vulnerabilidades:"
  echo "$TOP_NEW"
  cp "$CURRENT_FILE" "$SEEN_FILE"
else
  echo "Sin vulnerabilidades nuevas."
fi

echo ""
echo "Reporte TXT: $TXT"
echo "Reporte JSON: $JSON"

find "$OUT_DIR" \
  -type f \
  -name "trivy_host_high_critical_*" \
  -mtime +15 \
  -delete
