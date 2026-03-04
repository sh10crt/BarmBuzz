Configuration StudentBaseline {

    param(
        [Parameter(Mandatory = $true)]
        [PSCredential]$DomainAdminCredential,

        [Parameter(Mandatory = $true)]
        [PSCredential]$DsrmCredential,

        [Parameter(Mandatory = $true)]
        [PSCredential]$UserCredential
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName ComputerManagementDSC
    Import-DscResource -ModuleName ActiveDirectoryDSC
    Import-DscResource -ModuleName NetworkingDSC

    foreach ($Node in $AllNodes) {
        Node $Node.NodeName {

            # -----------------------
            # COMPUTER CONFIG
            # -----------------------

            Computer SetName {
                Name = if ($Node.PSObject.Properties['ComputerName']) { $Node.ComputerName } else { $Node.NodeName }
            }

            TimeZone SetTimeZone {
                IsSingleInstance = 'Yes'
                TimeZone         = if ($Node.PSObject.Properties['TimeZone']) { $Node.TimeZone } else { 'GMT Standard Time' }
            }

            Service WindowsTime {
                Name        = 'W32Time'
                State       = 'Running'
                StartupType = 'Automatic'
                DependsOn   = '[TimeZone]SetTimeZone'
            }

            # -----------------------
            # NETWORK
            # -----------------------

            if ($Node.PSObject.Properties['InterfaceAlias_Internal'] -and $Node.PSObject.Properties['IPv4Address_Internal']) {
                IPAddress SetInternalIP {
                    InterfaceAlias = $Node.InterfaceAlias_Internal
                    AddressFamily  = 'IPv4'
                    IPAddress      = $Node.IPv4Address_Internal
                    DependsOn      = '[Computer]SetName'
                }

                DnsServerAddress SetInternalDNS {
                    InterfaceAlias = $Node.InterfaceAlias_Internal
                    AddressFamily  = 'IPv4'
                    Address        = if ($Node.PSObject.Properties['DNSServers_Internal']) { $Node.DNSServers_Internal } else { @() }
                    DependsOn      = '[IPAddress]SetInternalIP'
                }
            }

            if ($Node.PSObject.Properties['InterfaceAlias_NAT']) {
                DnsConnectionSuffix DisableNatDnsRegistration {
                    InterfaceAlias               = $Node.InterfaceAlias_NAT
                    ConnectionSpecificSuffix     = ''
                    RegisterThisConnectionsAddress = $false
                    DependsOn                    = '[DnsServerAddress]SetInternalDNS'
                }
            }

            # -----------------------
            # AD DS INSTALL
            # -----------------------

            if ($Node.Role -eq 'DC') {

                WindowsFeature ADDS {
                    Name   = 'AD-Domain-Services'
                    Ensure = 'Present'
                }

                WindowsFeature RSAT_ADDS {
                    Name      = 'RSAT-AD-Tools'
                    Ensure    = 'Present'
                    DependsOn = '[WindowsFeature]ADDS'
                }

                ADDomain CreateForest {
                    DomainName                   = $Node.DomainName
                    DomainNetBIOSName            = $Node.DomainNetBIOSName
                    Credential                   = $DomainAdminCredential
                    SafeModeAdministratorPassword= $DsrmCredential
                    ForestMode                   = if ($Node.PSObject.Properties['ForestMode']) { $Node.ForestMode } else { 'WinThreshold' }
                    DomainMode                   = if ($Node.PSObject.Properties['DomainMode']) { $Node.DomainMode } else { 'WinThreshold' }
                    DependsOn                    = '[WindowsFeature]RSAT_ADDS'
                }

                WaitForADDomain WaitForDomain {
                    DomainName = $Node.DomainName
                    Credential = $DomainAdminCredential
                    DependsOn  = '[ADDomain]CreateForest'
                }

                # -----------------------
                # ORGANIZATIONAL UNITS
                # -----------------------
                if ($Node.PSObject.Properties['OrganizationalUnits']) {
                    foreach ($ou in $Node.OrganizationalUnits) {
                        $ouPath = if ($ou.ParentPath) { "$($ou.ParentPath),$($Node.DomainDN)" } else { $Node.DomainDN }
                        $ouDepends = if ($ou.DependsOnKey) { "[ADOrganizationalUnit]OU_$($ou.DependsOnKey)" } else { '[WaitForADDomain]WaitForDomain' }

                        ADOrganizationalUnit "OU_$($ou.Key)" {
                            Name = $ou.Name
                            Path = $ouPath
                            Description = if ($ou.PSObject.Properties['Description']) { $ou.Description } else { "" }
                            ProtectedFromAccidentalDeletion = if ($ou.PSObject.Properties['Protected']) { $ou.Protected } else { $false }
                            Ensure = 'Present'
                            Credential = $DomainAdminCredential
                            DependsOn = $ouDepends
                        }
                    }
                }

                # -----------------------
                # SECURITY GROUPS
                # -----------------------
                if ($Node.PSObject.Properties['SecurityGroups']) {
                    foreach ($group in $Node.SecurityGroups) {
                        $groupPath = "$($group.OUPath),$($Node.DomainDN)"
                        $deps = @("[ADOrganizationalUnit]OU_$($group.DependsOnOUKey)")

                        if ($group.PSObject.Properties['MembersToInclude']) {
                            foreach ($memberName in $group.MembersToInclude) {
                                $memberGrp = $Node.SecurityGroups | Where-Object { $_.GroupName -eq $memberName }
                                if ($memberGrp) { $deps += "[ADGroup]Group_$($memberGrp.Key)" }
                            }
                        }

                        ADGroup "Group_$($group.Key)" {
                            GroupName        = $group.GroupName
                            GroupScope       = $group.GroupScope
                            Category         = $group.Category
                            Path             = $groupPath
                            Description      = if ($group.PSObject.Properties['Description']) { $group.Description } else { "" }
                            MembersToInclude = if ($group.PSObject.Properties['MembersToInclude']) { $group.MembersToInclude } else { @() }
                            Ensure           = 'Present'
                            Credential       = $DomainAdminCredential
                            DependsOn        = $deps
                        }
                    }
                }

                # -----------------------
                # AD USERS
                # -----------------------
                if ($Node.PSObject.Properties['ADUsers']) {
                    foreach ($user in $Node.ADUsers) {
                        $userPath = "$($user.OUPath),$($Node.DomainDN)"
                        ADUser "User_$($user.Key)" {
                            DomainName            = $Node.DomainName
                            UserName              = $user.UserName
                            GivenName             = $user.GivenName
                            Surname               = $user.Surname
                            DisplayName           = $user.DisplayName
                            UserPrincipalName     = $user.UserPrincipalName
                            Path                  = $userPath
                            JobTitle              = if ($user.PSObject.Properties['JobTitle']) { $user.JobTitle } else { "" }
                            Department            = if ($user.PSObject.Properties['Department']) { $user.Department } else { "" }
                            Description           = if ($user.PSObject.Properties['Description']) { $user.Description } else { "" }
                            Password              = $UserCredential
                            PasswordNeverResets   = $true
                            ChangePasswordAtLogon = if ($user.PSObject.Properties['ChangePasswordAtLogon']) { $user.ChangePasswordAtLogon } else { $false }
                            Enabled               = $true
                            Ensure                = 'Present'
                            Credential            = $DomainAdminCredential
                            DependsOn             = "[ADOrganizationalUnit]OU_$($user.DependsOnOUKey)"
                        }
                    }
                }

                # -----------------------
                # PASSWORD POLICY
                # -----------------------
                if ($Node.PSObject.Properties['PasswordPolicy']) {
                    ADDomainDefaultPasswordPolicy SetPasswordPolicy {
                        DomainName                  = $Node.DomainName
                        ComplexityEnabled           = $Node.PasswordPolicy.ComplexityEnabled
                        MinPasswordLength           = $Node.PasswordPolicy.MinPasswordLength
                        PasswordHistoryCount        = $Node.PasswordPolicy.PasswordHistoryCount
                        MaxPasswordAge              = $Node.PasswordPolicy.MaxPasswordAge
                        MinPasswordAge              = $Node.PasswordPolicy.MinPasswordAge
                        LockoutThreshold            = $Node.PasswordPolicy.LockoutThreshold
                        LockoutDuration             = $Node.PasswordPolicy.LockoutDuration
                        LockoutObservationWindow    = $Node.PasswordPolicy.LockoutObservationWindow
                        ReversibleEncryptionEnabled = $Node.PasswordPolicy.ReversibleEncryptionEnabled
                        Credential                  = $DomainAdminCredential
                        DependsOn                   = '[WaitForADDomain]WaitForDomain'
                    }
                }
            } # End DC role
        } # End Node
    } # End foreach
} # End Configuration