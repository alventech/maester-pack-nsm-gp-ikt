<#
.SYNOPSIS
Runs the NSM pack from this repository against a tenant and checks that every result follows the pack's rules.

.DESCRIPTION
Use it to verify the pack in a tenant before a release, without installing it. The script:

1. Runs Test-MtPack, the checks Install-MtPack and the Maester Packs index run, and requires a valid Low risk pack.
2. Signs in to Microsoft Graph (delegated or app-only), unless -SkipConnect is given, and lists the scopes from
   maester-pack.json that the token lacks.
3. Runs every test with Invoke-MtTest -Path, so the source in this repository runs, not an installed copy.
4. Checks every result row:
   - no test ends in Error;
   - a Passed or Failed test states its level as "NSM-vurdering: Høy grad | Moderat grad | Liten grad.";
   - a Passed or Failed test states its scope on the next line, "Gjelder: <scope>.";
   - only Høy grad passes;
   - a skipped test gives a reason;
   - every Control resolves to a requirement in the pack's framework files.
5. Writes smoke-summary.json and smoke-summary.md to -OutputFolder and exits with 1 when a check fails.

Results are about the tenant; the checks are about the pack. A tenant with poor security still passes the smoke
test, as long as every test runs and reports its level correctly.

.PARAMETER TenantId
The tenant to sign in to.

.PARAMETER ClientId
The app to sign in with. Without it, Microsoft Graph PowerShell's own app is used (delegated only).

.PARAMETER CertificateThumbprint
Signs in app-only with this certificate (needs -ClientId and -TenantId, and the scopes granted as application
permissions).

.PARAMETER SkipConnect
Uses the Microsoft Graph connection already in this session.

.PARAMETER Config
A maester-config.json to run with, for example one that lists EmergencyAccessAccounts.

.PARAMETER OutputFolder
Where to write the summary. Defaults to smoke-results/<timestamp> in the repository.

.EXAMPLE
./scripts/Invoke-NsmPackSmokeTest.ps1 -TenantId contoso.onmicrosoft.com

Signs in as an admin in the browser and runs the smoke test. There is deliberately no device-code option: device-code
sign-in is a phishing vector and is often blocked by Conditional Access.

.EXAMPLE
./scripts/Invoke-NsmPackSmokeTest.ps1 -TenantId <tenant-id> -ClientId <app-id> -CertificateThumbprint <thumbprint>

