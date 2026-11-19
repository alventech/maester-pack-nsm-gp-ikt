<#
Unit tests for the NSM pack: every test and helper runs against fake Graph responses, without a tenant.

Run from the repository root:  Invoke-Pester ./unit-tests -Output Detailed
Needs Maester 3.0 (for the MaesterTest attribute) and Pester 5.7 or later.

Each test function is called directly. Invoke-MtGraphRequest, Get-MtConditionalAccessPolicy, Get-MtSetting and
Add-MtTestResultDetail are mocked: Graph answers come from $script:Graph, an ordered table of URI patterns, and
the level or skip the test reports is read back from what it passed to Add-MtTestResultDetail.
#>

BeforeAll {
    # Reuse a Maester 3 that is already loaded, so the tests run against the version the caller chose
    # (Import-Module <path>/Maester.psd1 before Invoke-Pester). Two Maester 3 builds cannot share a process.
    if (-not (Get-Module Maester | Where-Object Version -GE '3.0.0')) { Import-Module Maester -MinimumVersion 3.0.0 }
    $pack = Join-Path $PSScriptRoot '../nsm-gp-ikt'
    . (Join-Path $pack 'helpers/NsmHelpers.ps1')

    # Test function by test number, read from each file's MaesterTest attribute.
    $script:Fn = @{}
    foreach ($file in Get-ChildItem (Join-Path $pack 'tests') -Filter 'Test.MP.NSM.*.ps1') {
        . $file.FullName
        $text = Get-Content $file.FullName -Raw
        $id = [regex]::Match($text, "Id = 'MP\.NSM\.(\d+)'").Groups[1].Value
        $script:Fn[$id] = [regex]::Match($text, 'function (\S+)').Groups[1].Value
    }

    function New-GraphError {
        # An error like the one Invoke-MtGraphRequest throws for an HTTP status.
        param([int] $Status, [string] $Message = 'Graph error')
        $response = [System.Net.Http.HttpResponseMessage]::new([System.Net.HttpStatusCode]$Status)
        $exception = [Microsoft.PowerShell.Commands.HttpResponseException]::new($Message, $response)
        [System.Management.Automation.ErrorRecord]::new($exception, 'GraphError', 'InvalidOperation', $null)
    }

    function Invoke-NsmTest {
        # Runs one pack test and returns what it reported.
        param([string] $Id)
        $script:Detail = $null
        $returned = & $script:Fn[$Id]
        $text = [string]$script:Detail.Result
        [pscustomobject]@{
            Returned = $returned
            Level    = if ($text -match 'NSM-vurdering: (Høy|Moderat|Liten) grad') { $Matches[1] } else { $null }
            Skipped  = $script:Detail.SkippedBecause
            Text     = $text
        }
    }

    function New-CaPolicy {
        # A Conditional Access policy for all users and all apps, changed by the hashtable.
        param([hashtable] $Grant = @{ operator = 'OR'; builtInControls = @('mfa') }, [hashtable] $Users = @{}, [hashtable] $Conditions = @{}, [string] $State = 'enabled', [string] $Name = 'CA')
        $u = @{ includeUsers = @('All'); excludeUsers = @(); excludeGroups = @(); excludeRoles = @() }
        foreach ($k in $Users.Keys) { $u[$k] = $Users[$k] }
        $c = @{ users = [pscustomobject]$u; applications = [pscustomobject]@{ includeApplications = @('All'); excludeApplications = @() }; clientAppTypes = @('all') }
        foreach ($k in $Conditions.Keys) { $c[$k] = $Conditions[$k] }
        [pscustomobject]@{ displayName = $Name; state = $State; conditions = [pscustomobject]$c; grantControls = [pscustomobject]$Grant }
    }
}

