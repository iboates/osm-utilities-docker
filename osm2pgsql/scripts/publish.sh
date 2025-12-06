#!/bin/bash

DRY_RUN=false

force_dir() {
    # Traverse up until we find "osm-utilities-docker"
    while [[ "$PWD" != "/" && "$(basename "$PWD")" != "osm-utilities-docker" ]]; do
        cd ..
    done

    # Ensure we're in "osm-utilities-docker", then move into "osm2pgsql/scripts"
    if [[ "$(basename "$PWD")" == "osm-utilities-docker" ]]; then
        cd osm2pgsql/scripts || { echo "Error: scripts directory not found"; exit 1; }
    else
        exit 1
    fi

    cd ..
}

parse_args() {
  SUFFIX=""

  while [[ $# -gt 0 ]]; do
      case "$1" in
          --suffix)
              if [[ -n "$2" ]]; then
                  SUFFIX="-$2"
                  shift
              else
                  echo "Error: --suffix requires a value."
                  exit 1
              fi
              ;;
          --dry-run|-n)
              DRY_RUN=true
              ;;
          *)
              echo "Unknown argument: $1"
              exit 1
              ;;
      esac
      shift
  done
}

force_dir
parse_args "$@"

VERSIONS=()
for dir in ./dockerfiles/*/; do
    VERSION=$(basename "$dir")

    # Skip the "legacy" folder
    if [[ "$VERSION" == "legacy" ]]; then
        continue
    fi

    VERSIONS+=("$VERSION$SUFFIX")
done


SORTED_VERSIONS=($(printf "%s\n" "${VERSIONS[@]}" | sort -V))
LARGEST_VERSION="${SORTED_VERSIONS[-1]}"
LATEST_TAG="latest$SUFFIX"

###########################################
# DRY RUN MODE — list what would be built #
###########################################
if [[ "$DRY_RUN" == true ]]; then
    echo "Dry run mode enabled."
    echo "Images that would be built and pushed:"
    echo

    for VERSION in "${SORTED_VERSIONS[@]}"; do
        echo " - iboates/osm2pgsql:${VERSION}"
    done

    echo
    echo "Latest tag would be:"
    echo " - iboates/osm2pgsql:${LATEST_TAG}"
    echo
    exit 0
fi

###########################################
# NORMAL MODE — build and push images     #
###########################################

FAILED_VERSIONS=""

for VERSION in "${SORTED_VERSIONS[@]}"; do

    # Build image
    if ! ./scripts/build.sh "$VERSION" &> /dev/null; then
        echo -e "$VERSION: \033[31mBUILD FAILED\033[0m"
        echo "error_detected=true" >> $GITHUB_ENV
        FAILED_VERSIONS+="- $VERSION (Build Failed)\\n"
        docker image rm --force --no-prune iboates/osm2pgsql:"$VERSION"
        docker image rm --force --no-prune osm2pgsql:"$VERSION"
        continue
    fi
    echo -e "$VERSION: \033[32mBUILT\033[0m"

    # Test built image
    TEST_RESULT=$(./scripts/test.sh "$VERSION")
    if [[ "$TEST_RESULT" == *"PASSED"* ]]; then
        echo -e "$VERSION: \033[32mTEST PASSED\033[0m"
        docker tag osm2pgsql:"$VERSION" iboates/osm2pgsql:"$VERSION"

        # Push image if tests pass
        if ! docker push iboates/osm2pgsql:"$VERSION" &> /dev/null; then
            echo -e "$VERSION: \033[31mPUSH FAILED\033[0m"
            echo "error_detected=true" >> $GITHUB_ENV
            FAILED_VERSIONS+="- $VERSION (Push Failed)\\n"
            docker image rm --force --no-prune iboates/osm2pgsql:"$VERSION"
            docker image rm --force --no-prune osm2pgsql:"$VERSION"
            continue
        fi
        echo -e "$VERSION: \033[32mPUSHED\033[0m"

        # Tag largest version as latest and push
        if [[ "$VERSION" == "$LARGEST_VERSION" ]]; then
            docker tag osm2pgsql:"$VERSION" iboates/osm2pgsql:"$LATEST_TAG"
            if ! docker push iboates/osm2pgsql:"$LATEST_TAG" &> /dev/null; then
                echo -e "$LATEST_TAG: \033[31mPUSH FAILED\033[0m"
                echo "error_detected=true" >> $GITHUB_ENV
                FAILED_VERSIONS+="- $LATEST_TAG (Push Failed)\\n"
            else
                echo -e "$LATEST_TAG: \033[32mPUSHED\033[0m"
            fi
        fi
    else
        echo -e "$VERSION: \033[31mTEST FAILED\033[0m"
        echo "error_detected=true" >> $GITHUB_ENV
        FAILED_VERSIONS+="- $VERSION (Test Failed)\\n"
    fi

    docker image rm --force --no-prune iboates/osm2pgsql:"$VERSION"
    docker image rm --force --no-prune osm2pgsql:"$VERSION"

done

echo "FAILED_VERSIONS=$FAILED_VERSIONS" >> $GITHUB_ENV
