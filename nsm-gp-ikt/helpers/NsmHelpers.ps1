function Complete-MtNsmResult {
    <#
    .SYNOPSIS
    Writes the result of an NSM check on NSM's scale and returns whether it passed.

    .DESCRIPTION
    NSM's risk assessment scores each measure as høy, moderat or liten grad. The first line of the result is
    always "NSM-vurdering: <grad>." so that the NSM dashboard can read the level from Maester's JSON. Only
    høy grad passes; moderat and liten grad fail, so that they show up in the report. The second line names the
    scope the verdict holds for.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        # H, M or L.
        [Parameter(Mandatory)] [ValidateSet('H', 'M', 'L')] [string] $Level,

        # One or two sentences on why the check landed at this level.
        [Parameter(Mandatory)] [string] $Summary,

        # What the check looked at, such as "Windows-klienter i Intune". NSM's measures cover more than one
        # platform, so the verdict holds for this scope only. Must match the scope in tools/data/mapping.json.
        [Parameter()] [string] $Scope,

        # Optional markdown, usually a table, shown under the summary.
        [Parameter()] [string] $Details
    )

    $name = @{ H = 'Høy grad'; M = 'Moderat grad'; L = 'Liten grad' }[$Level]
    $markdown = "**NSM-vurdering: $name.** $Summary"
    if ($Scope) { $markdown += "`n`n*Gjelder: $Scope.*" }
    if ($Details) { $markdown += "`n`n$Details" }
    Add-MtTestResultDetail -Result $markdown
    return $Level -eq 'H'
}

function Get-MtNsmShareLevel {
    <#
    .SYNOPSIS
    Turns a share (0 to 1) into H, M or L against two thresholds.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)] [double] $Share,
        [Parameter(Mandatory)] [double] $High,
        [Parameter(Mandatory)] [double] $Moderate
    )

    if ($Share -ge $High) { 'H' } elseif ($Share -ge $Moderate) { 'M' } else { 'L' }
}

function Format-MtNsmPercent {
    <#
    .SYNOPSIS
    Formats a share (0 to 1) as a whole percent, the Norwegian way: "71 %".

    .DESCRIPTION
    Rounds down, so that a share just under a 100 % threshold never reads as "100 %".
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param([Parameter(Mandatory)] [double] $Share)

    '{0} %' -f [math]::Floor($Share * 100)
}

function Format-MtNsmCount {
    <#
    .SYNOPSIS
    Writes a count with the noun phrase in singular or plural: "1 policy", "2 policyer".
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory, Position = 0)] [int] $Count,
        [Parameter(Mandatory, Position = 1)] [string] $One,
        [Parameter(Mandatory, Position = 2)] [string] $Many
    )

    '{0} {1}' -f $Count, $(if ($Count -eq 1) { $One } else { $Many })
}

function ConvertTo-MtNsmTable {
    <#
    .SYNOPSIS
    Writes objects as a markdown table with the given columns.

    .DESCRIPTION
    The values come from the tenant, and some are set by ordinary users (device names), so every markdown character
    is escaped: a value cannot add links, emphasis or HTML to the report. Columns named in -Code are shown as code
    instead, with backticks removed from the value.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)] [AllowEmptyCollection()] [object[]] $InputObject,
        [Parameter(Mandatory)] [string[]] $Property,
        [Parameter()] [string[]] $Code = @()
    )

    if ($InputObject.Count -eq 0) { return '' }
    # Parenthesised: the comma binds tighter than +, which would join the header and the separator into one line.
    $lines = @(('| ' + ($Property -join ' | ') + ' |'), ('|' + (' --- |' * $Property.Count)))
    foreach ($row in $InputObject) {
        $cells = foreach ($p in $Property) {
            $value = ([string]$row.$p) -replace "`r?`n", ' '
            if ($p -in $Code) { '`' + ($value -replace '`', "'" -replace '\|', '\|') + '`' }
            else { $value -replace '([\\`*_\[\]<>|])', '\$1' }
        }
        $lines += '| ' + ($cells -join ' | ') + ' |'
    }
    $lines -join "`n"
}

