# arm64 support via multi-arch manifests

Date: 2026-09-13
Status: approved

## Goal

Publish `linux/arm64` builds of all three utilities (osmium, osm2pgsql,
osm2pgrouting) alongside the existing `linux/amd64` builds, and merge each pair
into a multi-arch manifest so that the tags users already pull resolve to the
right architecture automatically.

Today every published image is amd64-only. Users on Apple Silicon or AWS
Graviton pull an amd64 image and run it under QEMU emulation without being told,
which for a large PBF import is the difference between minutes and an hour.

## Outcome

`docker pull iboates/osm2pgsql:2.3.1` returns an arm64 image on arm64 hosts and
an amd64 image on amd64 hosts. No published tag name changes and no user-facing
command changes.

## Design

### Tag flow

Build jobs push architecture-suffixed tags. A merge job combines them into the
plain tag that exists today.

```
build (amd64) --> iboates/osm2pgsql:2.3.1-amd64 --+
                                                  +--> iboates/osm2pgsql:2.3.1
build (arm64) --> iboates/osm2pgsql:2.3.1-arm64 --+     (manifest list)
```

Per pipeline:

| Pipeline              | Final tags                     | Intermediates                  |
|-----------------------|--------------------------------|--------------------------------|
| osm2pgsql monthly     | `2.3.1` … `1.6.0`, `latest`    | `…-amd64`, `…-arm64`           |
| osm2pgsql nightly     | `latest-nightly`               | `latest-nightly-{amd64,arm64}` |
| osmium monthly        | `1.19.0` …, `latest`           | `…-amd64`, `…-arm64`           |
| osmium nightly        | `latest-nightly`               | `latest-nightly-{amd64,arm64}` |
| osm2pgrouting nightly | `2.3.8-nightly`, `latest-nightly` | `…-{amd64,arm64}`           |

The arch-suffixed intermediates remain visible on Docker Hub. This is accepted:
for osm2pgsql monthly the tag list grows from roughly 18 to roughly 54 entries.
The alternative, buildx `push-by-digest`, leaves no intermediate tags but
requires rewriting the working `docker build` / `docker push` shell scripts
around buildx. Rejected as too large a change to working code. The arch tags are
additionally useful to anyone wanting to pin an architecture.

### Workflow structure

All five existing workflow files are modified in place. No new workflow files,
no renames.

```yaml
on:
  workflow_dispatch:        # NEW - allows verification without waiting for cron
  schedule: [ ... ]         # unchanged
  push: [ ... ]             # unchanged

jobs:
  build:
    strategy:
      fail-fast: false      # an arm64 failure must not cancel amd64
      matrix:
        include:
          - { arch: amd64, runner: ubuntu-latest }
          - { arch: arm64, runner: ubuntu-24.04-arm }
    runs-on: ${{ matrix.runner }}
    # builds, tests, pushes <tag>-<arch>; records pushed tags to an artifact

  manifest:
    needs: build
    if: always()            # must run even when one arch failed
    runs-on: ubuntu-latest
    # merges <tag>-amd64 + <tag>-arm64 -> <tag>
```

`ubuntu-24.04-arm` is a free GitHub-hosted native arm64 runner for public
repositories, and this repository is public. arm64 images therefore compile
natively rather than under emulation. Emulated compilation was rejected: these
are full C++ source builds and the monthly osm2pgsql job rebuilds 18 versions,
which would risk the 6-hour job limit.

### Which architectures get merged

The merge step must never combine a stale arm64 tag from a previous run with a
freshly built amd64 tag. Probing the registry for existing tags cannot
distinguish the two, so instead each build job writes the tags it actually
pushed during that run to a job artifact. The manifest job downloads both
artifacts and merges, per version, whatever is present:

```
both present -> buildx imagetools create -t X  X-amd64  X-arm64
only amd64   -> buildx imagetools create -t X  X-amd64
only arm64   -> buildx imagetools create -t X  X-arm64
neither      -> skip
```

Concretely: each build/push script appends every tag it successfully pushed to
the file named by the `PUSHED_TAGS_FILE` environment variable, one fully
qualified tag per line, for example:

```
iboates/osm2pgsql:2.3.1-amd64
iboates/osm2pgsql:latest-amd64
```

When `PUSHED_TAGS_FILE` is unset the scripts skip this recording entirely, so
local usage is unaffected. The build job uploads that file as an artifact named
`pushed-tags-${{ matrix.arch }}`. The manifest job downloads both artifacts and,
for each recorded tag, strips the trailing `-amd64` or `-arm64` to derive the
target tag, then groups by target tag to decide what to merge.

