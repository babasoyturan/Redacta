[CmdletBinding(SupportsShouldProcess = $true)]
param(
  [Parameter(Mandatory = $true)]
  [string]$Location,

  [Parameter(Mandatory = $true)]
  [ValidatePattern('^[a-z0-9]{3,24}$')]
  [string]$StorageAccountName,

  [string]$ResourceGroupName = "rg-redacta-tfstate",

  [string]$ContainerName = "tfstate"
)

$ErrorActionPreference = "Stop"

if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
  throw "Azure CLI is required to bootstrap Terraform state."
}

if ($PSCmdlet.ShouldProcess($ResourceGroupName, "Create Terraform state resource group")) {
  az group create `
    --name $ResourceGroupName `
    --location $Location `
    --tags Project=redacta ManagedBy=bootstrap Purpose=tfstate `
    --output none
}

if ($PSCmdlet.ShouldProcess($StorageAccountName, "Create Terraform state storage account")) {
  az storage account create `
    --name $StorageAccountName `
    --resource-group $ResourceGroupName `
    --location $Location `
    --sku Standard_LRS `
    --kind StorageV2 `
    --min-tls-version TLS1_2 `
    --https-only true `
    --allow-blob-public-access false `
    --tags Project=redacta ManagedBy=bootstrap Purpose=tfstate `
    --output none
}

if ($PSCmdlet.ShouldProcess($StorageAccountName, "Enable Terraform state blob protection")) {
  az storage account blob-service-properties update `
    --account-name $StorageAccountName `
    --resource-group $ResourceGroupName `
    --enable-versioning true `
    --enable-delete-retention true `
    --delete-retention-days 30 `
    --enable-container-delete-retention true `
    --container-delete-retention-days 30 `
    --output none
}

$storageKey = az storage account keys list `
  --resource-group $ResourceGroupName `
  --account-name $StorageAccountName `
  --query "[0].value" `
  --output tsv

if ($PSCmdlet.ShouldProcess($ContainerName, "Create Terraform state container")) {
  az storage container create `
    --name $ContainerName `
    --account-name $StorageAccountName `
    --account-key $storageKey `
    --public-access off `
    --output none
}

Write-Host "Terraform backend bootstrap completed."
Write-Host "Resource group: $ResourceGroupName"
Write-Host "Storage account: $StorageAccountName"
Write-Host "Container: $ContainerName"
