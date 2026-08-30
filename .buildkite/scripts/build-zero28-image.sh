#!/usr/bin/env bash
set -euo pipefail

# Native Buildkite Zero 28 image build (flashable .img.gz).
# Requires: Linux x86_64 agent, Docker, >=180 GiB free, git, make.
# Env: KNULLI_BUILD_ROOT (optional persistent cache root)

echo "--- :disk: Prepare build directories"
REPO_SLUG="${BUILDKITE_PIPELINE_SLUG:-knulli-zero-28}"
BUILD_ROOT="${KNULLI_BUILD_ROOT:-${HOME}/.cache/knulli-buildkite/${REPO_SLUG}}"
mkdir -p "${BUILD_ROOT}"/{ccache,downloads,output}
export CCACHE_DIR="${BUILD_ROOT}/ccache"
export DL_DIR="${BUILD_ROOT}/downloads"
export OUTPUT_DIR="${BUILD_ROOT}/output"

available_bytes=$(df --output=avail -B1 "${BUILD_ROOT}" | tail -1 | tr -d ' ')
available_gib=$((available_bytes / 1024 / 1024 / 1024))
required_gib="${KNULLI_MIN_FREE_GIB:-180}"
required_bytes=$((required_gib * 1024 * 1024 * 1024))
df -h "${BUILD_ROOT}" || true
echo "BUILD_ROOT=${BUILD_ROOT}"
echo "free=${available_gib} GiB  required=${required_gib} GiB"

if ((available_bytes < required_bytes)); then
  cat >&2 <<EOF
ERROR: Not enough free disk for a full KNULLI A133 image build.

  BUILD_ROOT: ${BUILD_ROOT}
  Free:       ${available_gib} GiB
  Required:   ${required_gib} GiB (override with KNULLI_MIN_FREE_GIB, not recommended below 180)

A full Buildroot tree + Docker layers typically needs ~150-200 GiB.
This agent only has ~${available_gib} GiB free — the build cannot succeed here.

Fix options:
  1) Attach a large volume and set on the agent / build env:
       KNULLI_BUILD_ROOT=/mnt/bigdisk/knulli
  2) Free space on the agent (docker system prune -af, remove old outputs).
  3) Try the linux-large queue (BUILDKITE_QUEUE_IMAGE=linux-large), or use a
     different machine with >=${required_gib} GiB free + Docker.

  df -h ${BUILD_ROOT}
  docker system df
EOF
  if command -v buildkite-agent >/dev/null; then
    printf '%s\n' "### Disk space insufficient" "" \
      "Free **${available_gib} GiB** at \`${BUILD_ROOT}\`; need **${required_gib} GiB**." "" \
      "Set \`KNULLI_BUILD_ROOT\` to a large volume or expand the agent disk." \
      | buildkite-agent annotate --style "error" --context "zero28-disk" || true
  fi
  exit 1
fi

docker info >/dev/null

if [[ "${CLEAN_OUTPUT:-}" == "1" || "${CLEAN_OUTPUT:-}" == "true" ]]; then
  echo "--- :broom: Clean previous a133 output"
  rm -rf "${OUTPUT_DIR}/a133" || true
fi

# Buildkite checkout can omit recursive submodules.
echo "--- :git: Submodules"
git submodule update --init --recursive

echo "--- :docker: Build knulli build container"
make build-docker-image

echo "--- :hammer: make a133-build (MagicX Zero 28 only)"
# This EXTRA_OPTS quoting must match the GitHub Actions workflow.
make \
  BATCH_MODE=1 \
  PARALLEL_BUILD=1 \
  'EXTRA_OPTS=BR2_TARGET_KNULLI_IMAGES=\"allwinner/a133/magicx-zero-28\"' \
  a133-build

IMG_DIR="${OUTPUT_DIR}/a133/images/knulli/images/magicx-zero-28"
echo "--- :package: Collect artifacts"
mkdir -p artifacts/magicx-zero-28
shopt -s nullglob
files=("${IMG_DIR}"/*.img.gz "${IMG_DIR}"/*.img.gz.md5 "${IMG_DIR}"/*.img.gz.sha256)
if ((${#files[@]} == 0)); then
  echo "No images under ${IMG_DIR}" >&2
  ls -laR "${OUTPUT_DIR}/a133/images" 2>/dev/null || true
  exit 1
fi
cp -v "${files[@]}" artifacts/magicx-zero-28/

ls -lh artifacts/magicx-zero-28/

{
  echo "### MagicX Zero 28 flashable image"
  echo ""
  echo "Download the Buildkite artifacts from this job (\`.img.gz\`)."
  echo ""
  echo "Flash with balenaEtcher or:"
  echo '```'
  echo "gzcat knulli-*.img.gz | sudo dd of=/dev/rdiskN bs=4m"
  echo '```'
  echo ""
  echo '```'
  ls -lh artifacts/magicx-zero-28/
  echo '```'
} | buildkite-agent annotate --style "success" --context "zero28-image" || true

echo "+++ Done"
