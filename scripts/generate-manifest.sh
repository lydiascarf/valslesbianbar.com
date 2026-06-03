#!/bin/bash

MANIFEST_FILE="manifest.json"
TEMP_FILE=$(mktemp)

echo "[" > "$TEMP_FILE"

first=true

# Process oneoffs
for file in content/events/oneoffs/*.{yaml,yml}; do
  if [ -f "$file" ]; then
    if [ "$first" = false ]; then
      echo "," >> "$TEMP_FILE"
    fi
    filename=$(basename "$file")
    echo filename: $filename
    cat >> "$TEMP_FILE" << EOF
  {
    "name": "$filename",
    "path": "$file",
    "type": "oneoff"
  }
EOF
    first=false
  fi
done

# Process repeating_generated
for file in content/events/repeating_generated/*.{yaml,yml}; do
  if [ -f "$file" ]; then
    if [ "$first" = false ]; then
      echo "," >> "$TEMP_FILE"
    fi
    filename=$(basename "$file")
    cat >> "$TEMP_FILE" << EOF
  {
    "name": "$filename",
    "path": "$file",
    "type": "repeating"
  }
EOF
    first=false
  fi
done

echo "" >> "$TEMP_FILE"
echo "]" >> "$TEMP_FILE"

mv "$TEMP_FILE" "$MANIFEST_FILE"
echo "Manifest generated: $MANIFEST_FILE"
