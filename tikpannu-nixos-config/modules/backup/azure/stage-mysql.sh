set -euo pipefail

die() {
  echo "${1:?}" >&2
  exit "${2:-1}"
}

: "${TARGET_DIR:?}"
: "${MYSQL_HOST:?}"
: "${MYSQL_USER:?}"
: "${MYSQL_PASSWORD:?}"

db_list=$(
  mysql --host="$MYSQL_HOST" --user="$MYSQL_USER" --password="$MYSQL_PASSWORD" \
    --batch --skip-column-names -e \
    "SHOW DATABASES WHERE \`Database\` NOT IN
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
  if ! mysqldump --host="$MYSQL_HOST" --user="$MYSQL_USER" --password="$MYSQL_PASSWORD" \
    --single-transaction --routines --triggers --events \
    --databases "$db" > "$outTarget"; then
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