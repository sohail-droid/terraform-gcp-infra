#!/bin/bash

PROJECT_ID="$1"

if [ -z "$PROJECT_ID" ]; then
  echo "Error: Project ID not provided." >&2
  exit 1
fi

gcloud compute instances list --project="$PROJECT_ID" --format=json | jq '[.[] | {id: .id, zone: .zone}]' > instances.json

# ./myscript.sh argument1 argument2