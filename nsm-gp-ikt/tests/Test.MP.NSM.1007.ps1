function Test-MtNsmPimActivationApproval {
    <#
    .SYNOPSIS
    Checks that privileged roles are eligible in PIM and that Global Administrator activation needs approval.

    .DESCRIPTION
    Høy grad: privileged roles have eligible assignments, and activating Global Administrator requires approval
    and MFA. Moderat grad: eligible assignments exist, but activation needs no approval. Liten grad: PIM is not
    used for privileged roles.
    #>
    [MaesterTest(
        Id = 'MP.NSM.1007',
        Title = 'Privilegerte roller aktiveres i PIM med godkjenning',
        Product = 'entra',
        Feature = 'privileged-identity-management',
        Area = 'privileged-access',
        ResourceType = 'DirectoryRole',
        Severity = 'High',
        UserImpact = 'Low',
        ImplementationCost = 'Medium',
        Control = ('nsm-gp-ikt:2.6.1', 'nsm-gp-ikt:2.6.5'),
        Mitre = ('T1098.003', 'T1548.005'),
        Service = 'Graph',
        License = ('AAD_PREMIUM_P2', 'Entra_Identity_Governance'),
        Permission = ('Graph:Scope:RoleManagement.Read.Directory', 'Graph:Scope:RoleManagementPolicy.Read.Directory'),
        Tag = ('NSM', 'NSM-Identitet'),
        Author = 'alventech'
    )]
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    $nsmScope = 'Katalogroller i Entra ID'

    $globalAdmin = '62e90394-69f5-4237-9190-012177145e10'
    $privileged = Get-MtNsmPrivilegedRoleId
    try {
        $eligible = @(Invoke-MtGraphRequest -RelativeUri "roleManagement/directory/roleEligibilityScheduleInstances?`$expand=roleDefinition" -ApiVersion v1.0 |
            Where-Object { $_.roleDefinitionId -in $privileged })
        $assignment = @(Invoke-MtGraphRequest -RelativeUri 'policies/roleManagementPolicyAssignments' -Filter "scopeId eq '/' and scopeType eq 'DirectoryRole' and roleDefinitionId eq '$globalAdmin'" -QueryParameters @{ '$expand' = 'policy($expand=rules)' } -ApiVersion v1.0)[0]
    } catch {
        # Usually RoleManagementPolicy.Read.Directory, which Connect-Maester does not ask for.
        if (Test-MtNsmAccessDenied $_) { Add-MtTestResultDetail -SkippedBecause NotAuthorized; return $null }
        throw
    }
    $rules = @($assignment.policy.rules)
    $approval = [bool]($rules | Where-Object id -EQ 'Approval_EndUser_Assignment').setting.isApprovalRequired
    $mfa = @(($rules | Where-Object id -EQ 'Enablement_EndUser_Assignment').enabledRules) -contains 'MultiFactorAuthentication'
    $context = $rules | Where-Object id -EQ 'AuthenticationContext_EndUser_Assignment'
    $authContext = [bool]$context.isEnabled -and [bool]$context.claimValue
    $strong = $mfa -or $authContext
    $how = if ($authContext) { 'authentication context kreves' } elseif ($mfa) { 'MFA kreves' } else { 'verken MFA eller authentication context kreves' }
    $setup = "Aktivering av Global Administrator: godkjenning $(if ($approval) { 'kreves' } else { 'kreves ikke' }), $how."

    $rows = $eligible | Group-Object { $_.roleDefinition.displayName } | ForEach-Object { [pscustomobject]@{ Rolle = $_.Name; Eligible = $_.Count } }
    if (-not $eligible) {
        $level = 'L'; $summary = "Ingen privilegerte roller er eligible i PIM. $setup"
    } elseif ($approval -and $strong) {
        $level = 'H'; $summary = "$($eligible.Count) eligible-tildelinger av privilegerte roller. $setup"
    } else {
        $level = 'M'; $summary = "$($eligible.Count) eligible-tildelinger, men aktiveringen er ikke strengt nok satt opp. $setup"
    }
    Complete-MtNsmResult -Scope $nsmScope -Level $level -Summary $summary -Details (ConvertTo-MtNsmTable -InputObject @($rows) -Property Rolle, Eligible)
}
