set -euo pipefail

die() {
  echo "${1:?}" >&2
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

all_succeeded=true
for sa in "${storage_accounts[@]}"; do
  echo "Staging storage account: $sa"
  # Backup ALL blob containers
  containers_str=$(az storage container list --account-name "$sa" --auth-mode login --query "[].name" -o tsv) || {
    all_succeeded=false
    echo "ERROR: could not list blob storage containers for $sa"
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
      all_succeeded=false
      echo "ERROR: failed to stage blob container $container of $sa"
    fi
  done

  # Backup ALL file shares
  # az storage share list/file download-batch don't support --auth-mode login;
  # use share-rm list (ARM) + azcopy (supports OAuth for Azure Files)
  rg=$(az storage account show --name "$sa" --query resourceGroup -o tsv) || {
    all_succeeded=false
    echo "ERROR: could not get resource group for $sa"
    continue
  }
  shares_str=$(az storage share-rm list --storage-account "$sa" --resource-group "$rg" --query "[].name" -o tsv) || {
    all_succeeded=false
    echo "ERROR: could not list file storage shares for $sa"
    shares_str=""
  }
  mapfile -t shares <<< "$shares_str"
  echo "Found the following file shares for $sa:"
  printf "%s\n" "${shares[@]}"

  for share in "${shares[@]}"; do
    [[ -n "$share" ]] || continue
    target_dir="$FILE_DIR/$sa/$share"
    echo "Staging file storage $share to $target_dir"
    mkdir -p "$target_dir"
    if ! azcopy sync \
           "https://${sa}.file.core.windows.net/${share}" \
           "$target_dir" \
           "${SYNC_FLAGS[@]}"; then
      all_succeeded=false
      echo "ERROR: failed to stage $share of $sa"
    fi
  done
done

# Allow backup group to read and delete all
chmod -R g+rwX "$FILE_DIR"
chmod -R g+rwX "$BLOB_DIR"

if [[ "$all_succeeded" != true ]]; then
  die "Not all staging jobs were successful, failing..."
fi

echo "Done"
