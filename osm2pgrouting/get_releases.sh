#!/bin/bash

# Configuration
GITHUB_REPO="pgRouting/osm2pgrouting"
TARGET_DIR="./dockerfiles"
TEMPLATE_DOCKERFILE="./template_Dockerfile"


# Create target directory if it doesn't exist
mkdir -p "$TARGET_DIR"

# Fetch tags from GitHub API
TAGS=$(curl -s "https://api.github.com/repos/$GITHUB_REPO/tags" | jq -r '.[].name')

# Iterate over tags, create directories, and populate Dockerfiles
for TAG in $TAGS; do
    # Remove leading 'v' if present
    CLEAN_TAG=$(echo $TAG | sed 's/^v//')

    # Directory for the current tag
    DIR="$TARGET_DIR/$CLEAN_TAG"
    mkdir -p "$DIR"

    # Replace {{ version }} in the Dockerfile template and write to the new location
    sed "s/{{ version }}/$CLEAN_TAG/g" "$TEMPLATE_DOCKERFILE" > "$DIR/Dockerfile"

    echo "Created Dockerfile for $CLEAN_TAG in $DIR"
done

echo "All Dockerfiles have been created."