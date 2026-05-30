set -euo pipefail

die() {
  echo "<3>${1:?}" >&2
  exit "${2:-1}"
}

: "${BLOB_DIR:?}"
: "${FILE_DIR:?}"
: "${AZURE_CLIENT_SECRET_FILE:?}"
: "${AZURE_CLIENT_ID:?}"
: "${AZURE_TENANT_ID:?}"

# @ = secret in that file
az login --service-principal -u "$AZURE_CLIENT_ID" -p "@${AZURE_CLIENT_SECRET_FILE}" --tenant "$AZURE_TENANT_ID"

# use az cli's login for azcopy
export AZCOPY_AUTO_LOGIN_TYPE=AZCLI
SYNC_FLAGS=("--recursive" "--delete-destination=true")

# Get ALL storage accounts (exclude terraform state bucket)
storage_accounts_str=$(az storage account list --query "[?name!='tikprodterraform'].name" -o tsv) || {
  die "fatal: failed to list Azure storage accounts"
}
mapfile -t storage_accounts <<< "$storage_accounts_str"
echo "Found storage accounts:"
printf "%s\n" "${storage_accounts[@]}"

failed_syncs=()

snapshots=()
clean_snapshots() {
  local not_deleted=() sa rg share snapshot i
  for ((i = 0; i < ${#snapshots[@]}; i += 4)); do
    sa=${snapshots[i]}
    rg=${snapshots[i+1]}
    share=${snapshots[i+2]}
    snapshot=${snapshots[i+3]}
    az storage share-rm delete \
      --storage-account "$sa" \
      --resource-group "$rg" \
      --name "$share" \
      --snapshot "$snapshot" \
      --yes > /dev/null || {
      echo "<4>WARN: failed to delete snapshot $snapshot of $sa/$share"
      not_deleted+=("$sa" "$rg" "$share" "$snapshot")
    }
  done

  snapshots=("${not_deleted[@]}")
}
cleanup_trap() {
  rc=$?
  clean_snapshots
  exit "$rc"
}
trap cleanup_trap EXIT

for sa in "${storage_accounts[@]}"; do
  echo "Staging storage account: $sa"
  # Backup ALL blob containers
  containers_str=$(az storage container list --account-name "$sa" --auth-mode login --query "[].name" -o tsv) || {
    failed_syncs+=("all $sa blob containers")
    echo "<3>ERROR: could not list blob storage containers for $sa"
    containers_str=""
  }
  mapfile -t containers <<< "$containers_str"
  echo "Found the following blob containers for $sa:"
  printf "%s\n" "${containers[@]}"

  for container in "${containers[@]}"; do
    [[ -n "$container" ]] || continue
    target_dir="$BLOB_DIR/$sa/$container/"
    echo "Staging blob container $container to $target_dir"
    mkdir -p "$target_dir"
    if ! azcopy sync \
           "https://${sa}.blob.core.windows.net/${container}" \
           "$target_dir" \
           "${SYNC_FLAGS[@]}"; then
      failed_syncs+=("$sa: blob container $container")
      echo "<3>ERROR: failed to stage blob container $container of $sa"
    fi
  done

  # Backup ALL file shares
  # az storage share list/file download-batch don't support --auth-mode login;
  # use share-rm list (ARM) + azcopy (supports OAuth for Azure Files)
  rg=$(az storage account show --name "$sa" --query resourceGroup -o tsv) || {
    failed_syncs+=("all $sa file shares")
    echo "<3>ERROR: could not get resource group for $sa"
    continue
  }
  shares_str=$(az storage share-rm list --storage-account "$sa" --resource-group "$rg" --query "[].name" -o tsv) || {
    failed_syncs+=("all $sa file shares")
    echo "<3>ERROR: could not list file storage shares for $sa"
    shares_str=""
  }
  mapfile -t shares <<< "$shares_str"
  echo "Found the following file shares for $sa:"
  printf "%s\n" "${shares[@]}"

  for share in "${shares[@]}"; do
    [[ -n "$share" ]] || continue
    target_dir="$FILE_DIR/$sa/$share"
    echo "Staging file share $share to $target_dir"
    mkdir -p "$target_dir"
    if snapshot=$(
      az storage share-rm snapshot \
        --storage-account "$sa" \
        --resource-group "$rg" \
        --name "$share" \
        --query snapshotTime -o tsv
    ) && [[ -n "$snapshot" ]]; then
      # az storage share-rm returns the snapshot time with a +00:00 offset, but
      # the data-plane "sharesnapshot" query param expects the ...Z form (and a
      # literal + in a URL query string would be read as a space).
      snapshot="${snapshot/+00:00/Z}"
      echo "Created snapshot $snapshot for $sa/$share"
      snapshots+=("$sa" "$rg" "$share" "$snapshot")
    else
      snapshot=""
      echo "<4>WARN: failed to create snapshot for file share $share of $sa, attempting sync without snapshot"
    fi

    url="https://${sa}.file.core.windows.net/${share}"
    if [[ -n "$snapshot" ]]; then
      url="${url}?sharesnapshot=${snapshot}"
    fi
    if ! azcopy sync \
           "$url" \
           "$target_dir" \
           "${SYNC_FLAGS[@]}"; then
      failed_syncs+=("$sa: file share $share")
      echo "<3>ERROR: failed to stage file share $share of $sa"
    fi

    clean_snapshots
  done
done

if [[ "${#failed_syncs[@]}" -ne 0 ]]; then
  echo "<3>The following syncs have failed:"
  printf "<3>%s\n" "${failed_syncs[@]}"
  die "Not all staging jobs were successful, failing..."
fi

echo "All syncs succeeded"
