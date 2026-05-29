#!/bin/bash

FECHA=$(date +"%Y%m%d_%H%M")

BASE_DIR="/home/administrator"
OUT_DIR="$BASE_DIR/trivy-docker-reports"
STATE_DIR="$BASE_DIR/trivy-docker-state"

TRIVY="/usr/local/bin/trivy"

SEEN_FILE="$STATE_DIR/seen_container_vulns.txt"
CURRENT_FILE="$STATE_DIR/current_container_vulns.txt"
NEW_FILE="$STATE_DIR/new_container_vulns.txt"

TXT="$OUT_DIR/trivy_docker_high_critical_$FECHA.txt"
JSON_LIST="$OUT_DIR/trivy_docker_json_files_$FECHA.txt"

mkdir -p "$OUT_DIR"
mkdir -p "$STATE_DIR"
touch "$SEEN_FILE"

> "$CURRENT_FILE"
> "$NEW_FILE"
> "$TXT"
> "$JSON_LIST"

CONTAINERS=$(docker ps --format '{{.Names}}|{{.Image}}')
CONTAINERS_TOTAL=$(docker ps -q | wc -l)

if [ "$CONTAINERS_TOTAL" -eq 0 ]; then
  echo "🐳 TRIVY DOCKER SECURITY REPORT"
  echo "Host=$(hostname)"
  echo "Containers=0"
  echo "HIGH=0"
  echo "CRITICAL=0"
  echo "TOTAL=0"
  echo "NUEVAS=0"
  echo ""
  echo "No hay containers Docker en ejecución."
  echo ""
  echo "Reporte TXT: $TXT"
  echo "Reporte JSON: $JSON_LIST"
  exit 0
fi

while IFS='|' read -r CONTAINER IMAGE; do

  SAFE_NAME=$(echo "$CONTAINER" | tr '/: ' '___')

  JSON="$OUT_DIR/${SAFE_NAME}_$FECHA.json"
  TXT_CONTAINER="$OUT_DIR/${SAFE_NAME}_$FECHA.txt"

  echo "Container=$CONTAINER | Image=$IMAGE" >> "$TXT"
  echo "==================================================" >> "$TXT"

$TRIVY image \
  --quiet \
  --skip-db-update \
  --scanners vuln \
  --timeout 30m \
  --severity HIGH,CRITICAL \
  --format json \
  -o "$JSON" \
  "$IMAGE"

$TRIVY image \
  --quiet \
  --skip-db-update \
  --scanners vuln \
  --timeout 30m \
  --severity HIGH,CRITICAL \
  --format table \
  -o "$TXT_CONTAINER" \
  "$IMAGE"

  cat "$TXT_CONTAINER" >> "$TXT"
  echo "" >> "$TXT"

  echo "$JSON" >> "$JSON_LIST"

  jq -r --arg container "$CONTAINER" --arg image "$IMAGE" '
  .Results[]?.Vulnerabilities[]?
  | select(.Severity=="HIGH" or .Severity=="CRITICAL")
  | "\(.Severity)|\($container)|\($image)|\(.PkgName)|\(.VulnerabilityID)"
  ' "$JSON" >> "$CURRENT_FILE"

done <<< "$CONTAINERS"

sort -u "$CURRENT_FILE" -o "$CURRENT_FILE"
sort -u "$SEEN_FILE" -o "$SEEN_FILE"

comm -23 "$CURRENT_FILE" "$SEEN_FILE" > "$NEW_FILE"

CRITICAL=$(grep -c "^CRITICAL|" "$CURRENT_FILE" || true)
HIGH=$(grep -c "^HIGH|" "$CURRENT_FILE" || true)
TOTAL=$((CRITICAL + HIGH))

NEW_TOTAL=$(wc -l < "$NEW_FILE")
TOP_NEW=$(head -10 "$NEW_FILE" | sed 's/|/ | /g')

echo "🐳 TRIVY DOCKER SECURITY REPORT"
echo "Host=$(hostname)"
echo "Containers=$CONTAINERS_TOTAL"
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
echo "Reporte JSON: $JSON_LIST"

find "$OUT_DIR" -type f -mtime +15 -delete
