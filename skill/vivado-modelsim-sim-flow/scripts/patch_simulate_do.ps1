param(
    [Parameter(Mandatory = $true)]
    [string]$DoFile,

    [Parameter(Mandatory = $true)]
    [string]$TbName,

    [string]$WlfPath
)

if (-not (Test-Path $DoFile)) {
    Write-Error "simulate.do file not found: $DoFile"
    exit 1
}

$content = Get-Content -Encoding UTF8 $DoFile -Raw

$content = $content -replace 'run\s+1000ns', 'run -all'

if ([string]::IsNullOrWhiteSpace($WlfPath)) {
    $WlfPath = "../../../../../testbench/$TbName/runs/latest/waves/$TbName.wlf"
}

if ($content -notmatch '-wlf') {
    $content = $content -replace 'vsim\s+', "vsim -wlf $WlfPath "
} else {
    $content = $content -replace '-wlf\s+\S+', "-wlf $WlfPath"
}

# 不在本脚本中加入强制退出逻辑；只保证 run -all 和 -wlf 设置正确
Set-Content -Path $DoFile -Value $content -Encoding UTF8
Write-Output "Patched $DoFile"
