#!/bin/bash

VERSION="HTTP FILTER v1.1 | Designed By YogSec"
HEADER="HTTP FILTER | Designed By YogSec"

# ANSI color codes
RED="\e[1;31m"
GREEN="\e[1;32m"
BLUE="\e[1;34m"
YELLOW="\e[1;33m"
NC="\e[0m" # No Color

display_help() {
    echo -e "${BLUE}$HEADER${NC}"
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -h              Show this help message"
    echo "  -v              Show version information"
    echo "  -l <file>       Process a list of URLs from a file"
    echo "  -d <url>        Check a single URL"
    echo "  -t <seconds>    Set custom timeout (default: 10s)"
    echo "  -r <count>      Retry failed requests (default: 0)"
    echo "  -V              Enable verbose mode (show response time)"
    exit 0
}

display_version() {
    echo -e "${BLUE}$VERSION${NC}"
    exit 0
}

# Validate URL format (basic check)
validate_url() {
    if [[ ! $1 =~ ^https?:// ]]; then
        echo -e "${RED}[ERROR] Invalid URL format: $1${NC}" >&2
        return 1
    fi
    return 0
}

process_url() {
    local url=$1
    local timeout=$2
    local retries=$3
    local verbose=$4
    local attempt=0
    local max_attempts=$((retries + 1))
    local response
    local time_taken

    validate_url "$url" || return

    while [ $attempt -lt $max_attempts ]; do
        if [ "$verbose" == "true" ]; then
            response=$(curl -s -o /dev/null -w "%{http_code}|%{time_total}" --max-time "$timeout" "$url")
            IFS='|' read -r status time_taken <<< "$response"
        else
            status=$(curl -s -o /dev/null -w "%{http_code}" --max-time "$timeout" "$url")
        fi

        if [ "$status" == "000" ]; then
            ((attempt++))
            if [ $attempt -eq $max_attempts ]; then
                echo "$url" >> "$OUTPUT_DIR/failed.txt"
                echo -e "${RED}[FAILED] $url${NC}"
            else
                sleep 1 # Brief delay before retry
                continue
            fi
        else
            echo "$url" >> "$OUTPUT_DIR/$status.txt"
            if [ "$verbose" == "true" ]; then
                echo -e "${GREEN}[$status] $url (${YELLOW}${time_taken}s${GREEN})${NC}"
            else
                echo -e "${GREEN}[$status] $url${NC}"
            fi
            break
        fi
    done
}

process_list() {
    local input_file=$1
    local timeout=$2
    local retries=$3
    local verbose=$4

    if [ ! -f "$input_file" ] || [ ! -r "$input_file" ]; then
        echo -e "${RED}[ERROR] File '$input_file' not found or unreadable${NC}" >&2
        exit 1
    fi

    OUTPUT_DIR="${input_file%.*}_responses_$(date +%s)"
    mkdir -p "$OUTPUT_DIR"
    echo -e "${BLUE}[INFO] Saving results to $OUTPUT_DIR${NC}"

    export -f process_url validate_url
    export OUTPUT_DIR RED GREEN YELLOW NC

    xargs -P 10 -I {} bash -c "process_url \"\$@\" \"$timeout\" \"$retries\" \"$verbose\"" _ {} < "$input_file"

    # Generate summary
    echo -e "${BLUE}\n[SUMMARY]${NC}"
    for file in "$OUTPUT_DIR"/*.txt; do
        if [ -f "$file" ]; then
            count=$(wc -l < "$file")
            status=$(basename "$file" .txt)
            echo -e "${YELLOW}$status: $count URLs${NC}"
        fi
    done
}

check_single_url() {
    local url=$1
    local timeout=$2
    local retries=$3
    local verbose=$4

    process_url "$url" "$timeout" "$retries" "$verbose"
}

# Default values
TIMEOUT=10
RETRIES=0
VERBOSE=false

if [ $# -eq 0 ]; then
    display_help
fi

while getopts ":hvl:d:t:r:V" opt; do
    case $opt in
        h) display_help ;;
        v) display_version ;;
        l) process_list "$OPTARG" "$TIMEOUT" "$RETRIES" "$VERBOSE" ;;
        d) check_single_url "$OPTARG" "$TIMEOUT" "$RETRIES" "$VERBOSE" ;;
        t) TIMEOUT="$OPTARG" ;;
        r) RETRIES="$OPTARG" ;;
        V) VERBOSE=true ;;
        *) echo -e "${RED}Invalid option: -$OPTARG${NC}" >&2; display_help ;;
    esac
done
