<#
Runs the NSM pack's tests on Maester 2.x, as custom tests. Dot-sourced by every generated *.Tests.ps1 file.

Maester 3 does three things for a pack that Maester 2 does not: it gives tests Get-MtSetting, it skips a test
when the tenant lacks the licence in its [MaesterTest(License = ...)] attribute, and it shows the test's
documentation (Test.MP.NSM.<n>.md). This file does the same for Maester 2. tools/build_maester2.py removes the
attribute from the copied tests, since Maester 2 cannot invoke a function that carries it, and writes its values
into each test's Pester wrapper.
#>

# The Maester that runs the tests. Get-Command would auto-load another installed Maester (a 3.0 preview has
# Get-MtSetting), and results written to that module's session never reach the report.
$maester = @(Get-Module -Name Maester)[0]
if (-not $maester) { throw 'Maester is not loaded. Run the tests with Invoke-Maester.' }

if (-not $maester.ExportedCommands.ContainsKey('Get-MtSetting')) {
    function Get-MtSetting {
        <#
        .SYNOPSIS
        Returns a setting from GlobalSettings in the run's maester-config.json, else the -Default value.
        Maester 3 has this command; Maester 2 keeps the config in its session but has no command for it.
        #>
        [CmdletBinding()]
        param(
            [Parameter(Mandatory, Position = 0)] [string] $Name,
            [Parameter()] [AllowNull()] [object] $Default
        )

        $config = & (@(Get-Module -Name Maester)[0]) { $__MtSession.MaesterConfig }
        $global = if ($config -and $config.PSObject.Properties['GlobalSettings']) { $config.GlobalSettings }
        if ($global -and $global.PSObject.Properties[$Name]) { return $global.$Name }
        $Default
    }
}

# Licence tokens as in Maester 3's assets/MaesterLicenseTable.psd1 (3.0.0-rc83): a token is met by any of its
# service plan IDs or SKU IDs, or by a service plan of that name. Skip is the Maester 2 skip reason.
function Get-MtNsmLicenseTable {
    @{
    AAD_PREMIUM               = @{ Plans = 'e866a266-3cff-43a3-acca-0c90a7e00c8b', '41781fb2-bc02-4b7c-bd55-b576c07bb09d', 'eec0eb4f-6444-4f95-aba0-50c24d67f998'; Skip = 'NotLicensedEntraIDP1' }
    AAD_PREMIUM_P2            = @{ Plans = 'eec0eb4f-6444-4f95-aba0-50c24d67f998'; Skip = 'NotLicensedEntraIDP2' }
    Entra_Identity_Governance = @{ Plans = 'e866a266-3cff-43a3-acca-0c90a7e00c8b'; Skip = 'NotLicensedEntraIDGovernance' }
    INTUNE_A                  = @{ Plans = 'c1ec4a95-1f05-45b3-a911-aa3fa01094f5', 'd216f254-796f-4dab-bbfa-710686e646b9', '3e170737-c728-4eae-bbb9-3f3360f7184c', 'da24caf9-af8e-485c-b7c8-e73336da2693', '2b317a4a-77a6-4188-9437-b68a77b4e2c6', '2c21e77a-e0d6-4570-b38a-7ff2dc17d2ca', 'b4288abe-01be-47d9-ad20-311d6e83fc24', 'e6025b08-2fa5-4313-bd0a-7e5ffca32958'; Skip = 'NotLicensedIntune' }
    THREAT_INTELLIGENCE       = @{ Plans = '8e0c0a52-6a6c-4d40-8370-dd62790dcd70', '900018f1-0cdb-4ecb-94d4-90281760fdc6'; Skus = '8e0c0a52-6a6c-4d40-8370-dd62790dcd70', '900018f1-0cdb-4ecb-94d4-90281760fdc6'; Skip = 'NotLicensedMdoP2' }
    }
}

function Get-MtNsmTenantLicense {
    <#
    .SYNOPSIS
    Returns the service plan names and IDs and the SKU IDs of the tenant's enabled subscriptions, once per run.
    $null when Graph cannot be read; then no test is skipped for a licence, as in Maester 3.
    #>
    [CmdletBinding()]
    param()

    if ($global:MtNsmTenantLicense -and $global:MtNsmTenantLicense.TenantId -eq (Get-MgContext).TenantId) {
        return $global:MtNsmTenantLicense.Value
    }
    $value = try {
        $skus = @(Invoke-MtGraphRequest -RelativeUri 'subscribedSkus' -ApiVersion v1.0 -ErrorAction Stop | Where-Object capabilityStatus -EQ 'Enabled')
        $plans = @($skus | ForEach-Object { $_.servicePlans })
        [pscustomobject]@{
            PlanNames = @($plans.servicePlanName | Where-Object { $_ } | Sort-Object -Unique)
            PlanIds   = @($plans.servicePlanId | Where-Object { $_ } | Sort-Object -Unique)
            SkuIds    = @($skus.skuId | Where-Object { $_ } | Sort-Object -Unique)
        }
    } catch {
        Write-Verbose "Could not read the tenant's licences: $($_.Exception.Message)"
        $null
    }
    $global:MtNsmTenantLicense = @{ TenantId = (Get-MgContext).TenantId; Value = $value }
    $value
}