function Test-MtNsmAccessDenied {
    <#
    .SYNOPSIS
    Returns true when a Graph error is 401 or 403: the connection lacks a permission or role.

    .DESCRIPTION
    Tests catch only this case and skip with NotAuthorized; any other error is thrown again, so that Maester
    reports it as an error instead of the test guessing a level.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param([Parameter(Mandatory)] [System.Management.Automation.ErrorRecord] $ErrorRecord)

    $response = if ($ErrorRecord.Exception.PSObject.Properties['Response']) { $ErrorRecord.Exception.Response }
    [bool]($response -and [int]$response.StatusCode -in 401, 403)
}

function Get-MtNsmEmergencyAccess {
    <#
    .SYNOPSIS
    Returns the IDs and user principal names of the emergency access accounts in the Maester config, and of the
    members of emergency access groups.

    .DESCRIPTION
    Reads the EmergencyAccessAccounts global setting, which the built-in Maester checks also use. Entries carry
    Id, UserPrincipalName or both, and Type user (the default) or group. A user given only by its user
    principal name is looked up, because Conditional Access exclusions and role assignments hold object IDs.
    A group's transitive members are added, so that its members are left out of the counts of users. An entry
    that cannot be looked up gives a warning and is used as written.
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param()

    $entries = @(Get-MtSetting -Name EmergencyAccessAccounts -Default @())
    $values = [System.Collections.Generic.List[string]]::new()
    foreach ($entry in $entries) {
        $type = if ($entry.Type) { ([string]$entry.Type).ToLowerInvariant() } else { 'user' }
        if ($entry.Id) { $values.Add([string]$entry.Id) }
        if ($entry.UserPrincipalName) { $values.Add([string]$entry.UserPrincipalName) }
        try {
            if ($type -eq 'user' -and -not $entry.Id -and $entry.UserPrincipalName) {
                $user = Invoke-MtGraphRequest -RelativeUri "users/$([uri]::EscapeDataString([string]$entry.UserPrincipalName))" -Select 'id' -ApiVersion v1.0
                if ($user.id) { $values.Add([string]$user.id) }
            } elseif ($type -eq 'group' -and $entry.Id) {
                $members = @(Invoke-MtGraphRequest -RelativeUri "groups/$([uri]::EscapeDataString([string]$entry.Id))/transitiveMembers" -Select 'id,userPrincipalName' -ApiVersion v1.0)
                foreach ($m in $members) {
                    if ($m.id) { $values.Add([string]$m.id) }
                    if ($m.userPrincipalName) { $values.Add([string]$m.userPrincipalName) }
                }
            }
        } catch {
            Write-Warning "Could not look up the emergency access entry '$($entry.Id)$($entry.UserPrincipalName)': $($_.Exception.Message)"
        }
    }
    @($values | Select-Object -Unique)
}

function Get-MtNsmPrivilegedRole {
    <#
    .SYNOPSIS
    Returns the directory roles that Entra marks as privileged, with id, templateId and displayName.
    #>
    [CmdletBinding()]
    [OutputType([object[]])]
    param()

    @(Invoke-MtGraphRequest -RelativeUri 'roleManagement/directory/roleDefinitions' -Filter 'isPrivileged eq true' -Select 'id,templateId,displayName' -ApiVersion v1.0)
}

function Get-MtNsmPrivilegedRoleId {
    <#
    .SYNOPSIS
    Returns the IDs and template IDs of the directory roles that Entra marks as privileged.
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param()

    $roles = Get-MtNsmPrivilegedRole
    @($roles.id) + @($roles.templateId) | Where-Object { $_ } | Select-Object -Unique
}

function Test-MtNsmAssigned {
    <#
    .SYNOPSIS
    Returns true when an Intune assignment list includes at least one target, not only exclusions.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param([Parameter()] [AllowNull()] [AllowEmptyCollection()] [object[]] $Assignments)

    [bool](@($Assignments | Where-Object { $_.target.'@odata.type' -and $_.target.'@odata.type' -ne '#microsoft.graph.exclusionGroupAssignmentTarget' }).Count)
}

