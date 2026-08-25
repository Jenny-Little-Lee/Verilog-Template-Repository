param(
    [string]$RootDir = "."
)

$matches = Get-ChildItem -Path $RootDir -Directory -Recurse -Filter "modelsim" |
    Where-Object { $_.FullName -match "\\\.sim\\sim_1\\behav\\modelsim$" } |
    Sort-Object LastWriteTime -Descending

if (-not $matches) {
    Write-Error "No ModelSim run directory found under $RootDir"
    exit 1
}

$matches | Select-Object FullName, LastWriteTime
