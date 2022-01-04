#!/bin/bash
# TERRAFORM INIT SCRIPT. SOURCE THIS TO SETUP SHELL FOR TERRAFORM APPLY
# . ./init.sh <workspace>
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "Please source this script. Like this:"
  echo . ${0}
  exit 1
fi

# Workspace name required as parameter.
WORKSPACE=$1

if [ -z "$WORKSPACE" ]; then
  echo Missing argument: workspace name
  return 1
fi

case "$WORKSPACE" in
  prod)
    SUBSCRIPTION_NAME="Microsoft Azure Sponsorship"
    TFSTATE_STORAGE_RESOURCE_GROUP_NAME="terraform-state"
    TFSTATE_STORAGE_ACCOUNT_NAME="tikprodterraform"
    ;;
  *)
    echo "Unsupported workspace $WORKSPACE" >&2
    exit 1
    ;;
esac

SUBSCRIPTION=$(az account show --query 'id' --output tsv --subscription "$SUBSCRIPTION_NAME")
echo "Activating subscription: $SUBSCRIPTION ($SUBSCRIPTION_NAME)"
az account set --subscription "$SUBSCRIPTION"
TFSTATE_STORAGE_ACCOUNT_KEY=$(az storage account keys list --account-name "$TFSTATE_STORAGE_ACCOUNT_NAME" --resource-group "$TFSTATE_STORAGE_RESOURCE_GROUP_NAME" --subscription "$SUBSCRIPTION" --query "[?keyName=='key1'].value" --output tsv)

cat >> config.azurerm.tfbackend << EOF
storage_account_name = "$TFSTATE_STORAGE_ACCOUNT_NAME"
access_key           = "$TFSTATE_STORAGE_ACCOUNT_KEY"
EOF

echo "Initializing terraform"
terraform init -backend-config=config.azurerm.tfbackend

TF_WORKSPACES=$(terraform workspace list)
if [[ "$TF_WORKSPACES" =~ "$WORKSPACE" ]]
then
  echo "Switching to workspace ${WORKSPACE}"
  terraform workspace select "$WORKSPACE"
else
  echo "Workspace does not exist, creating"
  terraform workspace new "$WORKSPACE"
fi
