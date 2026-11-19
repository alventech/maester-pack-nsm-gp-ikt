<#
Unit tests for the Maester 2 build: tools/build_maester2.py and maester2/NsmMaester2.ps1, without a tenant.

Run from the repository root, in a PowerShell process where Maester 3 is not loaded:
  python3 tools/build_maester2.py
  Invoke-Pester ./unit-tests-maester2 -Output Detailed
Needs Maester 2.3.0 and Pester 5.7. The results and levels in a tenant are checked by running the build against
a tenant (docs/maester-comparison.md).
#>

BeforeAll {
    Import-Module Maester -RequiredVersion 2.3.0
    $script:Root = Join-Path $PSScriptRoot '..'
    $script:Build = Join-Path $Root 'dist/NSM'
    . (Join-Path $Root 'maester2/NsmMaester2.ps1')

    function New-Tenant {
        param([string[]] $PlanNames = @(), [string[]] $PlanIds = @(), [string[]] $SkuIds = @())
        [pscustomobject]@{ PlanNames = $PlanNames; PlanIds = $PlanIds; SkuIds = $SkuIds }
    }
}

Describe 'The build' {
    It 'has one Pester file per test, named by the test ID' {
        $tests = Get-ChildItem (Join-Path $Root 'nsm-gp-ikt/tests') -Filter 'Test.MP.NSM.*.ps1'
        $wrappers = Get-ChildItem $Build -Filter 'MP.NSM.*.Tests.ps1'
        @($wrappers.Name | Sort-Object) | Should -Be @($tests.Name -replace '^Test\.(.+)\.ps1$', '$1.Tests.ps1' | Sort-Object)
    }

    It 'has removed the MaesterTest attribute, which Maester 2 cannot invoke' {
        Get-ChildItem (Join-Path $Build 'tests') -Filter '*.ps1' | Select-String -SimpleMatch '[MaesterTest(' | Should -BeNullOrEmpty
    }

    It 'calls a function each test file defines, and loads in Maester 2' {
        foreach ($wrapper in Get-ChildItem $Build -Filter 'MP.NSM.*.Tests.ps1') {
            $name = [regex]::Match((Get-Content $wrapper.FullName -Raw), "-Name '([^']+)'").Groups[1].Value
            $source = Join-Path $Build "tests/Test.$($wrapper.Name -replace '\.Tests\.ps1$', '.ps1')"
            . $source
            Get-Command -Name $name -CommandType Function | Should -Not -BeNullOrEmpty -Because $wrapper.Name
        }
    }
}

Describe 'Get-MtSetting' {
    BeforeAll { $script:Saved = & (Get-Module Maester) { $__MtSession.MaesterConfig } }
    AfterAll { & (Get-Module Maester) { param($c) $__MtSession.MaesterConfig = $c } $Saved }

    It 'reads GlobalSettings from the run config' {
        & (Get-Module Maester) { $__MtSession.MaesterConfig = [pscustomobject]@{ GlobalSettings = [pscustomobject]@{ 'NsmGpIkt.MinimumWindowsBuild' = 22631 } } }
        Get-MtSetting -Name 'NsmGpIkt.MinimumWindowsBuild' -Default 26100 | Should -Be 22631
    }

    It 'returns the default when the config does not set it, or there is no config' {
        & (Get-Module Maester) { $__MtSession.MaesterConfig = [pscustomobject]@{ GlobalSettings = [pscustomobject]@{} } }
        Get-MtSetting -Name 'NsmGpIkt.MinimumWindowsBuild' -Default 26100 | Should -Be 26100
        & (Get-Module Maester) { $__MtSession.MaesterConfig = $null }
        Get-MtSetting -Name 'EmergencyAccessAccounts' -Default 'none' | Should -Be 'none'
    }
}

