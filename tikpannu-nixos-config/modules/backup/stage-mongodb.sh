set -euo pipefail

die() {
  echo "${1:?}" >&2
  exit "${2:-1}"
}

: "${TARGET_DIR:?}"
: "${MONGO_CONFIG:?}"

[[ -d "$TARGET_DIR" ]] || die "fatal: target directory '$TARGET_DIR' does not exist"

mongodump --config="$MONGO_CONFIG" --out="$TARGET_DIR"

echo "Done"