This implements the agreed failure policy: publish whatever succeeded. A version
that cannot compile on arm64 keeps its amd64 tag exactly as it is published
today, so this change can never regress current behaviour. osm2pgsql monthly
rebuilds back to 1.6.0 (2020) against current Alpine, so some old versions
failing on arm64 is expected, not exceptional.

### Test strategy

Both test database images are amd64-only. Verified against their registry
manifests on 2026-09-13:

| Image                     | Used by                | Architectures                     |
|---------------------------|------------------------|-----------------------------------|
| `postgis/postgis:latest`  | osm2pgsql `test.sh`    | amd64 only                        |
| `pgrouting/pgrouting:latest` | osm2pgrouting nightly | amd64 only (single-arch manifest) |

The database is only a TCP peer of the binary under test, so it does not need to
be arm64 for the test to be meaningful. Therefore:

- **osmium** — its test is `docker run --rm osmium:$V | grep osmium`. No
  database, so the arm64 job needs no special handling and runs fully native.
- **osm2pgsql / osm2pgrouting** — add `platform: linux/amd64` to the database
  service in both compose files and a `docker/setup-qemu-action` step on the
  arm64 job. The binary under test runs native arm64; only its database peer is
  emulated. The assertions are unchanged from today.

`platform:` is a no-op on amd64 runners, so both architectures share one code
path rather than branching.

Swapping to a multi-arch database image was considered and rejected:
`imresamu/postgis` would cover osm2pgsql but changes the amd64 test path too,
and no multi-arch equivalent of `pgrouting/pgrouting` exists, so osm2pgrouting
would still need emulation. Skipping the import test on arm64 was rejected as it
would publish arm64 images that have never imported data.

### Script changes

All three utilities are driven from the workflows through the same `--suffix`
interface:

```
osmium/scripts/monthly_build_and_push.sh   --suffix amd64          1.19.0 1.18.0 ...
osm2pgrouting/scripts/nightly_build_and_push.sh --suffix nightly-amd64  2.3.8 ...
osm2pgsql/scripts/publish.sh               --suffix amd64
```

| File | Change |
|------|--------|
| `osm2pgsql/scripts/publish.sh` | No tagging change needed; `--suffix` already exists and flows into both the version tag and the latest tag. `build.sh`'s `${VERSION%%-*}` still resolves the correct dockerfile directory for `2.3.1-amd64` and `2.3.1-nightly-amd64`. Add recording of pushed tags to the artifact file. |
| `osmium/scripts/monthly_build_and_push.sh` | Add `--suffix` flag parsing; apply suffix to the pushed tags; record pushed tags. |
| `osmium/scripts/nightly_build_and_push.sh` | Same. |
| `osm2pgrouting/scripts/nightly_build_and_push.sh` | Same, plus the line 48 fix below. |
| `osm2pgsql/scripts/docker-compose.yaml` | Add `platform: linux/amd64` to the `postgis` service. |
| `osm2pgrouting/scripts/docker-compose.yaml` | Add `platform: linux/amd64` to the `postgis` service. |

osmium and osm2pgrouting currently treat every argument as a version number, so
their new argument parser must consume the flag before the version list. The
flag is optional and defaults to empty, preserving existing local usage.

### Pre-existing bug fixed alongside

`osm2pgrouting/scripts/nightly_build_and_push.sh:48` reads:

```bash
docker compose -f docker-compose.yaml.tmp run -v "$(pwd)":/data multiple primary keys \
```

where the service name `osm2pgrouting` belongs. `docker compose run` takes
`multiple` as the service name and fails, leaving `count` at 0, so the nightly
push is skipped — that pipeline has been publishing nothing.

This is in scope because the test gate decides whether a push happens: while it
is broken the arm64 osm2pgrouting images would never publish either, and the new
arm64 path could not be verified. It lands as its own commit, separate from the
arm64 work.

## Risks

- **Old versions may not compile on arm64.** Expected and handled by design;
  they stay amd64.
- **Monthly osm2pgsql arm64 job duration.** 18 versions, each a native build
  plus an import test against an emulated database, against the 6-hour job
  limit. It runs in parallel with amd64 so it does not extend the amd64 path.
  Mitigation if it times out: shard the version list across matrix entries. Ship
  first and measure rather than pre-optimising.

## Verification

`workflow_dispatch` allows triggering a real run rather than waiting for cron.

Success criteria:

1. `docker buildx imagetools inspect iboates/osm2pgsql:2.3.1` lists both
   `linux/amd64` and `linux/arm64`.
2. The same holds for osmium and osm2pgrouting current versions and for the
   `latest` and `latest-nightly` tags.
3. Plain tags for any arm64-failing old version are still present and still
   resolve to amd64.
4. The osm2pgrouting nightly pipeline pushes images again.

## Conventions

Commits are authored as `iboates <iboates@gmail.com>`, set repo-locally. No
`Co-Authored-By` trailers.
