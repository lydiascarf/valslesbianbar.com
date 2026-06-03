#!/bin/bash
set -euxo pipefail

today=$(date -u +%Y-%m-%d)
one_month_later=$(date -u -d "+1 month" +%Y-%m-%d)
echo "Generating events from $today to $one_month_later"

for template in content/events/repeating_templates/*.yaml; do
    if [ ! -f "$template" ]; then
        continue
    fi

    echo "Processing: $template"

    title=$(yq eval '.title' "$template")
    start_datetime=$(yq eval '.repeat.datetime' "$template")
    interval=$(yq eval '.repeat.interval' "$template")
    flyer=$(yq eval '.flyer' "$template")
    description=$(yq eval '.description' "$template")

    # Parse the start datetime (ISO 8601 format)
    start_date=$(echo "$start_datetime" | cut -d'T' -f1)
    start_time=$(echo "$start_datetime" | cut -d'T' -f2)
    start_seconds=$(date -d "$start_date" +%s)
    today_seconds=$(date -d "$today" +%s)
    one_month_seconds=$(date -d "$one_month_later" +%s)

    if [ "$interval" = "weekly" ]; then
        current_seconds=$start_seconds
        
        if [ $current_seconds -lt $today_seconds ]; then
            days_diff=$(( (today_seconds - current_seconds) / 86400 ))
            weeks_diff=$(( (days_diff + 6) / 7 ))
            current_seconds=$(( start_seconds + weeks_diff * 604800 ))
        fi
        
        while [ $current_seconds -le $one_month_seconds ]; do
            event_date=$(date -d "@$current_seconds" +%Y-%m-%d)
            event_datetime=$(date -d "@$current_seconds" +'%Y-%m-%dT%H:%M:%S%z' | sed 's/\([0-9][0-9]\)$/:\1/')
            
            sanitized_title=$(echo "$title" | tr '[:upper:]' '[:lower:]' | tr ' ' '_' | tr -cd '[:alnum:]_')
            output_file="content/events/repeating_generated/${event_date}_${sanitized_title}.yaml"
            
            if [ -f "$output_file" ]; then
                echo "Skipping (already exists): $output_file"
                current_seconds=$(( current_seconds + 604800 ))
                continue
            fi
            echo "Generating: $output_file"
            cat > "$output_file" <<EOF
title: "$title"
datetime: "$event_datetime"
flyer: "$flyer"
description: |
$(echo "$description" | sed 's/^/  /')
EOF

            # Move to next week
            current_seconds=$(( current_seconds + 604800 ))
        done
    fi
done

echo "Done :)"