Describe 'NSM pack' {
    BeforeEach {
        $script:Graph = [ordered]@{}
        $script:Settings = @{}
        $script:Ca = @()
        Mock Invoke-MtGraphRequest {
            foreach ($pattern in $script:Graph.Keys) {
                if ($RelativeUri -match $pattern) {
                    $answer = $script:Graph[$pattern]
                    if ($answer -is [System.Management.Automation.ErrorRecord]) { throw $answer }
                    return $answer
                }
            }
            throw "Unexpected Graph call in a unit test: $RelativeUri"
        }
        Mock Get-MtSetting { if ($script:Settings.ContainsKey($Name)) { $script:Settings[$Name] } else { $Default } }
        Mock Get-MtConditionalAccessPolicy { $script:Ca }
        Mock Add-MtTestResultDetail { $script:Detail = [pscustomobject]@{ Result = $Result; SkippedBecause = $SkippedBecause } }
    }

    Describe 'Helpers' {
        It 'writes a markdown table with the header and the separator on their own lines' {
            $table = ConvertTo-MtNsmTable -InputObject @([pscustomobject]@{ A = 'x|y'; B = 1 }) -Property A, B
            $table -split "`n" | Should -Be @('| A | B |', '| --- | --- |', '| x\|y | 1 |')
        }

        It 'escapes markdown in values, so tenant data cannot add links or HTML' {
            $row = [pscustomobject]@{ A = '[click](https://evil.example) <b>x</b> *y* _z_'; B = 'a`b|c' }
            $table = ConvertTo-MtNsmTable -InputObject @($row) -Property A, B -Code B
            ($table -split "`n")[2] | Should -Be ('| \[click\](https://evil.example) \<b\>x\</b\> \*y\* \_z\_ | ' + '`a''b\|c`' + ' |')
        }

        It 'rounds percentages down, so 99.5 % never reads as 100 %' {
            Format-MtNsmPercent 0.995 | Should -Be '99 %'
        }

        It 'writes a count in singular for one and plural otherwise' {
            Format-MtNsmCount 1 policy policyer | Should -Be '1 policy'
            Format-MtNsmCount 0 policy policyer | Should -Be '0 policyer'
            Format-MtNsmCount 2 policy policyer | Should -Be '2 policyer'
        }

        It 'recognises 401 and 403 as access denied, and nothing else' {
            Test-MtNsmAccessDenied (New-GraphError 403) | Should -BeTrue
            Test-MtNsmAccessDenied (New-GraphError 401) | Should -BeTrue
            Test-MtNsmAccessDenied (New-GraphError 500) | Should -BeFalse
            Test-MtNsmAccessDenied ([System.Management.Automation.ErrorRecord]::new([System.Exception]::new('x'), 'x', 'InvalidOperation', $null)) | Should -BeFalse
        }

        It 'requires MFA only when no other control can satisfy the policy' {
            Test-MtNsmCaRequiresMfa (New-CaPolicy -Grant @{ operator = 'OR'; builtInControls = @('mfa') }) | Should -BeTrue
            Test-MtNsmCaRequiresMfa (New-CaPolicy -Grant @{ operator = 'OR'; builtInControls = @('mfa', 'compliantDevice') }) | Should -BeFalse
            Test-MtNsmCaRequiresMfa (New-CaPolicy -Grant @{ operator = 'AND'; builtInControls = @('mfa', 'compliantDevice') }) | Should -BeTrue
            Test-MtNsmCaRequiresMfa (New-CaPolicy -Grant @{ operator = 'OR'; builtInControls = @('compliantDevice') }) | Should -BeFalse
        }

        It 'counts only the given authentication strengths with -StrengthId' {
            $pr = New-CaPolicy -Grant @{ operator = 'OR'; builtInControls = @(); authenticationStrength = [pscustomobject]@{ id = 'pr' } }
            Test-MtNsmCaRequiresMfa $pr -StrengthId 'pr' | Should -BeTrue
            Test-MtNsmCaRequiresMfa $pr -StrengthId 'other' | Should -BeFalse
            Test-MtNsmCaRequiresMfa (New-CaPolicy) -StrengthId 'pr' | Should -BeFalse
        }

        It 'counts excluded users, groups, roles, guests and apps as exceptions, but not emergency access accounts' {
            $p = New-CaPolicy -Users @{ excludeUsers = @('bg1', 'u1'); excludeGroups = @('g1'); excludeRoles = @('r1'); excludeGuestsOrExternalUsers = [pscustomobject]@{ guestOrExternalUserTypes = 'b2bCollaborationGuest' } }
            $p.conditions.applications.excludeApplications = @('app1')
            (Get-MtNsmCaScope -Policy $p -Excluded 'bg1').Exceptions | Should -Be 5
        }

        It 'names the conditions that narrow a policy' {
            $p = New-CaPolicy -Conditions @{ locations = [pscustomobject]@{ includeLocations = @('All'); excludeLocations = @('trusted') }; signInRiskLevels = @('high') }
            (Get-MtNsmCaScope -Policy $p).Narrowing | Should -Be @('locations', 'risk')
            (Get-MtNsmCaScope -Policy (New-CaPolicy)).Narrowing | Should -BeNullOrEmpty
        }

        It 'does not count an assignment to exclusion groups only' {
            Test-MtNsmAssigned @([pscustomobject]@{ target = [pscustomobject]@{ '@odata.type' = '#microsoft.graph.exclusionGroupAssignmentTarget' } }) | Should -BeFalse
            Test-MtNsmAssigned @([pscustomobject]@{ target = [pscustomobject]@{ '@odata.type' = '#microsoft.graph.groupAssignmentTarget' } }) | Should -BeTrue
            Test-MtNsmAssigned @() | Should -BeFalse
        }

        It 'looks up emergency access accounts given by user principal name, and the members of groups' {
            $script:Settings.EmergencyAccessAccounts = @(
                [pscustomobject]@{ UserPrincipalName = 'bg@contoso.com' },
                [pscustomobject]@{ Id = 'grp'; Type = 'Group' }
            )
            $script:Graph['^users/bg%40contoso\.com$'] = [pscustomobject]@{ id = 'bg-id' }
            $script:Graph['^groups/grp/transitiveMembers$'] = @([pscustomobject]@{ id = 'm1'; userPrincipalName = 'm1@contoso.com' })
            $ids = Get-MtNsmEmergencyAccess
            $ids | Should -Contain 'bg-id'
            $ids | Should -Contain 'bg@contoso.com'
            $ids | Should -Contain 'grp'
            $ids | Should -Contain 'm1'
        }

        It 'counts passkeys, FIDO2, Windows Hello and macOS platform credentials as phishing-resistant' {
            Test-MtNsmPhishingResistantMethod @('passKeyDeviceBound') | Should -BeTrue
            Test-MtNsmPhishingResistantMethod @('macOsSecureEnclaveKey') | Should -BeTrue
            Test-MtNsmPhishingResistantMethod @('microsoftAuthenticatorPasswordless', 'mobilePhone') | Should -BeFalse
        }
    }

    Describe 'MP.NSM.1001 phishing-resistant Conditional Access' {
        BeforeEach {
            $script:Graph['^policies/authenticationStrengthPolicies$'] = @([pscustomobject]@{ id = 'pr'; allowedCombinations = @('fido2', 'windowsHelloForBusiness') })
            $script:Strength = @{ operator = 'OR'; builtInControls = @(); authenticationStrength = [pscustomobject]@{ id = 'pr' } }
        }

        It 'is høy grad for an enabled policy for everyone with the strength as its only control' {
            $script:Ca = @(New-CaPolicy -Grant $script:Strength)
            (Invoke-NsmTest 1001).Level | Should -Be 'Høy'
        }

        It 'is moderat grad when large groups are excluded' {
            $script:Ca = @(New-CaPolicy -Grant $script:Strength -Users @{ excludeGroups = @('g1', 'g2', 'g3') })
            (Invoke-NsmTest 1001).Level | Should -Be 'Moderat'
        }

        It 'is moderat grad when the policy only applies outside trusted locations' {
            $script:Ca = @(New-CaPolicy -Grant $script:Strength -Conditions @{ locations = [pscustomobject]@{ includeLocations = @('All'); excludeLocations = @('AllTrusted') } })
            (Invoke-NsmTest 1001).Level | Should -Be 'Moderat'
        }

        It 'is liten grad when no policy asks for a phishing-resistant strength' {
            $script:Ca = @(New-CaPolicy)
            (Invoke-NsmTest 1001).Level | Should -Be 'Liten'
        }
    }

    Describe 'MP.NSM.1002 admins with phishing-resistant methods' {
        BeforeEach {
            $script:Graph['^policies/authenticationMethodsPolicy$'] = [pscustomobject]@{ authenticationMethodConfigurations = @() }
            $script:Graph['^users/'] = [pscustomobject]@{ id = 'bg-id' }
        }

        It 'leaves out a break-glass account given only by user principal name' {
            $script:Settings.EmergencyAccessAccounts = @([pscustomobject]@{ UserPrincipalName = 'bg@contoso.com' })
            $script:Graph['^reports/authenticationMethods/userRegistrationDetails$'] = @(
                [pscustomobject]@{ id = 'a1'; userPrincipalName = 'admin@contoso.com'; methodsRegistered = @('fido2SecurityKey') },
                [pscustomobject]@{ id = 'bg-id'; userPrincipalName = 'bg@contoso.com'; methodsRegistered = @('mobilePhone') }
            )
            (Invoke-NsmTest 1002).Level | Should -Be 'Høy'
        }

        It 'says so when certificate-based authentication is on' {
            $script:Graph['^policies/authenticationMethodsPolicy$'] = [pscustomobject]@{ authenticationMethodConfigurations = @([pscustomobject]@{ id = 'X509Certificate'; state = 'enabled' }) }
            $script:Graph['^reports/authenticationMethods/userRegistrationDetails$'] = @([pscustomobject]@{ id = 'a1'; userPrincipalName = 'admin@contoso.com'; methodsRegistered = @() })
            $r = Invoke-NsmTest 1002
            $r.Level | Should -Be 'Liten'
            $r.Text | Should -Match 'Certificate-based authentication \(CBA\)'
        }

        It 'skips as not authorised on 403' {
            $script:Graph['^reports/'] = New-GraphError 403
            (Invoke-NsmTest 1002).Skipped | Should -Be 'NotAuthorized'
        }
    }

    Describe 'MP.NSM.1003 users with phishing-resistant methods' {
        It 'counts only enabled members with a licence' {
            $script:Graph['^policies/authenticationMethodsPolicy$'] = [pscustomobject]@{ authenticationMethodConfigurations = @() }
            $script:Graph['^reports/authenticationMethods/userRegistrationDetails$'] = @(
                [pscustomobject]@{ id = 'u1'; userPrincipalName = 'u1@contoso.com'; methodsRegistered = @('passKeyDeviceBound') },
                [pscustomobject]@{ id = 'room'; userPrincipalName = 'room@contoso.com'; methodsRegistered = @() }
            )
            $script:Graph['^users$'] = @(
                [pscustomobject]@{ id = 'u1'; assignedLicenses = @([pscustomobject]@{ skuId = 's' }) },
                [pscustomobject]@{ id = 'room'; assignedLicenses = @() }
            )
            $r = Invoke-NsmTest 1003
            $r.Level | Should -Be 'Høy'
            $r.Text | Should -Match '100 % av 1 aktiv bruker med lisens'
        }
    }

    Describe 'MP.NSM.1004 authentication methods policy' {
        BeforeEach {
            $script:Methods = @(
                [pscustomobject]@{ id = 'Fido2'; state = 'enabled'; isAttestationEnforced = $true },
                [pscustomobject]@{ id = 'Sms'; state = 'disabled' },
                [pscustomobject]@{ id = 'Voice'; state = 'disabled' },
                [pscustomobject]@{ id = 'Email'; state = 'disabled'; allowExternalIdToUseEmailOtp = 'enabled' }
            )
        }

        It 'is høy grad with FIDO2 attested, SMS and voice off, and the migration complete' {
            $script:Graph['^policies/authenticationMethodsPolicy$'] = [pscustomobject]@{ policyMigrationState = 'migrationComplete'; authenticationMethodConfigurations = $script:Methods }
            (Invoke-NsmTest 1004).Level | Should -Be 'Høy'
        }

        It 'is moderat grad while the legacy MFA and SSPR policies still apply' {
            $script:Graph['^policies/authenticationMethodsPolicy$'] = [pscustomobject]@{ policyMigrationState = 'preMigration'; authenticationMethodConfigurations = $script:Methods }
            (Invoke-NsmTest 1004).Level | Should -Be 'Moderat'
        }

        It 'is moderat grad when Email OTP is on for the tenant''s users' {
            ($script:Methods | Where-Object id -EQ 'Email').state = 'enabled'
            $script:Graph['^policies/authenticationMethodsPolicy$'] = [pscustomobject]@{ policyMigrationState = 'migrationComplete'; authenticationMethodConfigurations = $script:Methods }
            $r = Invoke-NsmTest 1004
            $r.Level | Should -Be 'Moderat'
            $r.Text | Should -Match 'Fortsatt på: Email OTP\.'
        }

        It 'is moderat grad when SMS is on, and names it as the portal does' {
            ($script:Methods | Where-Object id -EQ 'Sms').state = 'enabled'
            $script:Graph['^policies/authenticationMethodsPolicy$'] = [pscustomobject]@{ policyMigrationState = 'migrationComplete'; authenticationMethodConfigurations = $script:Methods }
            $r = Invoke-NsmTest 1004
            $r.Level | Should -Be 'Moderat'
            $r.Text | Should -Match 'Fortsatt på: SMS\.'
        }

        It 'does not score Email OTP for guests, which is a separate setting' {
            $script:Graph['^policies/authenticationMethodsPolicy$'] = [pscustomobject]@{ policyMigrationState = 'migrationComplete'; authenticationMethodConfigurations = $script:Methods }
            (Invoke-NsmTest 1004).Level | Should -Be 'Høy'
        }
    }

    Describe 'MP.NSM.1005 MFA for all users' {
        It 'is høy grad when MFA is the only control' {
            $script:Ca = @(New-CaPolicy)
            (Invoke-NsmTest 1005).Level | Should -Be 'Høy'
        }

        It 'is moderat grad for "MFA or compliant device"' {
            $script:Ca = @(New-CaPolicy -Grant @{ operator = 'OR'; builtInControls = @('mfa', 'compliantDevice') })
            (Invoke-NsmTest 1005).Level | Should -Be 'Moderat'
        }

        It 'is moderat grad when roles and guests are excluded' {
            $script:Ca = @(New-CaPolicy -Users @{ excludeRoles = @('r1', 'r2'); excludeGuestsOrExternalUsers = [pscustomobject]@{ guestOrExternalUserTypes = 'b2bCollaborationGuest' } })
            (Invoke-NsmTest 1005).Level | Should -Be 'Moderat'
        }

        It 'does not count break-glass accounts given by user principal name as exceptions' {
            $script:Settings.EmergencyAccessAccounts = @([pscustomobject]@{ UserPrincipalName = 'bg1@contoso.com' }, [pscustomobject]@{ UserPrincipalName = 'bg2@contoso.com' })
            $script:Graph['^users/bg1'] = [pscustomobject]@{ id = 'id1' }
            $script:Graph['^users/bg2'] = [pscustomobject]@{ id = 'id2' }
            $script:Ca = @(New-CaPolicy -Users @{ excludeUsers = @('id1', 'id2', 'svc') })
            (Invoke-NsmTest 1005).Level | Should -Be 'Høy'
        }

        It 'is liten grad without a policy for everyone' {
            (Invoke-NsmTest 1005).Level | Should -Be 'Liten'
        }
    }

    Describe 'MP.NSM.1006 permanent privileged roles' {
        BeforeEach {
            $script:Graph['^roleManagement/directory/roleDefinitions$'] = @([pscustomobject]@{ id = 'ga'; templateId = 'ga'; displayName = 'Global Administrator' })
        }

        It 'is høy grad with at most two permanent holders' {
            $script:Graph['roleAssignmentScheduleInstances'] = @(
                [pscustomobject]@{ roleDefinitionId = 'ga'; principalId = 'p1'; assignmentType = 'Assigned'; endDateTime = $null; principal = [pscustomobject]@{ userPrincipalName = 'a@contoso.com' } },
                [pscustomobject]@{ roleDefinitionId = 'ga'; principalId = 'p2'; assignmentType = 'Activated'; endDateTime = '2026-11-09T12:00:00Z'; principal = [pscustomobject]@{ userPrincipalName = 'b@contoso.com' } }
            )
            $r = Invoke-NsmTest 1006
            $r.Level | Should -Be 'Høy'
            $r.Text | Should -Match 'Global Administrator'
        }

        It 'falls back to role assignments only when Entra ID P2 is missing' {
            $script:Graph['roleAssignmentScheduleInstances'] = New-GraphError 400 'AadPremiumLicenseRequired'
            $script:Graph['roleAssignments'] = @(1..3 | ForEach-Object { [pscustomobject]@{ roleDefinitionId = 'ga'; principalId = "p$_"; principal = [pscustomobject]@{ userPrincipalName = "u$_@contoso.com" } } })
            (Invoke-NsmTest 1006).Level | Should -Be 'Moderat'
        }

        It 'skips as not authorised on 403 instead of counting activated assignments as permanent' {
            $script:Graph['roleAssignmentScheduleInstances'] = New-GraphError 403
            (Invoke-NsmTest 1006).Skipped | Should -Be 'NotAuthorized'
        }

        It 'lets other errors through to Maester' {
            $script:Graph['roleAssignmentScheduleInstances'] = New-GraphError 500
            { Invoke-NsmTest 1006 } | Should -Throw
        }
    }

    Describe 'MP.NSM.1007 PIM activation' {
        BeforeEach {
            $script:Graph['^roleManagement/directory/roleDefinitions$'] = @([pscustomobject]@{ id = 'ga'; templateId = 'ga' })
            $script:Graph['roleEligibilityScheduleInstances'] = @([pscustomobject]@{ roleDefinitionId = 'ga'; roleDefinition = [pscustomobject]@{ displayName = 'Global Administrator' } })
        }

        It 'skips as not authorised when the activation rules cannot be read, instead of scoring moderat grad' {
            $script:Graph['^policies/roleManagementPolicyAssignments$'] = New-GraphError 403
            (Invoke-NsmTest 1007).Skipped | Should -Be 'NotAuthorized'
        }

        It 'is høy grad with approval and an authentication context' {
            $rules = @(
                [pscustomobject]@{ id = 'Approval_EndUser_Assignment'; setting = [pscustomobject]@{ isApprovalRequired = $true } },
                [pscustomobject]@{ id = 'Enablement_EndUser_Assignment'; enabledRules = @() },
                [pscustomobject]@{ id = 'AuthenticationContext_EndUser_Assignment'; isEnabled = $true; claimValue = 'c1' }
            )
            $script:Graph['^policies/roleManagementPolicyAssignments$'] = @([pscustomobject]@{ policy = [pscustomobject]@{ rules = $rules } })
            (Invoke-NsmTest 1007).Level | Should -Be 'Høy'
        }

        It 'is moderat grad without approval' {
            $rules = @([pscustomobject]@{ id = 'Enablement_EndUser_Assignment'; enabledRules = @('MultiFactorAuthentication') })
            $script:Graph['^policies/roleManagementPolicyAssignments$'] = @([pscustomobject]@{ policy = [pscustomobject]@{ rules = $rules } })
            (Invoke-NsmTest 1007).Level | Should -Be 'Moderat'
        }
    }

    Describe 'MP.NSM.1008 guest access reviews' {
        It 'is not applicable in a tenant without guests' {
            $script:Graph['^users$'] = [pscustomobject]@{ value = @() }
            $script:Graph['accessReviews'] = @()
            (Invoke-NsmTest 1008).Skipped | Should -Be 'NotApplicable'
        }

        It 'is høy grad with a recurring review of guests' {
            $script:Graph['^users$'] = [pscustomobject]@{ value = @([pscustomobject]@{ id = 'g1' }) }
            $script:Graph['accessReviews'] = @([pscustomobject]@{
                    displayName = 'Gjester'; status = 'InProgress'
                    scope       = [pscustomobject]@{ query = "/users?`$filter=(userType eq 'Guest')" }
                    settings    = [pscustomobject]@{ recurrence = [pscustomobject]@{ pattern = [pscustomobject]@{ type = 'absoluteMonthly'; interval = 3 } } }
                })
            (Invoke-NsmTest 1008).Level | Should -Be 'Høy'
        }
    }

    Describe 'MP.NSM.1010 Entra recommendations' {
        It 'skips as not authorised on 403' {
            $script:Graph['^directory/recommendations$'] = New-GraphError 403
            (Invoke-NsmTest 1010).Skipped | Should -Be 'NotAuthorized'
        }

        It 'lets other errors through to Maester' {
            $script:Graph['^directory/recommendations$'] = New-GraphError 400
            { Invoke-NsmTest 1010 } | Should -Throw
        }
    }

    Describe 'MP.NSM.2001 legacy authentication' {
        BeforeEach {
            $script:Graph['identitySecurityDefaultsEnforcementPolicy'] = [pscustomobject]@{ isEnabled = $false }
            $script:Block = @{ operator = 'OR'; builtInControls = @('block') }
            $script:Legacy = @{ clientAppTypes = @('exchangeActiveSync', 'other') }
        }

        It 'is høy grad with security defaults and no policies' {
            $script:Graph['identitySecurityDefaultsEnforcementPolicy'] = [pscustomobject]@{ isEnabled = $true }
            (Invoke-NsmTest 2001).Level | Should -Be 'Høy'
        }

        It 'is høy grad for an enabled block for everyone' {
            $script:Ca = @(New-CaPolicy -Grant $script:Block -Conditions $script:Legacy)
            (Invoke-NsmTest 2001).Level | Should -Be 'Høy'
        }

        It 'is moderat grad when many are excluded' {
            $script:Ca = @(New-CaPolicy -Grant $script:Block -Conditions $script:Legacy -Users @{ excludeGroups = @('g1', 'g2', 'g3') })
            (Invoke-NsmTest 2001).Level | Should -Be 'Moderat'
        }

        It 'is liten grad without a block or security defaults' {
            (Invoke-NsmTest 2001).Level | Should -Be 'Liten'
        }
    }

    Describe 'MP.NSM.2002 Secure Score recommendations' {
        BeforeEach {
            function Set-SecureScore {
                # A Secure Score of 10 %, with the given recommendations and their share met.
                param([hashtable] $Met)
                $controls = foreach ($name in $Met.Keys) {
                    [pscustomobject]@{ controlName = $name; scoreInPercentage = $Met[$name]; implementationStatus = "<p>$name&nbsp;status</p>" }
                }
                $script:Graph['^security/secureScores$'] = [pscustomobject]@{ value = @([pscustomobject]@{ currentScore = 10; maxScore = 100; controlScores = @($controls) }) }
            }
        }

        It 'skips as not authorised on 403' {
            $script:Graph['^security/secureScores$'] = New-GraphError 403
            (Invoke-NsmTest 2002).Skipped | Should -Be 'NotAuthorized'
        }

        It 'is høy grad when every listed recommendation is met, whatever the overall score' {
            Set-SecureScore @{ scid_53 = 100; spo_legacy_auth = 100; CustomerLockBoxEnabled = 0 }
            $r = Invoke-NsmTest 2002
            $r.Level | Should -Be 'Høy'
            $r.Text | Should -Match '2 av 2 anbefalinger'
            $r.Text | Should -Match 'Samlet Secure Score er 10 %, til orientering'
        }

        It 'is moderat grad when half are met, and counts a partly met one as not met' {
            Set-SecureScore @{ scid_53 = 100; scid_54 = 50 }
            $r = Invoke-NsmTest 2002
            $r.Level | Should -Be 'Moderat'
            $r.Text | Should -Match '\| Delvis \(50 %\) \| scid\\_54 status \|'
        }

        It 'is liten grad when fewer than half are met' {
            Set-SecureScore @{ scid_53 = 100; scid_54 = 0; scid_57 = 0 }
            (Invoke-NsmTest 2002).Level | Should -Be 'Liten'
        }

        It 'leaves out recommendations other tests score' {
            Set-SecureScore @{ BlockLegacyAuthentication = 0; IntegratedApps = 0; scid_53 = 100 }
            (Invoke-NsmTest 2002).Level | Should -Be 'Høy'
        }

        It 'skips when the tenant has none of the recommendations' {
            Set-SecureScore @{ CustomerLockBoxEnabled = 0 }
            (Invoke-NsmTest 2002).Skipped | Should -Be 'Custom'
        }
    }

    Describe 'MP.NSM.2003 phishing simulation' {
        It 'does not count a scheduled simulation as run' {
            $script:Graph['simulations'] = @([pscustomobject]@{ displayName = 'Neste'; status = 'scheduled'; launchDateTime = [datetime]::UtcNow.AddDays(10) })
            (Invoke-NsmTest 2003).Level | Should -Be 'Liten'
        }

        It 'is høy grad for a simulation that ran in the last 90 days' {
            $script:Graph['simulations'] = @([pscustomobject]@{ displayName = 'Høst'; status = 'succeeded'; launchDateTime = [datetime]::UtcNow.AddDays(-20) })
            (Invoke-NsmTest 2003).Level | Should -Be 'Høy'
        }

        It 'skips as not authorised on 403' {
            $script:Graph['simulations'] = New-GraphError 403
            (Invoke-NsmTest 2003).Skipped | Should -Be 'NotAuthorized'
        }
    }

    Describe 'MP.NSM.2004 Defender for Identity' {
        It 'is not applicable in a cloud-only tenant' {
            $script:Graph['^organization$'] = @([pscustomobject]@{ onPremisesSyncEnabled = $null })
            (Invoke-NsmTest 2004).Skipped | Should -Be 'NotApplicable'
        }

        It 'is høy grad when Secure Score reports the sensor installed' {
            $script:Graph['^organization$'] = @([pscustomobject]@{ onPremisesSyncEnabled = $true })
            $script:Graph['^security/secureScores$'] = [pscustomobject]@{ value = @([pscustomobject]@{ controlScores = @([pscustomobject]@{ controlName = 'AATP_DefenderForIdentityIsNotInstalled'; scoreInPercentage = 100 }) }) }
            (Invoke-NsmTest 2004).Level | Should -Be 'Høy'
        }

        It 'skips as not authorised on 403' {
            $script:Graph['^organization$'] = @([pscustomobject]@{ onPremisesSyncEnabled = $true })
            $script:Graph['^security/secureScores$'] = New-GraphError 403
            (Invoke-NsmTest 2004).Skipped | Should -Be 'NotAuthorized'
        }
    }

    Describe 'Intune device tests' {
        BeforeEach {
            $script:All = @([pscustomobject]@{ target = [pscustomobject]@{ '@odata.type' = '#microsoft.graph.allDevicesAssignmentTarget' } })
            $script:ExclusionOnly = @([pscustomobject]@{ target = [pscustomobject]@{ '@odata.type' = '#microsoft.graph.exclusionGroupAssignmentTarget' } })
            $script:Group = @([pscustomobject]@{ target = [pscustomobject]@{ '@odata.type' = '#microsoft.graph.groupAssignmentTarget' } })
            # Device settings in Entra ID: LAPS on, in a cloud-only tenant. No older policies (intents).
            $script:Graph['deviceRegistrationPolicy'] = [pscustomobject]@{ localAdminPassword = [pscustomobject]@{ isEnabled = $true } }
            $script:Graph['^organization$'] = @([pscustomobject]@{ onPremisesSyncEnabled = $null })
            $script:Graph['^deviceManagement/templates$'] = @()
            $script:Graph['^deviceManagement/intents$'] = @()

            function New-EndpointPolicy {
                # An Intune endpoint security policy of the given template family.
                param([string] $Name, [string] $Family, [string] $Template, [object[]] $Assignments = $script:All)
                [pscustomobject]@{ id = $Name; name = $Name; assignments = $Assignments; templateReference = [pscustomobject]@{ templateFamily = $Family; templateDisplayName = $Template } }
            }
        }

        It '3001 does not count a LAPS policy assigned to exclusion groups only' {
            $script:Graph['configurationPolicies'] = @([pscustomobject]@{ id = '1'; name = 'LAPS'; assignments = $script:ExclusionOnly; templateReference = [pscustomobject]@{ templateFamily = 'endpointSecurityAccountProtection'; templateDisplayName = 'Local admin password solution (Windows LAPS)' } })
            (Invoke-NsmTest 3001).Level | Should -Be 'Liten'
        }

        It '3001 finds LAPS set in the settings catalog' {
            $script:Graph["configurationPolicies\('c1'\)/settings"] = @([pscustomobject]@{ settingInstance = [pscustomobject]@{ settingDefinitionId = 'device_vendor_msft_laps_policies_backupdirectory' } })
            $script:Graph['configurationPolicies'] = @([pscustomobject]@{ id = 'c1'; name = 'LAPS katalog'; assignments = $script:All; templateReference = [pscustomobject]@{ templateFamily = 'none' } })
            (Invoke-NsmTest 3001).Level | Should -Be 'Høy'
        }

        It '3003 counts App Control for Business set by OMA-URI' {
            $script:Graph['configurationPolicies'] = @()
            $script:Graph['deviceConfigurations/w1$'] = [pscustomobject]@{ omaSettings = @([pscustomobject]@{ omaUri = './Vendor/MSFT/ApplicationControl/Policies/x/Policy' }) }
            $script:Graph['deviceConfigurations'] = @([pscustomobject]@{ id = 'w1'; displayName = 'WDAC'; '@odata.type' = '#microsoft.graph.windows10CustomConfiguration'; assignments = $script:All })
            (Invoke-NsmTest 3003).Level | Should -Be 'Høy'
        }

        It '3001 is liten grad in a cloud-only tenant when LAPS is turned off in Entra ID' {
            $script:Graph['deviceRegistrationPolicy'] = [pscustomobject]@{ localAdminPassword = [pscustomobject]@{ isEnabled = $false } }
            $script:Graph['configurationPolicies'] = @(New-EndpointPolicy -Name 'LAPS' -Family 'endpointSecurityAccountProtection' -Template 'Local admin password solution (Windows LAPS)')
            $r = Invoke-NsmTest 3001
            $r.Level | Should -Be 'Liten'
            $r.Text | Should -Match 'LAPS er slått av i Device settings i Entra ID'
        }

        It '3001 keeps the level in a hybrid tenant when LAPS is off in Entra ID, and says so' {
            $script:Graph['deviceRegistrationPolicy'] = [pscustomobject]@{ localAdminPassword = [pscustomobject]@{ isEnabled = $false } }
            $script:Graph['^organization$'] = @([pscustomobject]@{ onPremisesSyncEnabled = $true })
            $script:Graph['configurationPolicies'] = @(New-EndpointPolicy -Name 'LAPS' -Family 'endpointSecurityAccountProtection' -Template 'Local admin password solution (Windows LAPS)')
            $r = Invoke-NsmTest 3001
            $r.Level | Should -Be 'Høy'
            $r.Text | Should -Match 'lokal Active Directory'
        }

        It '3001 keeps the level and says so when the device settings cannot be read' {
            $script:Graph['deviceRegistrationPolicy'] = New-GraphError 403
            $script:Graph['configurationPolicies'] = @(New-EndpointPolicy -Name 'LAPS' -Family 'endpointSecurityAccountProtection' -Template 'Local admin password solution (Windows LAPS)')
            $r = Invoke-NsmTest 3001
            $r.Level | Should -Be 'Høy'
            $r.Text | Should -Match 'kunne ikke leses'
        }

        It '<Id> is høy grad for a policy assigned to all devices, moderat for groups, liten without one' -ForEach @(
            @{ Id = '3004'; Family = 'endpointSecurityAttackSurfaceReduction'; Template = 'Attack Surface Reduction Rules' }
            @{ Id = '3008'; Family = 'endpointSecurityFirewall'; Template = 'Windows Firewall' }
            @{ Id = '3009'; Family = 'endpointSecurityAntivirus'; Template = 'Microsoft Defender Antivirus' }
            @{ Id = '3010'; Family = 'baseline'; Template = 'Security Baseline for Windows 10 and later' }
        ) {
            $script:Graph['configurationPolicies'] = @(New-EndpointPolicy -Name 'P' -Family $Family -Template $Template)
            (Invoke-NsmTest $Id).Level | Should -Be 'Høy'
            $script:Graph['configurationPolicies'] = @(New-EndpointPolicy -Name 'P' -Family $Family -Template $Template -Assignments $script:Group)
            $r = Invoke-NsmTest $Id
            $r.Level | Should -Be 'Moderat'
            $r.Text | Should -Match '\| P \| Endpoint security \| Grupper \|'
            $script:Graph['configurationPolicies'] = @(New-EndpointPolicy -Name 'P' -Family $Family -Template $Template -Assignments $script:ExclusionOnly)
            (Invoke-NsmTest $Id).Level | Should -Be 'Liten'
        }

        It 'each endpoint check counts only its own kind of policy' {
            $script:Graph['configurationPolicies'] = @(New-EndpointPolicy -Name 'FW' -Family 'endpointSecurityFirewall' -Template 'Windows Firewall')
            (Invoke-NsmTest 3008).Level | Should -Be 'Høy'
            (Invoke-NsmTest 3004).Level | Should -Be 'Liten'
            (Invoke-NsmTest 3009).Level | Should -Be 'Liten'
            (Invoke-NsmTest 3010).Level | Should -Be 'Liten'
        }

        It '3009 does not count antivirus exclusions, and 3008 does not count firewall rules' {
            $script:Graph['configurationPolicies'] = @(
                New-EndpointPolicy -Name 'AV unntak' -Family 'endpointSecurityAntivirus' -Template 'Microsoft Defender Antivirus exclusions'
                New-EndpointPolicy -Name 'FW regler' -Family 'endpointSecurityFirewall' -Template 'Windows Firewall Rules'
            )
            (Invoke-NsmTest 3009).Level | Should -Be 'Liten'
            (Invoke-NsmTest 3008).Level | Should -Be 'Liten'
        }

        It '3009 credits an older antivirus policy (intent) to antivirus, with its own assignment, and 3010 does not' {
            $script:Graph['configurationPolicies'] = @()
            $script:Graph['^deviceManagement/templates$'] = @([pscustomobject]@{ id = 't-av'; templateType = 'securityTemplate'; templateSubtype = 'antivirus' })
            $script:Graph['^deviceManagement/intents/i1/assignments$'] = $script:Group
            $script:Graph['^deviceManagement/intents$'] = @([pscustomobject]@{ id = 'i1'; displayName = 'Gammel AV'; isAssigned = $true; templateId = 't-av' })
            $r = Invoke-NsmTest 3009
            $r.Level | Should -Be 'Moderat'
            $r.Text | Should -Match '\| Gammel AV \| Endpoint security \(intent\) \| Grupper \|'
            (Invoke-NsmTest 3010).Level | Should -Be 'Liten'
        }

        It '3010 counts a settings catalog policy whose name matches the baseline pattern' {
            $script:Graph['configurationPolicies'] = @(New-EndpointPolicy -Name 'CIS L1 Windows 11' -Family 'none' -Template '')
            (Invoke-NsmTest 3010).Level | Should -Be 'Høy'
            $script:Settings['NsmGpIkt.BaselinePolicyPattern'] = 'Grunnlinje'
            (Invoke-NsmTest 3010).Level | Should -Be 'Liten'
        }

        It '3005 scores the share of encrypted devices only' {
            $script:Graph['managedDevices'] = @(
                [pscustomobject]@{ deviceName = 'a'; complianceState = 'noncompliant'; isEncrypted = $true },
                [pscustomobject]@{ deviceName = 'b'; complianceState = 'noncompliant'; isEncrypted = $true }
            )
            (Invoke-NsmTest 3005).Level | Should -Be 'Høy'
            $script:Graph['managedDevices'] = @(
                [pscustomobject]@{ deviceName = 'a'; complianceState = 'compliant'; isEncrypted = $true },
                [pscustomobject]@{ deviceName = 'b'; complianceState = 'compliant'; isEncrypted = $false }
            )
            $r = Invoke-NsmTest 3005
            $r.Level | Should -Be 'Liten'
            $r.Text | Should -Match '50 % av 2 Windows-enheter er kryptert'
        }

        It '3011 leaves co-managed devices out of the compliance share, and does not look at encryption' {
            $script:Graph['managedDevices'] = @(
                [pscustomobject]@{ deviceName = 'a'; complianceState = 'compliant'; isEncrypted = $false },
                [pscustomobject]@{ deviceName = 'b'; complianceState = 'configManager'; isEncrypted = $false }
            )
            $script:Graph['^deviceManagement$'] = [pscustomobject]@{ settings = [pscustomobject]@{ secureByDefault = $true } }
            (Invoke-NsmTest 3011).Level | Should -Be 'Høy'
        }

        It '3011 is at most moderat grad when devices without a policy count as compliant' {
            $script:Graph['managedDevices'] = @([pscustomobject]@{ deviceName = 'a'; complianceState = 'compliant'; isEncrypted = $true })
            $script:Graph['^deviceManagement$'] = [pscustomobject]@{ settings = [pscustomobject]@{ secureByDefault = $false } }
            (Invoke-NsmTest 3011).Level | Should -Be 'Moderat'
        }

        It '3011 skips when Configuration Manager evaluates compliance for every device' {
            $script:Graph['managedDevices'] = @([pscustomobject]@{ deviceName = 'a'; complianceState = 'configManager'; isEncrypted = $true })
            (Invoke-NsmTest 3011).Skipped | Should -Be 'Custom'
        }

        It '3006 is høy grad when the active devices are managed' {
            $script:Graph['^devices$'] = @([pscustomobject]@{ displayName = 'pc'; isManaged = $true; trustType = 'AzureAd'; approximateLastSignInDateTime = [datetime]::UtcNow.AddDays(-1) })
            (Invoke-NsmTest 3006).Level | Should -Be 'Høy'
        }

        It '3007 accepts builds the organisation lists as supported, such as LTSC' {
            $script:Settings['NsmGpIkt.AllowedWindowsBuilds'] = @(19044)
            $script:Graph['managedDevices'] = @(
                [pscustomobject]@{ deviceName = 'ltsc'; osVersion = '10.0.19044.5000' },
                [pscustomobject]@{ deviceName = 'new'; osVersion = '10.0.26100.1' }
            )
            (Invoke-NsmTest 3007).Level | Should -Be 'Høy'
        }

        It '3007 counts an unreadable version as unsupported instead of failing' {
            $script:Graph['managedDevices'] = @(
                [pscustomobject]@{ deviceName = 'odd'; osVersion = 'unknown' },
                [pscustomobject]@{ deviceName = 'new'; osVersion = '10.0.26100.1' }
            )
            (Invoke-NsmTest 3007).Level | Should -Be 'Liten'
        }
    }

    Describe 'MP.NSM.1011 local administrator on joined devices' {
        BeforeEach {
            function Set-DeviceSetting {
                param([string] $Admins, [string] $Join = 'all', [object[]] $Users = @())
                $type = { param($k) "#microsoft.graph.$($k)DeviceRegistrationMembership" }
                $script:Graph['deviceRegistrationPolicy'] = [pscustomobject]@{ azureADJoin = [pscustomobject]@{
                    allowedToJoin = [pscustomobject]@{ '@odata.type' = (& $type $Join) }
                    localAdmins   = [pscustomobject]@{ enableGlobalAdmins = $true; registeringUsers = [pscustomobject]@{ '@odata.type' = (& $type $Admins); users = $Users; groups = @() } }
                } }
            }
        }

        It 'is liten grad when every registering user becomes local administrator (the default)' {
            Set-DeviceSetting -Admins all
            (Invoke-NsmTest 1011).Level | Should -Be 'Liten'
        }

        It 'is moderat grad for selected users, and counts them' {
            Set-DeviceSetting -Admins enumerated -Users @('u1', 'u2')
            $r = Invoke-NsmTest 1011
            $r.Level | Should -Be 'Moderat'
            $r.Text | Should -Match '2 utvalgte'
        }

        It 'is høy grad when nobody becomes local administrator' {
            Set-DeviceSetting -Admins no
            (Invoke-NsmTest 1011).Level | Should -Be 'Høy'
        }

        It 'is not applicable when no user can join a device' {
            Set-DeviceSetting -Admins all -Join no
            (Invoke-NsmTest 1011).Skipped | Should -Be 'NotApplicable'
        }

        It 'reads the response Graph v1.0 returns (shape from a real tenant, 2026-11-11)' {
            $script:Graph['deviceRegistrationPolicy'] = '{"id":"deviceRegistrationPolicy","userDeviceQuota":50,"multiFactorAuthConfiguration":"required","localAdminPassword":{"isEnabled":false},"azureADRegistration":{"isAdminConfigurable":false,"allowedToRegister":{"@odata.type":"#microsoft.graph.allDeviceRegistrationMembership"}},"azureADJoin":{"isAdminConfigurable":true,"allowedToJoin":{"@odata.type":"#microsoft.graph.allDeviceRegistrationMembership"},"localAdmins":{"enableGlobalAdmins":true,"registeringUsers":{"@odata.type":"#microsoft.graph.allDeviceRegistrationMembership"}}}}' | ConvertFrom-Json
            $r = Invoke-NsmTest 1011
            $r.Level | Should -Be 'Liten'
            $r.Text | Should -Match 'Global Administrator-rollen er lokal administrator \(vurderes ikke\) \| Ja'
        }

        It 'skips as not authorised on 403, and lets other errors through' {
            $script:Graph['deviceRegistrationPolicy'] = New-GraphError 403
            (Invoke-NsmTest 1011).Skipped | Should -Be 'NotAuthorized'
            $script:Graph['deviceRegistrationPolicy'] = New-GraphError 500
            { Invoke-NsmTest 1011 } | Should -Throw
        }
    }

    Describe 'MP.NSM.1012 managed device in Conditional Access' {
        It 'is høy grad for an enabled policy that requires a compliant device for everyone' {
            $script:Ca = @(New-CaPolicy -Grant @{ operator = 'OR'; builtInControls = @('compliantDevice') })
            (Invoke-NsmTest 1012).Level | Should -Be 'Høy'
        }

        It 'is høy grad when the alternatives are all device controls (compliant or hybrid joined)' {
            $script:Ca = @(New-CaPolicy -Grant @{ operator = 'OR'; builtInControls = @('compliantDevice', 'domainJoinedDevice') })
            (Invoke-NsmTest 1012).Level | Should -Be 'Høy'
        }

        It 'is moderat grad for "MFA or compliant device", which a user can meet without a managed device' {
            $script:Ca = @(New-CaPolicy -Grant @{ operator = 'OR'; builtInControls = @('mfa', 'compliantDevice') })
            $r = Invoke-NsmTest 1012
            $r.Level | Should -Be 'Moderat'
            $r.Text | Should -Match 'kan oppfylles uten forvaltet enhet'
        }

        It 'is høy grad for "MFA and compliant device"' {
            $script:Ca = @(New-CaPolicy -Grant @{ operator = 'AND'; builtInControls = @('mfa', 'compliantDevice') })
            (Invoke-NsmTest 1012).Level | Should -Be 'Høy'
        }

        It 'is moderat grad in report-only mode, for selected users, or for one platform' {
            $script:Ca = @(New-CaPolicy -Grant @{ operator = 'OR'; builtInControls = @('compliantDevice') } -State 'enabledForReportingButNotEnforced')
            (Invoke-NsmTest 1012).Level | Should -Be 'Moderat'
            $script:Ca = @(New-CaPolicy -Grant @{ operator = 'OR'; builtInControls = @('compliantDevice') } -Users @{ includeUsers = @(); includeGroups = @('g1') })
            (Invoke-NsmTest 1012).Level | Should -Be 'Moderat'
            $script:Ca = @(New-CaPolicy -Grant @{ operator = 'OR'; builtInControls = @('compliantDevice') } -Conditions @{ platforms = [pscustomobject]@{ includePlatforms = @('windows'); excludePlatforms = @() } })
            (Invoke-NsmTest 1012).Level | Should -Be 'Moderat'
        }

        It 'is liten grad when no policy asks for a managed device' {
            $script:Ca = @(New-CaPolicy)
            (Invoke-NsmTest 1012).Level | Should -Be 'Liten'
        }
    }

    Describe 'MP.NSM.2005 Outlook add-ins' {
        BeforeEach {
            function Set-AddinScore {
                param([object] $Percent)
                $controls = @([pscustomobject]@{ controlName = 'scid_53'; scoreInPercentage = 100 })
                if ($null -ne $Percent) { $controls += [pscustomobject]@{ controlName = 'exo_outlookaddins'; scoreInPercentage = $Percent; implementationStatus = '<p>3 policies&nbsp;allow add-ins</p>' } }
                $script:Graph['^security/secureScores$'] = [pscustomobject]@{ value = @([pscustomobject]@{ currentScore = 10; maxScore = 100; controlScores = $controls }) }
            }
        }

        It 'is <Level> grad when the recommendation is <Percent> % met' -ForEach @(
            @{ Percent = 100; Level = 'Høy' }, @{ Percent = 50; Level = 'Moderat' }, @{ Percent = 0; Level = 'Liten' }
        ) {
            Set-AddinScore $Percent
            $r = Invoke-NsmTest 2005
            $r.Level | Should -Be $Level
            # The level follows the score; Microsoft's own text is quoted, marked as such.
            $r.Text | Should -Match "Secure Score: $Percent % oppfylt\. Microsofts tekst: «3 policies allow add-ins»\."
        }

        It 'skips when the tenant has no such recommendation, and as not authorised on 403' {
            Set-AddinScore $null
            (Invoke-NsmTest 2005).Skipped | Should -Be 'Custom'
            $script:Graph['^security/secureScores$'] = New-GraphError 403
            (Invoke-NsmTest 2005).Skipped | Should -Be 'NotAuthorized'
        }
    }

    Describe 'MP.NSM.2002 after the split' {
        It 'no longer scores Outlook add-ins or mail forwarding, and says how many recommendations the tenant has' {
            $controls = 'exo_outlookaddins', 'mdo_blockmailforward', 'mdo_autoforwardingmode' | ForEach-Object { [pscustomobject]@{ controlName = $_; scoreInPercentage = 0 } }
            $controls += [pscustomobject]@{ controlName = 'scid_53'; scoreInPercentage = 100 }
            $script:Graph['^security/secureScores$'] = [pscustomobject]@{ value = @([pscustomobject]@{ currentScore = 10; maxScore = 100; controlScores = $controls }) }
            $r = Invoke-NsmTest 2002
            $r.Level | Should -Be 'Høy'
            $r.Text | Should -Match 'Tenanten har 1 av de 26 anbefalingene'
            $r.Text | Should -Match '\| Defender for Endpoint \| SMBv1-klient'
        }
    }

    Describe 'Mapping catalogue' {
        BeforeDiscovery {
            $root = Join-Path $PSScriptRoot '..'
            $catalogue = Get-Content (Join-Path $root 'tools/data/mapping.json') -Raw | ConvertFrom-Json -AsHashtable
            $script:Cases = foreach ($file in Get-ChildItem (Join-Path $root 'nsm-gp-ikt/tests') -Filter 'Test.MP.NSM.*.ps1') {
                $n = [regex]::Match($file.Name, '\d{4}').Value
                @{ Id = $n; Text = Get-Content $file.FullName -Raw; Entry = $catalogue.tests[$n] }
            }
            $script:CatalogueIds = @($catalogue.tests.Keys)
        }

        BeforeAll {
            $script:Requirements = @{}
            foreach ($f in Get-ChildItem (Join-Path $PSScriptRoot '../nsm-gp-ikt/tests/frameworks') -Filter *.json) {
                $fw = Get-Content $f.FullName -Raw | ConvertFrom-Json
                $script:Requirements[$fw.Framework] = @($fw.Requirements.Id)
            }
        }

        It 'has an entry for every test, and no entry without a test' {
            @($script:Cases | Where-Object { -not $_.Entry }).Id | Should -BeNullOrEmpty
            $script:CatalogueIds | Where-Object { $_ -notin $script:Cases.Id } | Should -BeNullOrEmpty
        }

        It '<Id> has the Control the catalogue gives it: direct and partial links, in order' -ForEach $script:Cases {
            $control = [regex]::Match($Text, "(?m)^\s*Control\s*=\s*\(([^)]*)\)").Groups[1].Value
            $actual = @([regex]::Matches($control, "'([^']+)'") | ForEach-Object { $_.Groups[1].Value })
            $expected = @($Entry.cites | Where-Object { $_.strength -ne 'indikator' } | ForEach-Object { $_.ref })
            $actual | Should -Be $expected
        }

        It '<Id> states the scope the catalogue gives it on every result' -ForEach $script:Cases {
            $Text | Should -Match ([regex]::Escape("`$nsmScope = '$($Entry.scope)'"))
            $calls = [regex]::Matches($Text, 'Complete-MtNsmResult\b(?! -Scope \$nsmScope)')
            $calls.Count | Should -Be 0
        }

        It '<Id> cites requirements that exist, with a known strength and a reason' -ForEach $script:Cases {
            $Entry.cites.Count | Should -BeGreaterThan 0
            foreach ($c in $Entry.cites) {
                $key, $rid = $c.ref -split ':', 2
                $rid | Should -BeIn $script:Requirements[$key]
                $c.strength | Should -BeIn 'direkte', 'delvis', 'indikator'
                $c.why | Should -Not -BeNullOrEmpty
            }
        }

        It '<Id> has the ATT&CK techniques the catalogue gives it, or none' -ForEach $script:Cases {
            $mitre = [regex]::Match($Text, "(?m)^\s*Mitre\s*=\s*(.*?),?\s*$").Groups[1].Value
            $actual = @([regex]::Matches($mitre, "'([^']+)'") | ForEach-Object { $_.Groups[1].Value })
            $actual | Should -Be @($Entry.mitre.ids)
            if ($Entry.mitre) { $Entry.mitre.sameAs | Should -Not -BeNullOrEmpty }
        }

        It 'lists no related controls in the framework files, so the report shows no framework the pack does not test' {
            foreach ($f in Get-ChildItem (Join-Path $PSScriptRoot '../nsm-gp-ikt/tests/frameworks') -Filter *.json) {
                (Get-Content $f.FullName -Raw) | Should -Not -Match '"Related"'
            }
        }

        It 'lists every setting the tests read in the guide' {
            $guide = Get-Content (Join-Path $PSScriptRoot '../nsm-gp-ikt/maester-pack.guide.json') -Raw | ConvertFrom-Json
            $code = Get-ChildItem (Join-Path $PSScriptRoot '../nsm-gp-ikt') -Recurse -Filter *.ps1 | ForEach-Object { Get-Content $_.FullName -Raw }
            $read = $code | ForEach-Object { [regex]::Matches($_, "Get-MtSetting -Name '(NsmGpIkt\.[^']+)'") } | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique
            $read | Should -Not -BeNullOrEmpty
            $read | Where-Object { $_ -notin $guide.Run.Options.Name } | Should -BeNullOrEmpty
        }

        It '<Id> is tagged as an indicator exactly when it has no counted link' -ForEach $script:Cases {
            $indicator = -not @($Entry.cites | Where-Object { $_.strength -ne 'indikator' }).Count
            ($Text -match "'NSM-Indikator'") | Should -Be $indicator
        }

        It 'writes the scope on the second line of a result' {
            Complete-MtNsmResult -Level M -Summary 'Oppsummering.' -Scope 'Windows-klienter i Intune' -Details 'tabell' | Should -BeFalse
            ([string]$script:Detail.Result) -split "`n`n" | Should -Be @('**NSM-vurdering: Moderat grad.** Oppsummering.', '*Gjelder: Windows-klienter i Intune.*', 'tabell')
        }
    }

    Describe 'Test attributes' {
        BeforeAll {
            $script:Text = @{}
            foreach ($file in Get-ChildItem (Join-Path $PSScriptRoot '../nsm-gp-ikt/tests') -Filter 'Test.MP.NSM.*.ps1') {
                $script:Text[[regex]::Match($file.Name, '\d{4}').Value] = Get-Content $file.FullName -Raw
            }
        }

        It '<Id> declares licence <License>' -ForEach @(
            @{ Id = '1007'; License = "'AAD_PREMIUM_P2', 'Entra_Identity_Governance'" }
            @{ Id = '1008'; License = "'AAD_PREMIUM_P2', 'Entra_Identity_Governance'" }
            @{ Id = '2003'; License = "'THREAT_INTELLIGENCE'" }
            @{ Id = '2004'; License = "'ATA'" }
        ) {
            $script:Text[$Id] | Should -Match ([regex]::Escape("License = $(if ($License -match ',') { "($License)" } else { $License })"))
        }

        It 'no test checks its licence in code' {
            $script:Text.Values | Where-Object { $_ -match 'Get-MtLicenseInformation' } | Should -BeNullOrEmpty
        }

        It 'every test document has the heading the report splits "Why it matters" from "How to fix" on' {
            # Maester's report (ReportTemplate.html) looks for a heading that starts with Remediation, How to fix or
            # Investigation steps. Without it, the whole document shows under both.
            $docs = Get-ChildItem (Join-Path $PSScriptRoot '../nsm-gp-ikt/tests') -Filter 'Test.MP.NSM.*.md'
            $docs | Where-Object { (Get-Content $_.FullName -Raw) -notmatch '(?m)^#{2,6}\s*(Remediation|How to fix|Investigation steps)' } |
                Select-Object -ExpandProperty Name | Should -BeNullOrEmpty
        }

        It 'every test has an area the report knows, so "What an attacker could do" fits the test' {
            $areas = 'authentication', 'access-control', 'privileged-access', 'applications', 'external-access', 'email-protection',
                'data-protection', 'devices', 'logging-and-detection', 'infrastructure', 'identity-lifecycle'
            foreach ($id in $script:Text.Keys) { [regex]::Match($script:Text[$id], "Area = '([^']+)'").Groups[1].Value | Should -BeIn $areas -Because $id }
            # Mixed lists of tenant-wide recommendations are foundations, not mail or sign-in.
            $script:Text['2002'] | Should -Match "Area = 'infrastructure'"
            $script:Text['1010'] | Should -Match "Area = 'infrastructure'"
        }
    }
}
