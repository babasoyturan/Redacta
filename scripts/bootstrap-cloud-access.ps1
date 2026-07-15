[CmdletBinding(SupportsShouldProcess = $true)]
param(
  [string]$Location = "swedencentral",

  [string]$SharedResourceGroupName = "rg-redacta-shared",

  [string]$SharedTerraformIdentityName = "id-redacta-github-terraform-shared-swec",

  [string[]]$EnvironmentResourceGroupNames = @(
    "rg-redacta-development",
    "rg-redacta-production"
  )
)

$ErrorActionPreference = "Stop"

if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
  throw "Azure CLI is required to bootstrap Redacta cloud access."
}

$accountId = az account show --query id --output tsv
if ([string]::IsNullOrWhiteSpace($accountId)) {
  throw "Azure CLI is not logged in. Run 'az login' first."
}

$sharedPrincipalId = az identity show `
  --resource-group $SharedResourceGroupName `
  --name $SharedTerraformIdentityName `
  --query principalId `
  --output tsv

if ([string]::IsNullOrWhiteSpace($sharedPrincipalId)) {
  throw "Could not find shared Terraform identity '$SharedTerraformIdentityName' in '$SharedResourceGroupName'."
}

foreach ($resourceGroupName in $EnvironmentResourceGroupNames) {
  $exists = az group exists --name $resourceGroupName

  if ($exists -eq "false") {
    if ($PSCmdlet.ShouldProcess($resourceGroupName, "Create environment resource group")) {
      az group create `
        --name $resourceGroupName `
        --location $Location `
        --tags Project=redacta ManagedBy=terraform Stack=shared `
        --output none
    }
  }

  $scope = az group show --name $resourceGroupName --query id --output tsv

  foreach ($roleName in @("Contributor", "User Access Administrator")) {
    $assignment = az role assignment list `
      --assignee $sharedPrincipalId `
      --scope $scope `
      --role $roleName `
      --query "[0].id" `
      --output tsv

    if ([string]::IsNullOrWhiteSpace($assignment)) {
      if ($PSCmdlet.ShouldProcess("$SharedTerraformIdentityName on $resourceGroupName", "Grant $roleName")) {
        az role assignment create `
          --assignee-object-id $sharedPrincipalId `
          --assignee-principal-type ServicePrincipal `
          --role $roleName `
          --scope $scope `
          --output none
      }
    }
  }
}

Write-Host "Redacta cloud access bootstrap completed."
Write-Host "Subscription: $accountId"
Write-Host "Shared Terraform identity: $SharedTerraformIdentityName"
Write-Host "Environment resource groups: $($EnvironmentResourceGroupNames -join ', ')"
