#!/usr/bin/env bash
# For each match, print: product_name<TAB>code
# Then print a summary line: Found N product(s) containing: "<INGREDIENT>"
set -euo pipefail
#Set bounds of a field to 1 gigabyte
export CSVKIT_FIELD_SIZE_LIMIT=$((1024 * 1024 * 1024))


usage() { 
    echo "Usage: $0 -i INGREDIENT_NAME -d SRC_PATH"
    echo "  -i search term/ingredient name (case-insensitive)"
    echo "  -d file path to folder containing products.csv (tab-separated)"
    echo "  -h show help"
    }
ING=""; FILEPATH="";
while getopts ":i:d:h" opt; do
    case $opt in
        i) ING=$OPTARG;;
        d) FILEPATH=$OPTARG;;
        h) usage; exit 0;;
        *) usage; exit 1;;
    esac
done

# Check for flags
[ -z "${ING:-}" ] && { echo "ERROR: -i <ingredient> is required" >&2; usage; exit 1; }
[ -z "${FILEPATH:-}" ] && { echo "ERROR: -d /path/to/folder is required" >&2; usage; exit 1; }

# Check file exists
CSV="${FILEPATH}/products.csv"
[ -s "$CSV" ] || { echo "ERROR: $CSV not found or empty." >&2; exit 1; }

# Check if csvkit installed
for cmd in csvcut csvgrep csvformat; do
    command -v "$cmd" >/dev/null 2>&1 || { echo "ERROR: $cmd not found. Please install csvkit." >&2; exit 1; }
done

# remove windows newlines
tmp_csv="$(mktemp)"
tr -d '\r' < "$CSV" > "$tmp_csv"

matches=$(mktemp)
csvcut -t -c ingredients_text,product_name,code "$tmp_csv" | csvgrep -c ingredients_text -r "(?i)$ING" | csvcut -c product_name,code | csvformat -T | tail -n +2 | tee "$matches"
# Prints lines and then a summary: Found N product(s) containing: "<ingredient>"
count="$(wc -l <"$matches" | tr -d ' ')"
echo '----'
echo "Found $count products containing: $ING"

rm -f "$tmp_csv" "$matches"
