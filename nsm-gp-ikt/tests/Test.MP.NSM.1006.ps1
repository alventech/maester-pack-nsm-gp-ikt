function Test-MtNsmPermanentPrivilegedAssignment {
    <#
    .SYNOPSIS
    Counts permanent, active assignments of privileged directory roles.

    .DESCRIPTION
    Høy grad: no more than two principals beyond the emergency access accounts. Moderat grad: three to five.
    Liten grad: more. Uses PIM schedule instances when the tenant has them, else role assignments.
    #>
    [MaesterTest(
        Id = 'MP.NSM.1006',
        Title = 'Privilegerte roller er ikke tildelt permanent',
        Product = 'entra',
        Feature = 'privileged-identity-management',
        Area = 'privileged-access',
        ResourceType = 'DirectoryRole',
        Severity = 'High',
        UserImpact = 'Low',
        ImplementationCost = 'Medium',
        Control = ('nsm-gp-ikt:2.6.5'),
        Mitre = 'T1098.003',
        Service = 'Graph',
        Permission = ('Graph:Scope:RoleManagement.Read.Directory', 'Graph:Scope:Directory.Read.All'),
        Tag = ('NSM', 'NSM-Identitet'),
        Author = 'alventech'
    )]
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    $nsmScope = 'Katalogroller i Entra ID'

    $roles = Get-MtNsmPrivilegedRole
    $privileged = @(@($roles.id) + @($roles.templateId) | Where-Object { $_ })
    $roleName = @{}
    foreach ($r in $roles) {
        $roleName[[string]$r.id] = $r.displayName
        if ($r.templateId) { $roleName[[string]$r.templateId] = $r.displayName }
    }
    $excluded = Get-MtNsmEmergencyAccess
    try {
        $assignments = @(Invoke-MtGraphRequest -RelativeUri "roleManagement/directory/roleAssignmentScheduleInstances?`$expand=principal" -ApiVersion v1.0 |
            Where-Object { $_.assignmentType -eq 'Assigned' -and -not $_.endDateTime })
    } catch {
        if ($_.Exception.Message -notmatch 'AadPremiumLicenseRequired') {
            if (Test-MtNsmAccessDenied $_) { Add-MtTestResultDetail -SkippedBecause NotAuthorized; return $null }
            throw
        }
        # Without Entra ID P2 there is no PIM, so every active assignment is permanent.
        $assignments = @(Invoke-MtGraphRequest -RelativeUri "roleManagement/directory/roleAssignments?`$expand=principal" -ApiVersion v1.0)
    }
    $permanent = @($assignments | Where-Object {
        $_.roleDefinitionId -in $privileged -and $_.principalId -notin $excluded -and $_.principal.userPrincipalName -notin $excluded
    })

    $rows = $permanent | Group-Object principalId | ForEach-Object {
        $p = $_.Group[0].principal
        [pscustomobject]@{
            Konto  = if ($p.userPrincipalName) { $p.userPrincipalName } else { $p.displayName }
            Type   = ($p.'@odata.type' -replace '#microsoft.graph.', '')
            Roller = (@($_.Group | ForEach-Object { $roleName[[string]$_.roleDefinitionId] }) | Sort-Object -Unique) -join ', '
        }
    }
    $rows = @($rows)
    $level = if ($rows.Count -le 2) { 'H' } elseif ($rows.Count -le 5) { 'M' } else { 'L' }
    Complete-MtNsmResult -Scope $nsmScope -Level $level -Summary "$(Format-MtNsmCount $rows.Count konto kontoer) har en privilegert rolle permanent, utenom nødtilgangskontoene." `
        -Details (ConvertTo-MtNsmTable -InputObject $rows -Property Konto, Type, Roller)
}