function Get-MtNsmLicenseSkip {
    <#
    .SYNOPSIS
    Returns $null when the tenant meets a test's License list (any one element; 'A&B' needs both), else the
    Maester 2 skip reason and, for a licence Maester 2 has no reason for, the text to show.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [AllowEmptyCollection()] [string[]] $License,
        [Parameter()] [AllowNull()] [object] $Tenant
    )

    if ($License.Count -eq 0 -or -not $Tenant) { return $null }
    $table = Get-MtNsmLicenseTable
    $missingFirst = $null
    foreach ($element in $License) {
        $missing = @(foreach ($token in @($element -split '&' | ForEach-Object Trim | Where-Object { $_ })) {
                $entry = $table[$token]
                $has = ($Tenant.PlanNames -contains $token) -or
                    ($entry -and ((@($entry.Plans) | Where-Object { $_ -in $Tenant.PlanIds }) -or (@($entry.Skus) | Where-Object { $_ -in $Tenant.SkuIds })))
                if (-not $has) { $token }
            })
        if ($missing.Count -eq 0) { return $null }
        if (-not $missingFirst) { $missingFirst = $missing[0] }
    }
    $tokens = @($License | ForEach-Object { $_ -split '&' } | ForEach-Object Trim)
    if (($tokens | Sort-Object) -join ',' -eq 'AAD_PREMIUM_P2,Entra_Identity_Governance') {
        return @{ SkippedBecause = 'NotLicensedEntraIDP2OrGovernance' }
    }
    $entry = $table[$missingFirst]
    if ($entry) { return @{ SkippedBecause = $entry.Skip } }
    $names = @{ ATA = 'Microsoft Defender for Identity' }
    $name = if ($names.ContainsKey($missingFirst)) { "$($names[$missingFirst]) ($missingFirst)" } else { $missingFirst }
    @{ SkippedBecause = 'Custom'; SkippedCustomReason = "This test requires $name. The tenant does not have it." }
}

function Add-MtTestResultDetail {
    <#
    .SYNOPSIS
    Passes every call on to Maester's Add-MtTestResultDetail, adding the running test's documentation and
    severity. Maester 2 finds the documentation only next to the function that calls it, and the pack writes
    its results from a helper (Complete-MtNsmResult), so without this the report would show no description.
    #>
    [CmdletBinding()]
    param(
        [string] $Description,
        [string] $Result,
        [object[]] $GraphObjects,
        [string] $GraphObjectType,
        [string] $TestName,
        [string] $TestTitle,
        [string] $SkippedBecause,
        [string] $SkippedCustomReason,
        [switch] $Investigate,
        $SkippedError,
        [string] $Severity
    )

    $test = $global:MtNsmCurrentTest
    if ($test -and -not $PSBoundParameters.ContainsKey('Description')) {
        $parts = (Get-Content -LiteralPath $test.Markdown -Raw) -split '<!--- Results --->', 2
        $PSBoundParameters['Description'] = $parts[0]
        $template = if ($parts.Count -gt 1) { $parts[1].Trim() } else { '%TestResult%' }
        $text = if ($PSBoundParameters.ContainsKey('Result')) { $Result } elseif ($SkippedBecause) { $null } else { '' }
        if ($null -ne $text -and $template -match '%TestResult%') { $PSBoundParameters['Result'] = $template.Replace('%TestResult%', $text) }
    }
    if ($test -and -not $PSBoundParameters.ContainsKey('Severity')) { $PSBoundParameters['Severity'] = $test.Severity }
    $command = @(Get-Module -Name Maester)[0].ExportedCommands['Add-MtTestResultDetail']
    & $command @PSBoundParameters
}

function Invoke-MtNsmTest {
    <#
    .SYNOPSIS
    Runs one of the pack's test functions inside a Pester It block: skips it when the tenant lacks its licence,
    and returns $true, $false or $null (skipped), as Maester 3 would read it.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string] $Name,
        [Parameter(Mandatory)] [string] $Markdown,
        [Parameter()] [AllowEmptyCollection()] [string[]] $License = @(),
        [Parameter()] [string] $Severity
    )

    $global:MtNsmCurrentTest = @{ Name = $Name; Markdown = $Markdown; Severity = $Severity }
    try {
        $skip = Get-MtNsmLicenseSkip -License $License -Tenant (Get-MtNsmTenantLicense)
        if ($skip) { Add-MtTestResultDetail @skip; return $null }
        & $Name
    } finally {
        $global:MtNsmCurrentTest = $null
    }
}
