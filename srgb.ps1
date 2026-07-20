<#
.SYNOPSIS
    Call a SignalRGB MCP tool from the command line.

.DESCRIPTION
    Spawns SignalRGB's MCP server (newest installed version), performs the
    MCP initialize handshake, invokes one tool, prints the raw JSON-RPC
    response, and exits. Useful for scripting SignalRGB without an MCP client.

    SignalRGB must be running with "Enable Model Context Protocol" turned on
    (Settings > AI Integration; requires an app restart after toggling).

.EXAMPLE
    .\srgb.ps1 -Tool read_status
    .\srgb.ps1 -Tool effect_apply -ArgsJson '{"name":"Screen Ambience"}'
    .\srgb.ps1 -Tool effect_setproperties -ArgsJson '{"picture_mode":"Vivid","saturation":40}'
#>
param(
    [Parameter(Mandatory=$true)][string]$Tool,
    [string]$ArgsJson = '{}'
)

$base = Join-Path $env:LOCALAPPDATA 'VortxEngine'
$exe = Get-ChildItem -Path $base -Directory -Filter 'app-*' -ErrorAction Stop |
    Sort-Object LastWriteTime -Descending |
    ForEach-Object { Join-Path $_.FullName 'Signal-x64\SignalRgbMcp.exe' } |
    Where-Object { Test-Path $_ } |
    Select-Object -First 1
if (-not $exe) { throw "SignalRgbMcp.exe not found under $base — is SignalRGB installed?" }

$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = $exe
$psi.UseShellExecute = $false
$psi.RedirectStandardInput = $true
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError = $true
$proc = [System.Diagnostics.Process]::Start($psi)
try {
    $proc.StandardInput.WriteLine('{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"srgb-cli","version":"1.0"}}}')
    $proc.StandardInput.Flush()
    $null = $proc.StandardOutput.ReadLine()
    $proc.StandardInput.WriteLine('{"jsonrpc":"2.0","method":"notifications/initialized"}')
    $call = @{ jsonrpc = '2.0'; id = 2; method = 'tools/call'; params = @{ name = $Tool; arguments = ($ArgsJson | ConvertFrom-Json) } } | ConvertTo-Json -Depth 10 -Compress
    $proc.StandardInput.WriteLine($call)
    $proc.StandardInput.Flush()
    do { $line = $proc.StandardOutput.ReadLine() } while ($line -ne $null -and $line -notmatch '"id":2')
    $line
} finally {
    $proc.Kill()
}