Runs the smoke test app-only.
#>
[CmdletBinding(DefaultParameterSetName = 'Delegated')]
param(
    [Parameter(ParameterSetName = 'Delegated')]
    [Parameter(ParameterSetName = 'AppOnly', Mandatory)]
    [string] $TenantId,

    [Parameter(ParameterSetName = 'Delegated')]
    [Parameter(ParameterSetName = 'AppOnly', Mandatory)]
    [string] $ClientId,

    [Parameter(ParameterSetName = 'AppOnly', Mandatory)]
    [string] $CertificateThumbprint,

    [Parameter(ParameterSetName = 'Existing', Mandatory)]
    [switch] $SkipConnect,

    [string] $Config,

    [string] $OutputFolder
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot -Parent
$pack = Join-Path $repo 'nsm-gp-ikt'
$manifest = Get-Content (Join-Path $pack 'maester-pack.json') -Raw | ConvertFrom-Json
if (-not $OutputFolder) { $OutputFolder = Join-Path $repo "smoke-results/$(Get-Date -Format yyyyMMdd-HHmmss)" }
$failures = [System.Collections.Generic.List[string]]::new()

# Reuse a Maester 3 that is already loaded (two Maester 3 builds cannot share a process).
if (-not (Get-Module Maester | Where-Object Version -GE '3.0.0')) { Import-Module Maester -MinimumVersion 3.0.0 }
$maesterVersion = "$((Get-Module Maester).Version)$(if ((Get-Module Maester).PrivateData.PSData.Prerelease) { "-$((Get-Module Maester).PrivateData.PSData.Prerelease)" })"
Write-Host "Maester $maesterVersion, pack $($manifest.Id) $($manifest.Version)" -ForegroundColor Cyan

# 1. The pack itself.
$check = Test-MtPack -Path $pack
if (-not $check.IsValid) { $failures.Add("Test-MtPack: invalid. $($check.Errors -join '; ')") }
if ($check.Risk -ne 'Low') { $failures.Add("Test-MtPack: risk $($check.Risk), expected Low. $($check.Findings -join '; ')") }
foreach ($w in $check.Warnings) { $failures.Add("Test-MtPack warning: $w") }
Write-Host "Test-MtPack: valid $($check.IsValid), risk $($check.Risk), $(@($check.TestIds).Count) tests"

# 2. Sign in and compare the token with the scopes the pack declares.
$scopes = @($manifest.Uses.GraphScopes)
switch ($PSCmdlet.ParameterSetName) {
    'AppOnly' {
        Connect-MgGraph -TenantId $TenantId -ClientId $ClientId -CertificateThumbprint $CertificateThumbprint -NoWelcome -ContextScope Process
    }
    'Delegated' {
        $connect = @{ Scopes = $scopes; NoWelcome = $true; ContextScope = 'Process' }
        if ($TenantId) { $connect.TenantId = $TenantId }
        if ($ClientId) { $connect.ClientId = $ClientId }
        Connect-MgGraph @connect
    }
}
$context = Get-MgContext
if (-not $context) { throw 'Not connected to Microsoft Graph.' }
$missing = @($scopes | Where-Object { $_ -notin $context.Scopes })
Write-Host "Signed in: $($context.AuthType) as $(if ($context.Account) { $context.Account } else { $context.AppName }), tenant $($context.TenantId)"
if ($missing) { Write-Warning "The token lacks: $($missing -join ', '). Tests that need them should skip with a reason." }

# 3. Run the source.
$run = @{ Path = $pack }
if ($Config) { $run.Config = $Config }
$rows = @(Invoke-MtTest @run)

# 4. Check every row.
$frameworks = @{}
foreach ($f in Get-ChildItem (Join-Path $pack 'tests/frameworks') -Filter *.json) {
    $fw = Get-Content $f.FullName -Raw | ConvertFrom-Json
    $frameworks[$fw.Framework] = @($fw.Requirements.Id)
}
$expected = @(Get-ChildItem (Join-Path $pack 'tests') -Filter 'Test.*.ps1').Count
if ($rows.Count -ne $expected) { $failures.Add("Ran $($rows.Count) tests, expected $expected.") }

$summary = foreach ($row in $rows) {
    $detail = $row.ResultDetail
    $text = if ($detail -is [string]) { $detail } elseif ($detail) { [string]$detail.TestResult } else { '' }
    $level = if ($text -match 'NSM-vurdering: (Høy|Moderat|Liten) grad') { $Matches[1] } else { $null }
    $problems = [System.Collections.Generic.List[string]]::new()

    switch ($row.Result) {
        'Error' { $problems.Add("error: $(@($row.ErrorRecord)[0])") }
        { $_ -in 'Passed', 'Failed' } {
            if (-not $level) { $problems.Add('no NSM-vurdering line') }
            elseif (($level -eq 'Høy') -ne ($row.Result -eq 'Passed')) { $problems.Add("$($row.Result) with level $level") }
            if ($text -notmatch '\*Gjelder: [^*]+\.\*') { $problems.Add('no scope line (Gjelder: ...)') }
        }
        'Skipped' { if (-not ($row.ReasonCode -or $row.ReasonDetail -or $text)) { $problems.Add('skipped without a reason') } }
    }
    foreach ($c in @($row.Control)) {
        $key, $id = $c -split ':', 2
        if ($frameworks.ContainsKey($key) -and $id -notin $frameworks[$key]) { $problems.Add("unknown requirement $c") }
    }
    foreach ($p in $problems) { $failures.Add("$($row.Id): $p") }

    [pscustomobject]@{
        Id      = $row.Id
        Result  = $row.Result
        Level   = $level
        Reason  = if ($row.Result -eq 'Skipped') { @($row.ReasonCode, $row.ReasonDetail) -join ' ' } else { $null }
        Control = @($row.Control | Where-Object { $_ -match '^nsm-' })
        Check   = if ($problems.Count) { $problems -join '; ' } else { 'ok' }
    }
}

# 5. Report.
New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null
$result = [ordered]@{
    Pack       = "$($manifest.Id) $($manifest.Version)"
    Maester    = $maesterVersion
    RunAt      = (Get-Date).ToString('o')
    TenantId   = $context.TenantId
    AuthType   = "$($context.AuthType)"
    MissingScopes = $missing
    TestMtPack = [ordered]@{ IsValid = $check.IsValid; Risk = "$($check.Risk)"; Digest = $check.Digest }
    Counts     = [ordered]@{
        Passed  = @($summary | Where-Object Result -EQ 'Passed').Count
        Failed  = @($summary | Where-Object Result -EQ 'Failed').Count
        Skipped = @($summary | Where-Object Result -EQ 'Skipped').Count
        Error   = @($summary | Where-Object Result -EQ 'Error').Count
    }
    SmokeTest  = if ($failures.Count) { 'Failed' } else { 'Passed' }
    Failures   = $failures
    Tests      = $summary
}
$result | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $OutputFolder 'smoke-summary.json') -Encoding utf8

$md = @(
    "# Smoke test: $($result.Pack)"
    ''
    "Maester $($result.Maester), $($result.AuthType), $($result.RunAt). Smoke test: **$($result.SmokeTest)**."
    ''
    '| Test | Result | Level | NSM | Check |'
    '| --- | --- | --- | --- | --- |'
    $summary | ForEach-Object { "| $($_.Id) | $($_.Result) | $($_.Level) | $($_.Control -join ', ') | $(if ($_.Reason) { "$($_.Check). Skipped: $($_.Reason)" } else { $_.Check }) |" }
)
if ($missing) { $md += '', "Scopes the token lacked: $($missing -join ', ')." }
$md | Set-Content (Join-Path $OutputFolder 'smoke-summary.md') -Encoding utf8

$summary | Format-Table Id, Result, Level, Check -AutoSize | Out-String -Width 200 | Write-Host
Write-Host "Summary: $OutputFolder" -ForegroundColor Cyan
if ($failures.Count) {
    $failures | ForEach-Object { Write-Host "  ✗ $_" -ForegroundColor Red }
    Write-Host "Smoke test failed: $($failures.Count) problems." -ForegroundColor Red
    exit 1
}
Write-Host 'Smoke test passed: every test ran and reported its level by the pack''s rules.' -ForegroundColor Green
