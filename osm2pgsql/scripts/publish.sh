#!/bin/bash

force_dir() {
    # Traverse up until we find "osm-utilities-docker"
    while [[ "$PWD" != "/" && "$(basename "$PWD")" != "osm-utilities-docker" ]]; do
        cd ..
    done

    # Ensure we're in "osm-utilities-docker", then move into "osm2pgsql/scripts"
    if [[ "$(basename "$PWD")" == "osm-utilities-docker" ]]; then
        cd osm2pgsql/scripts || { echo "Error: scripts directory not found"; exit 1; }
    else
        # echo "Error: Not inside osm-utilities-docker or its subdirectories"
        exit 1
    fi

    cd ..

    # echo "Now in $(pwd)"
}

parse_suffix() {
  SUFFIX=""  # Declare in global scope

  while [[ $# -gt 0 ]]; do
      case "$1" in
          --suffix)
              if [[ -n "$2" ]]; then
                  SUFFIX="-$2"  # Assign value to global variable
                  shift
              else
                  echo "Error: --suffix requires a value."
                  exit 1
              fi
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
parse_suffix "$@"

VERSIONS=()
for dir in ./dockerfiles/*/; do
    # Extract the base name (folder name)
    VERSION=$(basename "$dir")
    VERSIONS+=("$VERSION$SUFFIX")
done

SORTED_VERSIONS=($(printf "%s\n" "${VERSIONS[@]}" | sort -V))
# echo "Sorted Versions: ${SORTED_VERSIONS[@]}"
LARGEST_VERSION="${SORTED_VERSIONS[-1]}"
LATEST_TAG="latest$SUFFIX"

# Loop through each version code to build the images
for VERSION in "${SORTED_VERSIONS[@]}"; do
  echo "failed_test=true;version=$VERSION|" >> $GITHUB_ENV
#  ./scripts/build.sh "$VERSION" &> /dev/null
#  echo -e "$VERSION: \033[32mBUILT\033[0m"
#
#  TEST_RESULT=$(./scripts/test.sh "$VERSION")
#  if [[ "$TEST_RESULT" == *"PASSED"* ]]; then
#      echo -e "$VERSION: \033[32mTEST PASSED\033[0m"
#      docker tag osm2pgsql:"$VERSION" iboates/osm2pgsql:"$VERSION"
#      docker push iboates/osm2pgsql:"$VERSION" &> /dev/null
#      echo -e "$VERSION: \033[32mPUSHED\033[0m"
#
#      # If this is the largest version, tag it as "latest"
#      if [[ "$VERSION" == "$LARGEST_VERSION" ]]; then
#          docker tag osm2pgsql:"$VERSION" iboates/osm2pgsql:"$LATEST_TAG"
#          docker push iboates/osm2pgsql:"$LATEST_TAG" &> /dev/null
#          echo -e "$LATEST_TAG: \033[32mPUSHED\033[0m"
#      fi
#  else
#      echo -e "$VERSION: \033[31mTEST FAILED\033[0m"
#      # TODO: create issue on failure
#      echo "failed_test=true;version=$VERSION|" >> $GITHUB_ENV
#  fi
done