function Test-MtNsmAllDevicesAssignment {
    <#
    .SYNOPSIS
    Returns true when an Intune assignment list targets all devices or all users.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param([Parameter()] [AllowNull()] [AllowEmptyCollection()] [object[]] $Assignments)

    $types = @($Assignments | ForEach-Object { $_.target.'@odata.type' })
    ($types -contains '#microsoft.graph.allDevicesAssignmentTarget') -or ($types -contains '#microsoft.graph.allLicensedUsersAssignmentTarget')
}

function Get-MtNsmPhishingResistantStrengthId {
    <#
    .SYNOPSIS
    Returns the IDs of the authentication strengths that only allow phishing-resistant methods.

    .DESCRIPTION
    The built-in "Phishing-resistant MFA" strength counts, and so does any custom strength whose combinations
    are all FIDO2/passkey, Windows Hello for Business or certificate-based multifactor authentication.
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param()

    $allowed = @('fido2', 'windowsHelloForBusiness', 'x509CertificateMultiFactor')
    $strengths = @(Invoke-MtGraphRequest -RelativeUri 'policies/authenticationStrengthPolicies' -ApiVersion v1.0)
    @(foreach ($s in $strengths) {
        $combinations = @($s.allowedCombinations)
        if ($combinations.Count -gt 0 -and @($combinations | Where-Object { $_ -notin $allowed }).Count -eq 0) { $s.id }
    })
}

function Test-MtNsmPhishingResistantMethod {
    <#
    .SYNOPSIS
    Returns true when a list of registered methods (methodsRegistered in the registration report) includes a
    phishing-resistant one: a FIDO2 security key or passkey, Windows Hello for Business or a macOS platform
    credential.

    .DESCRIPTION
    Certificate-based authentication is phishing-resistant too, but the registration report does not show it.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param([Parameter()] [AllowNull()] [AllowEmptyCollection()] [object[]] $Methods)

    [bool](@($Methods | Where-Object { $_ -match '^(fido2|passKey|windowsHelloForBusiness|macOsSecureEnclaveKey)' }).Count)
}

function Get-MtNsmCaScope {
    <#
    .SYNOPSIS
    Describes who and what a Conditional Access policy covers: all users, all apps, how many exceptions it has,
    and which conditions narrow it.

    .DESCRIPTION
    Exceptions are excluded users and groups (other than the emergency access accounts), excluded roles,
    excluded guests or external users, and excluded apps. Narrowing conditions are locations, platforms, client
    app types, user or sign-in risk, and device filters: a policy with one of them does not apply everywhere.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)] [object] $Policy,
        [Parameter()] [AllowNull()] [AllowEmptyCollection()] [string[]] $Excluded = @()
    )

    $c = $Policy.conditions
    $u = $c.users
    $exceptions = @(@($u.excludeUsers) + @($u.excludeGroups) | Where-Object { $_ -and $_ -notin $Excluded }).Count +
        @($u.excludeRoles | Where-Object { $_ }).Count +
        @($c.applications.excludeApplications | Where-Object { $_ }).Count +
        $(if ($u.excludeGuestsOrExternalUsers) { 1 } else { 0 })

    $narrowing = @(
        if ($c.locations -and (@($c.locations.includeLocations) -notcontains 'All' -or @($c.locations.excludeLocations | Where-Object { $_ }).Count)) { 'locations' }
        if ($c.platforms -and (@($c.platforms.includePlatforms) -notcontains 'all' -or @($c.platforms.excludePlatforms | Where-Object { $_ }).Count)) { 'device platforms' }
        if (@($c.clientAppTypes | Where-Object { $_ }).Count -and @($c.clientAppTypes) -notcontains 'all') { 'client apps' }
        if (@($c.userRiskLevels | Where-Object { $_ }).Count -or @($c.signInRiskLevels | Where-Object { $_ }).Count) { 'risk' }
        if ($c.devices.deviceFilter.rule) { 'filter for devices' }
    )

    [pscustomobject]@{
        AllUsers   = @($u.includeUsers) -contains 'All'
        AllApps    = @($c.applications.includeApplications) -contains 'All'
        Exceptions = $exceptions
        Narrowing  = $narrowing
    }
}

