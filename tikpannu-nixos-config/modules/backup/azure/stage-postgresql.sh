set -euo pipefail

die() {
  echo "${1:?}" >&2
  exit "${2:-1}"
}

: "${TARGET_DIR:?}"
: "${PGHOST:?}"
: "${PGUSER:?}"
: "${PGPASSWORD:?}"

db_list=$(
  psql -d postgres --no-align --tuples-only -c \
  "SELECT datname FROM pg_database
  WHERE datistemplate = false
  AND datname NOT IN ('postgres', 'azure_maintenance', 'azure_sys');"
) || {
  die "fatal: failed to list databases with psql"
}

if [[ -z "$db_list" ]]; then
  die "fatal: no databases found"
fi

# read newline separated string into array indices
mapfile -t databases_arr <<< "$db_list"

echo "Found postgresql databases:"
printf "%s\n" "${databases_arr[@]}"

all_succeeded=true
[[ -d "$TARGET_DIR" ]] || die "fatal: target directory '$TARGET_DIR' does not exist"

for db in "${databases_arr[@]}"; do
  [[ -n "$db" ]] || continue

  outTarget="$TARGET_DIR/$db.dump"
  echo "Staging $db to $outTarget"
  if ! pg_dump -d "$db" --format=directory --compress=none -f "$outTarget"; then
    echo "ERROR: failed to stage $db" >&2
    all_succeeded=false
  else
    echo "Staged $db"
  fi
done

# Allow backup group to read and delete all
chmod -R g+rwX "$TARGET_DIR"

if [[ "$all_succeeded" != true ]]; then
  die "Not all databases were staged, failing..."
fi

echo "Done"
