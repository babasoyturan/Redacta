param(
  [ValidateSet("development", "production", "all")]
  [string] $Environment = "all",

  [string] $DashboardDirectory = (Join-Path $PSScriptRoot "..\deploy\observability\grafana")
)

$ErrorActionPreference = "Stop"

$targets = @()

if ($Environment -eq "development" -or $Environment -eq "all") {
  $targets += @{
    Name = "development"
    ResourceGroup = "rg-redacta-development"
    GrafanaName = "graf-redacta-dev-swec"
  }
}

if ($Environment -eq "production" -or $Environment -eq "all") {
  $targets += @{
    Name = "production"
    ResourceGroup = "rg-redacta-production"
    GrafanaName = "graf-redacta-prod-swec"
  }
}

$dashboards = Get-ChildItem -Path $DashboardDirectory -Filter "*.json" -File | Sort-Object Name

if ($dashboards.Count -eq 0) {
  throw "No Grafana dashboard JSON files found in $DashboardDirectory"
}

foreach ($target in $targets) {
  Write-Host "Importing Grafana dashboards into $($target.Name) Managed Grafana..."

  foreach ($dashboard in $dashboards) {
    Write-Host "  - $($dashboard.Name)"

    az grafana dashboard import `
      --resource-group $target.ResourceGroup `
      --name $target.GrafanaName `
      --definition $dashboard.FullName `
      --overwrite true `
      --only-show-errors `
      --output none

    if ($LASTEXITCODE -ne 0) {
      throw "Failed to import $($dashboard.Name) into $($target.Name) Grafana."
    }
  }
}

Write-Host "Grafana dashboard import completed."
