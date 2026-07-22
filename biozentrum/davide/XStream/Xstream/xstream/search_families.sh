#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 3 ]]; then
    echo "Usage: $0 INPUT_FOLDER RESULTS_FOLDER XSTREAM_JAR"
    exit 1
fi

INPUT_FOLDER=$(realpath "$1")
RESULTS_FOLDER=$(realpath -m "$2")
XSTREAM_JAR=$(realpath "$3")

mkdir -p "$RESULTS_FOLDER"

find "$INPUT_FOLDER" -maxdepth 1 -type f -print0 |
while IFS= read -r -d '' INPUT_FILE; do
    FILE_NAME=$(basename "$INPUT_FILE")
    OUTPUT_FOLDER="$RESULTS_FOLDER/$FILE_NAME"

    echo "Processing: $FILE_NAME"

    mkdir -p "$OUTPUT_FOLDER"

    (
        cd "$OUTPUT_FOLDER"

        java -Xmx4g -Duser.language=en \
            -jar "$XSTREAM_JAR" "$INPUT_FILE" \
            -m7 \
            -x15 \
            -e2 \
            -L10 \
            -i.7 \
            -I.8 \
            -z \
            -G
    )

    echo "Results written to: $OUTPUT_FOLDER"
done