function Test-MtNsmCaRequiresMfa {
    <#
    .SYNOPSIS
    Returns true when a Conditional Access policy's grant controls always require MFA.

    .DESCRIPTION
    MFA is required when the policy asks for MFA or an authentication strength, and either that is its only
    control or the controls are joined with AND. "MFA or a compliant device" does not require MFA. With
    -StrengthId, only those authentication strengths count, and the MFA control alone does not.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)] [object] $Policy,
        [Parameter()] [string[]] $StrengthId
    )

    $grant = $Policy.grantControls
    if (-not $grant) { return $false }
    $controls = @($grant.builtInControls | Where-Object { $_ })
    $strength = $grant.authenticationStrength.id
    $mfa = if ($PSBoundParameters.ContainsKey('StrengthId')) { [bool]$strength -and $strength -in $StrengthId } else { ($controls -contains 'mfa') -or [bool]$strength }
    $count = $controls.Count + $(if ($strength) { 1 } else { 0 })
    $mfa -and ($count -eq 1 -or $grant.operator -eq 'AND')
}

function Get-MtNsmWindowsDevice {
    <#
    .SYNOPSIS
    Returns the Windows devices that Intune manages, with the properties the device checks use.

    .DESCRIPTION
    One request with the same properties for every device check, so that Maester's request cache reads the
    devices once per run.
    #>
    [CmdletBinding()]
    [OutputType([object[]])]
    param()

    @(Invoke-MtGraphRequest -RelativeUri 'deviceManagement/managedDevices' -Filter "operatingSystem eq 'Windows'" `
            -Select 'id,deviceName,osVersion,lastSyncDateTime,complianceState,isEncrypted,managementAgent' -ApiVersion v1.0)
}

function Get-MtNsmSecureScore {
    <#
    .SYNOPSIS
    Returns the newest Microsoft Secure Score, or nothing when the tenant has none.

    .DESCRIPTION
    One request for every check that reads Secure Score recommendations, so that Maester's request cache reads it
    once per run. Throws on Graph errors: the caller skips on 401 and 403 with Test-MtNsmAccessDenied.
    #>
    [CmdletBinding()]
    [OutputType([object])]
    param()

    # With -DisablePaging the raw response comes back, so the newest score is the first entry of value.
    @((Invoke-MtGraphRequest -RelativeUri 'security/secureScores' -QueryParameters @{ '$top' = 1 } -DisablePaging -ApiVersion v1.0).value)[0]
}

function Get-MtNsmDeviceRegistrationPolicy {
    <#
    .SYNOPSIS
    Returns the tenant's device registration policy (Entra ID > Devices > Device settings).

    .DESCRIPTION
    Holds who becomes local administrator on Entra joined devices and whether Windows LAPS is turned on for the
    tenant. Throws on Graph errors: the caller skips on 401 and 403 with Test-MtNsmAccessDenied.
    #>
    [CmdletBinding()]
    [OutputType([object])]
    param()

    Invoke-MtGraphRequest -RelativeUri 'policies/deviceRegistrationPolicy' -ApiVersion v1.0
}

function Get-MtNsmEndpointPolicy {
    <#
    .SYNOPSIS
    Returns the assigned Intune endpoint security policies of one kind, with who they are assigned to.

    .DESCRIPTION
    Kinds: Asr (attack surface reduction rules), Antivirus, Firewall and Baseline (an Intune security baseline, or
    a settings catalog policy whose name matches the NsmGpIkt.BaselinePolicyPattern setting, by default CIS or
    baseline). Both current policies (configurationPolicies) and older ones (intents) count. Antivirus exclusions
    and firewall rules alone do not count, and neither does a policy assigned to exclusion groups only.
    Each row has Policy, Type and Tildelt: "Alle enheter" (all devices or all users) or "Grupper".
    #>
    [CmdletBinding()]
    [OutputType([object[]])]
    param([Parameter(Mandatory)] [ValidateSet('Asr', 'Antivirus', 'Firewall', 'Baseline')] [string] $Kind)

    $assigned = @(Invoke-MtGraphRequest -RelativeUri "deviceManagement/configurationPolicies?`$expand=assignments" -ApiVersion beta | Where-Object { Test-MtNsmAssigned $_.assignments })
    $current = switch ($Kind) {
        'Asr'       { $assigned | Where-Object { $_.templateReference.templateFamily -eq 'endpointSecurityAttackSurfaceReduction' -and $_.templateReference.templateDisplayName -like '*Attack Surface Reduction*' } }
        'Antivirus' { $assigned | Where-Object { $_.templateReference.templateFamily -eq 'endpointSecurityAntivirus' -and $_.templateReference.templateDisplayName -notmatch '(?i)exclusion|experience' } }
        'Firewall'  { $assigned | Where-Object { $_.templateReference.templateFamily -eq 'endpointSecurityFirewall' -and $_.templateReference.templateDisplayName -notmatch '(?i)rule' } }
        'Baseline'  {
            $pattern = [string](Get-MtSetting -Name 'NsmGpIkt.BaselinePolicyPattern' -Default '(?i)\bCIS\b|baseline')
            # A timeout, so a pattern that backtracks without end cannot hang the run.
            $regex = [regex]::new($pattern, [System.Text.RegularExpressions.RegexOptions]::None, [timespan]::FromSeconds(1))
            $assigned | Where-Object { $_.templateReference.templateFamily -eq 'baseline' -or $regex.IsMatch([string]$_.name) }
        }
    }
    $rows = @($current | ForEach-Object {
        [pscustomobject]@{ Policy = $_.name; Type = 'Endpoint security'; Tildelt = if (Test-MtNsmAllDevicesAssignment $_.assignments) { 'Alle enheter' } else { 'Grupper' } }
    })

    # Older endpoint security policies and security baselines are intents. Their template says what they are.
    $baselineTypes = 'securityBaseline', 'advancedThreatProtectionSecurityBaseline', 'microsoftEdgeSecurityBaseline', 'microsoftOffice365ProPlusSecurityBaseline'
    $wanted = @{ Asr = 'attackSurfaceReduction'; Antivirus = 'antivirus'; Firewall = 'firewall'; Baseline = 'baseline' }[$Kind]
    $kindOf = @{}
    foreach ($t in Invoke-MtGraphRequest -RelativeUri 'deviceManagement/templates' -Select 'id,templateType,templateSubtype' -ApiVersion beta) {
        $kindOf[[string]$t.id] = if ($t.templateType -in $baselineTypes) { 'baseline' } else { [string]$t.templateSubtype }
    }
    $intents = @(Invoke-MtGraphRequest -RelativeUri 'deviceManagement/intents' -Select 'id,displayName,isAssigned,templateId' -ApiVersion beta |
        Where-Object { $_.isAssigned -and $kindOf[[string]$_.templateId] -eq $wanted })
    foreach ($i in $intents) {
        $assignments = @(Invoke-MtGraphRequest -RelativeUri "deviceManagement/intents/$($i.id)/assignments" -ApiVersion beta)
        if (-not (Test-MtNsmAssigned $assignments)) { continue }
        $rows += [pscustomobject]@{ Policy = $i.displayName; Type = 'Endpoint security (intent)'; Tildelt = if (Test-MtNsmAllDevicesAssignment $assignments) { 'Alle enheter' } else { 'Grupper' } }
    }
    @($rows)
}

function Get-MtNsmAssignmentLevel {
    <#
    .SYNOPSIS
    Turns rows from Get-MtNsmEndpointPolicy into H, M or L: assigned to all devices, to groups only, or not at all.

    .DESCRIPTION
    An assigned policy shows that the setting is managed centrally, not that it is in force on every device. The
    checks that use this are therefore partial evidence (delvis) in the mapping.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param([Parameter()] [AllowNull()] [AllowEmptyCollection()] [object[]] $Rows)

    if (@($Rows | Where-Object Tildelt -EQ 'Alle enheter').Count) { 'H' } elseif (@($Rows).Count) { 'M' } else { 'L' }
}
