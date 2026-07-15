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
    PrometheusDatasourceUid = "amw-redacta-dev-swec"
  }
}

if ($Environment -eq "production" -or $Environment -eq "all") {
  $targets += @{
    Name = "production"
    ResourceGroup = "rg-redacta-production"
    GrafanaName = "graf-redacta-prod-swec"
    PrometheusDatasourceUid = "amw-redacta-prod-swec"
  }
}

$dashboards = Get-ChildItem -Path $DashboardDirectory -Filter "*.json" -File | Sort-Object Name

if ($dashboards.Count -eq 0) {
  throw "No Grafana dashboard JSON files found in $DashboardDirectory"
}

function Set-PrometheusDatasource {
  param(
    [object] $Node,

    [Parameter(Mandatory = $true)]
    [object] $Datasource
  )

  if ($null -eq $Node) {
    return
  }

  if ($Node -is [System.Array]) {
    foreach ($item in $Node) {
      Set-PrometheusDatasource -Node $item -Datasource $Datasource
    }

    return
  }

  if ($Node -isnot [pscustomobject]) {
    return
  }

  $propertyNames = @($Node.PSObject.Properties.Name)

  if ($propertyNames -contains "targets") {
    $Node | Add-Member -MemberType NoteProperty -Name datasource -Value $Datasource -Force

    foreach ($target in $Node.targets) {
      if ($target -is [pscustomobject]) {
        $target | Add-Member -MemberType NoteProperty -Name datasource -Value $Datasource -Force
      }
    }
  }

  foreach ($property in $Node.PSObject.Properties) {
    Set-PrometheusDatasource -Node $property.Value -Datasource $Datasource
  }
}

foreach ($target in $targets) {
  Write-Host "Importing Grafana dashboards into $($target.Name) Managed Grafana..."

  foreach ($dashboard in $dashboards) {
    Write-Host "  - $($dashboard.Name)"

    $prometheusDatasource = @{
      type = "prometheus"
      uid = $target.PrometheusDatasourceUid
    }

    $dashboardModel = Get-Content -Path $dashboard.FullName -Raw | ConvertFrom-Json
    Set-PrometheusDatasource -Node $dashboardModel -Datasource $prometheusDatasource

    $preparedDashboardPath = Join-Path `
      ([System.IO.Path]::GetTempPath()) `
      ("redacta-$($target.Name)-$($dashboard.BaseName)-dashboard.json")

    $dashboardModel |
      ConvertTo-Json -Depth 100 |
      Set-Content -Path $preparedDashboardPath -Encoding UTF8

    az grafana dashboard import `
      --resource-group $target.ResourceGroup `
      --name $target.GrafanaName `
      --definition $preparedDashboardPath `
      --overwrite true `
      --only-show-errors `
      --output none

    if ($LASTEXITCODE -ne 0) {
      throw "Failed to import $($dashboard.Name) into $($target.Name) Grafana."
    }
  }
}

Write-Host "Grafana dashboard import completed."
