<#
STUDENT TASK:
- Define Configuration StudentBaseline
- Use ConfigurationData (AllNodes.psd1)
- DO NOT hardcode passwords here.
#>

Configuration StudentBaseline {

    param(
        [Parameter(Mandatory = $true)]
        [PSCredential] $DomainAdminCredential,

        [Parameter(Mandatory = $true)]
        [PSCredential] $DsrmCredential,

        [Parameter(Mandatory = $true)]
        [PSCredential] $UserCredential
    )

    # =======================
    # IMPORT DSC MODULES
    # =======================
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName ComputerManagementDSC
    Import-DscResource -ModuleName ActiveDirectoryDsc
    Import-DscResource -ModuleName NetworkingDsc
    # Note: GroupPolicyDsc removed for PowerShell 7 compatibility

    # =======================
    # DEFINE NODE ARRAYS
    # =======================
    $DCNodes        = $AllNodes | Where-Object { $_.Role -eq 'DC' } | Select-Object -ExpandProperty NodeName
    $WinClientNodes = $AllNodes | Where-Object { $_.Role -eq 'WinClient' } | Select-Object -ExpandProperty NodeName

    # =========================
    # DOMAIN CONTROLLER NODE(S)
    # =========================
    Node $DCNodes {

        # Computer name
        Computer SetComputerName {
            Name = $Node.ComputerName
        }

        # Time zone
        TimeZone SetTimeZone {
            IsSingleInstance = 'Yes'
            TimeZone         = $Node.TimeZone
        }

        Service WindowsTime {
            Name        = 'W32Time'
            State       = 'Running'
            StartupType = 'Automatic'
            DependsOn   = '[TimeZone]SetTimeZone'
        }

        # Network (Internal)
        IPAddress SetInternalIP {
            InterfaceAlias = $Node.InterfaceAlias_Internal
            AddressFamily  = 'IPv4'
            IPAddress      = $Node.IPAddress_Internal
            DependsOn      = '[Computer]SetComputerName'
        }

        DnsServerAddress SetInternalDns {
            InterfaceAlias = $Node.InterfaceAlias_Internal
            AddressFamily  = 'IPv4'
            Address        = $Node.DNSServers_Internal
            DependsOn      = '[IPAddress]SetInternalIP'
        }

        # Network (NAT)
        DnsConnectionSuffix DisableDnsRegistration {
            InterfaceAlias                 = $Node.InterfaceAlias_NAT
            ConnectionSpecificSuffix       = 'barmbuzz.corp'
            RegisterThisConnectionsAddress = $false
            DependsOn                      = '[DnsServerAddress]SetInternalDns'
        }

        # Install AD DS + RSAT
        WindowsFeature ADDS {
            Name   = 'AD-Domain-Services'
            Ensure = 'Present'
        }

        WindowsFeature RSATADDS {
            Name      = 'RSAT-AD-Tools'
            Ensure    = 'Present'
            DependsOn = '[WindowsFeature]ADDS'
        }

        # Create forest / promote DC
        ADDomain CreateForest {
            DomainName                    = $Node.DomainName
            DomainNetBIOSName             = $Node.DomainNetbiosName
            Credential                    = $DomainAdminCredential
            SafeModeAdministratorPassword = $DsrmCredential
            ForestMode                    = $Node.ForestMode
            DomainMode                    = $Node.DomainMode
            DependsOn                     = '[WindowsFeature]RSATADDS'
        }

        WaitForADDomain WaitForBarmBuzz {
            DomainName = $Node.DomainName
            Credential = $DomainAdminCredential
            DependsOn  = '[ADDomain]CreateForest'
        }

        # ----------------------
        # ORGANIZATIONAL UNITS
        # ----------------------
        foreach ($ou in $Node.OrgnizationalUnits) {
            $ouPath = if ([string]::IsNullOrWhiteSpace($ou.ParentPath)) {
                $Node.DomainDN
            } else {
                "$($ou.ParentPath),$($Node.DomainDN)"
            }

            $ouDep = if ([string]::IsNullOrWhiteSpace($ou.DependsOnKey)) {
                '[WaitForADDomain]WaitForBarmBuzz'
            } else {
                "[ADOrganizationalUnit]OU_$($ou.DependsOnKey)"
            }

            ADOrganizationalUnit "OU_$($ou.Key)" {
                Name                            = $ou.Name
                Path                            = $ouPath
                Description                     = $ou.Description
                ProtectedFromAccidentalDeletion = ($ou.Protected -eq 'true')
                Ensure                          = 'Present'
                Credential                      = $DomainAdminCredential
                DependsOn                       = $ouDep
            }
        }

        # ----------------------
        # SECURITY GROUPS
        # ----------------------
        foreach ($grp in $Node.SecurityGroups) {
            $grpPath = "$($grp.OUPath),$($Node.DomainDN)"
            $deps    = @("[ADOrganizationalUnit]OU_$($grp.DependsOnKey)")

            if ($grp.MembersToInclude -and $grp.MembersToInclude.Count -gt 0) {
                foreach ($memberName in $grp.MembersToInclude) {
                    $memberGrp = $Node.SecurityGroups | Where-Object { $_.GroupName -eq $memberName } | Select-Object -First 1
                    if ($memberGrp) {
                        $deps += "[ADGroup]Group_$($memberGrp.Key)"
                    }
                }
            }

            ADGroup "Group_$($grp.Key)" {
                GroupName        = $grp.GroupName
                GroupScope       = $grp.GroupScope
                Category         = $grp.Category
                Description      = $grp.Description
                Path             = $grpPath
                Ensure           = 'Present'
                Credential       = $DomainAdminCredential
                DependsOn        = $deps
                MembersToInclude = $grp.MembersToInclude
            }
        }

        # ----------------------
        # USERS
        # ----------------------
        foreach ($user in $Node.ADUsers) {
            $userPath = "$($user.OUPath),$($Node.DomainDN)"

            ADUser "User_$($user.Key)" {
                DomainName            = $Node.DomainName
                UserName              = $user.UserName
                GivenName             = $user.GivenName
                Surname               = $user.Surname
                DisplayName           = $user.DisplayName
                UserPrincipalName     = $user.UserPrincipalName
                JobTitle              = $user.JobTitle
                Department            = $user.Department
                Description           = $user.Description
                Path                  = $userPath
                Password              = $UserCredential
                PasswordNeverExpires  = $false
                ChangePasswordAtLogon = $true
                Enabled               = $true
                Ensure                = 'Present'
                Credential            = $DomainAdminCredential
                DependsOn             = "[ADOrganizationalUnit]OU_$($user.DependsOnKey)"
            }
        }

        # ----------------------
        # PASSWORD POLICY
        # ----------------------
        ADDomainDefaultPasswordPolicy SetPasswordPolicy {
            DomainName               = $Node.DomainName
            ComplexityEnabled        = ($Node.PasswordPolicy.ComplexityEnabled -eq 'true')
            MinPasswordLength        = $Node.PasswordPolicy.MinimumPasswordLength
            PasswordHistoryCount     = $Node.PasswordPolicy.PasswordHistoryCount
            MaxPasswordAge           = $Node.PasswordPolicy.MaxPasswordAge
            MinPasswordAge           = $Node.PasswordPolicy.MinPasswordAge
            LockoutThreshold         = $Node.PasswordPolicy.LockoutThreshold
            LockoutDuration          = $Node.PasswordPolicy.LockoutDuration
            LockoutObservationWindow = $Node.PasswordPolicy.LockoutObservationWindow
            Credential               = $DomainAdminCredential
            DependsOn                = '[WaitForADDomain]WaitForBarmBuzz'
        }

    }

    # ======================
    # WINDOWS CLIENT NODE(S)
    # ======================
    Node $WinClientNodes {

        TimeZone SetClientTimeZone {
            IsSingleInstance = 'Yes'
            TimeZone         = $Node.TimeZone
        }

        DnsServerAddress SetDnsToDC {
            InterfaceAlias = $Node.InterfaceAlias_Internal
            Address        = $Node.DnsServerAddress
            AddressFamily  = 'IPv4'
        }

        Computer JoinDomain {
            Name       = $Node.ComputerName
            DomainName = $Node.DomainName
            JoinOU     = $Node.JoinOU
            Credential = $DomainAdminCredential
            DependsOn  = '[DnsServerAddress]SetDnsToDC'
        }

        Service WindowsTimeClient {
            Name        = 'W32Time'
            State       = 'Running'
            StartupType = 'Automatic'
        }

        WindowsOptionalFeature DisableSMBv1Client {
            Name                 = 'SMB1Protocol'
            Ensure               = 'Disable'
            NoWindowsUpdateCheck = $true
        }

        Service WindowsFirewall {
            Name        = 'mpsSvc'
            State       = 'Running'
            StartupType = 'Automatic'
        }
    }
}