#!/bin/bash
threshold=0.005
last=""
for img in thumbs_labeled/*.jpg; do
  if [[ -n "$last" ]]; then
    diff=$(compare -metric RMSE "$last" "$img" null: 2>&1 | awk '{print $1}')
    echo "$last vs $img → $diff"
    if (( $(echo "$diff < $threshold" | bc -l) )); then
      echo "⏸️  Posible inactividad entre $last y $img"
    fi
  fi
  last="$img"
done