Describe 'Get-MtNsmLicenseSkip' {
    It 'skips nothing when the test needs no licence, or the licences could not be read' {
        Get-MtNsmLicenseSkip -License @() -Tenant (New-Tenant) | Should -BeNullOrEmpty
        Get-MtNsmLicenseSkip -License 'INTUNE_A' -Tenant $null | Should -BeNullOrEmpty
    }

    It 'accepts a service plan ID from the table: Entra ID P2 meets AAD_PREMIUM' {
        Get-MtNsmLicenseSkip -License 'AAD_PREMIUM' -Tenant (New-Tenant -PlanIds 'eec0eb4f-6444-4f95-aba0-50c24d67f998') | Should -BeNullOrEmpty
    }

    It 'accepts a SKU ID from the table' {
        Get-MtNsmLicenseSkip -License 'THREAT_INTELLIGENCE' -Tenant (New-Tenant -SkuIds '900018f1-0cdb-4ecb-94d4-90281760fdc6') | Should -BeNullOrEmpty
    }

    It 'accepts a service plan name for a token the table does not have' {
        Get-MtNsmLicenseSkip -License 'ATA' -Tenant (New-Tenant -PlanNames 'ATA') | Should -BeNullOrEmpty
    }

    It 'accepts any one element of the list' {
        Get-MtNsmLicenseSkip -License 'AAD_PREMIUM_P2', 'Entra_Identity_Governance' -Tenant (New-Tenant -PlanIds 'e866a266-3cff-43a3-acca-0c90a7e00c8b') | Should -BeNullOrEmpty
    }

    It 'needs every licence of an element joined with &' {
        $tenant = New-Tenant -PlanNames 'ATA'
        (Get-MtNsmLicenseSkip -License 'ATA&INTUNE_A' -Tenant $tenant).SkippedBecause | Should -Be 'NotLicensedIntune'
    }

    It 'skips with Maester 2 reason <reason> when the tenant lacks <license>' -ForEach @(
        @{ License = @('AAD_PREMIUM'); Reason = 'NotLicensedEntraIDP1' }
        @{ License = @('AAD_PREMIUM_P2', 'Entra_Identity_Governance'); Reason = 'NotLicensedEntraIDP2OrGovernance' }
        @{ License = @('INTUNE_A'); Reason = 'NotLicensedIntune' }
        @{ License = @('THREAT_INTELLIGENCE'); Reason = 'NotLicensedMdoP2' }
    ) {
        (Get-MtNsmLicenseSkip -License $License -Tenant (New-Tenant -PlanNames 'EXCHANGE_S_STANDARD')).SkippedBecause | Should -Be $Reason
    }

    It 'names a licence Maester 2 has no reason for' {
        $skip = Get-MtNsmLicenseSkip -License 'ATA' -Tenant (New-Tenant)
        $skip.SkippedBecause | Should -Be 'Custom'
        $skip.SkippedCustomReason | Should -BeLike '*Microsoft Defender for Identity (ATA)*'
    }

    It 'every licence the tests name is in the table or is ATA' {
        $named = Get-ChildItem (Join-Path $Root 'nsm-gp-ikt/tests') -Filter 'Test.MP.NSM.*.ps1' |
            Select-String -Pattern "^\s*License\s*=\s*(.+?),?$" | ForEach-Object { [regex]::Matches($_.Matches[0].Groups[1].Value, "'([^']+)'").Groups } |
            Where-Object Name -EQ 1 | ForEach-Object Value | Sort-Object -Unique
        $known = @((Get-MtNsmLicenseTable).Keys) + 'ATA'
        $named | Where-Object { $_ -notin $known } | Should -BeNullOrEmpty
    }

    It 'has the same service plan and SKU IDs as Maester 3''s licence table' {
        $m3 = Get-Module -ListAvailable Maester | Where-Object { $_.Version.Major -ge 3 } | Select-Object -First 1
        if (-not $m3) { Set-ItResult -Skipped -Because 'Maester 3 is not installed'; return }
        $table = (Import-PowerShellDataFile (Join-Path $m3.ModuleBase 'assets/MaesterLicenseTable.psd1')).Tokens
        foreach ($entry in (Get-MtNsmLicenseTable).GetEnumerator()) {
            @($entry.Value.Plans | Sort-Object) | Should -Be @($table[$entry.Key].ServicePlanIds | Sort-Object) -Because $entry.Key
            @($entry.Value.Skus | Where-Object { $_ } | Sort-Object) | Should -Be @($table[$entry.Key].SkuIds | Where-Object { $_ } | Sort-Object) -Because $entry.Key
        }
    }
}
