set -euo pipefail

die() {
  echo "${1:?}" >&2
  exit "${2:-1}"
}

: "${TARGET_DIR:?}"
: "${MYSQL_CNF:?}"

db_list=$(
  mysql --defaults-file="$MYSQL_CNF" --batch --skip-column-names -e \
  "SELECT schema_name FROM information_schema.schemata
  WHERE schema_name NOT IN
  ('information_schema', 'mysql', 'performance_schema', 'sys');"
) || {
  die "fatal: failed to list databases with mysql"
}

if [[ -z "$db_list" ]]; then
  die "fatal: no databases found"
fi

# read newline separated string into array indices
mapfile -t databases_arr <<< "$db_list"

echo "Found mysql databases:"
printf "%s\n" "${databases_arr[@]}"

all_succeeded=true
[[ -d "$TARGET_DIR" ]] || die "fatal: target directory '$TARGET_DIR' does not exist"

for db in "${databases_arr[@]}"; do
  [[ -n "$db" ]] || continue

  outTarget="$TARGET_DIR/$db.sql"
  echo "Staging $db to $outTarget"

  if ! mysqldump --defaults-file="$MYSQL_CNF" \
    --single-transaction \
    --no-tablespaces \
    --routines \
    --events \
    --triggers \
    --set-gtid-purged=OFF \
    --databases "$db" \
    --result-file="$outTarget"; then
    echo "ERROR: failed to stage $db" >&2
    all_succeeded=false
  else
    echo "Staged $db"
  fi
done

if [[ "$all_succeeded" != true ]]; then
  die "Not all databases were staged, failing..."
fi

echo "Done"
