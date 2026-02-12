#!/usr/bin/env bash
# Script to run make targets inside Docker containers
# Usage: ./run_targets.sh <docker_image> <docker_platform> <dirs_to_run> <target_to_run> <target_name>

set -euo pipefail

DOCKER_IMAGE="$1"
DOCKER_PLATFORM="$2"
DIRS_TO_RUN="$3"
TARGET_TO_RUN="$4"
TARGET_NAME="$5"
PWD=$(pwd)

# Colors
GREEN="\033[1;32m"
RED="\033[1;31m"
BLUE="\033[1;34m"
YELLOW="\033[1;33m"
RESET="\033[0m"

export LC_NUMERIC=C
printf "\n🐳 ${BLUE}Running target '${GREEN}${TARGET_NAME}${BLUE}' via Docker...${RESET}\n\n"

RESULT_FILE=$(mktemp)
total_start=$(date +%s.%N)

for dir in $DIRS_TO_RUN; do
    start=$(date +%s.%N)
    printf "📦 ${BLUE}Building${RESET} %s (Target: ${GREEN}${TARGET_TO_RUN}${RESET})\n" "$dir"
    
    if docker run --rm --platform "$DOCKER_PLATFORM" \
        -v "$PWD":/workspace -w /workspace \
        -v /var/run/docker.sock:/var/run/docker.sock \
        "$DOCKER_IMAGE" \
        make -s -C "$dir" "$TARGET_TO_RUN"; then
        
        end=$(date +%s.%N)
        elapsed=$(printf "%.2f" "$(echo "$end - $start" | bc)")
        printf "   ✅ ${GREEN}Success${RESET} (%s) — ${YELLOW}%ss${RESET}\n\n" "$dir" "$elapsed"
        echo "$dir|SUCCESS|$elapsed" >> "$RESULT_FILE"
    else
        end=$(date +%s.%N)
        elapsed=$(printf "%.2f" "$(echo "$end - $start" | bc)")
        printf "   ❌ ${RED}Error${RESET} (%s) — ${YELLOW}%ss${RESET}\n\n" "$dir" "$elapsed"
        echo "$dir|ERROR|$elapsed" >> "$RESULT_FILE"
    fi
done

total_end=$(date +%s.%N)
total_elapsed=$(printf "%.2f" "$(echo "$total_end - $total_start" | bc)")

printf "⏱  ${BLUE}Total time: ${YELLOW}%ss${RESET}\n\n" "$total_elapsed"

if [ -s "$RESULT_FILE" ]; then
    printf "${BLUE}────── SUMMARY ──────${RESET}\n"
    printf "%-65s %-10s %-10s\n" "Directory" "Result" "Time(s)"
    printf "%-65s %-10s %-10s\n" "-----------------------------------------------------------------" "--------" "--------"
    while IFS="|" read -r dir result time; do
        if [ "$result" = "SUCCESS" ]; then 
            color="${GREEN}"
            symbol="✅"
        else 
            color="${RED}"
            symbol="❌"
        fi
        printf "%-65s %-10b %-10s\n" "$dir" "$symbol $color$result${RESET}" "$time"
    done < "$RESULT_FILE"
    printf "${BLUE}──────────────────────${RESET}\n"
fi

rm -f "$RESULT_FILE"
