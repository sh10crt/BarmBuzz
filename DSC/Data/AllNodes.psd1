@{
    AllNodes = @(
        @{
            NodeName   = 'localhost'
            Role       = 'DC'

            DomainName        = 'barmbuzz.corp'
            DomainNetbiosName = 'BARMBUZZ'
            ForestMode        = 'WinThreshold'
            DomainMode        = 'WinThreshold'

            # Computer Settings
            ComputerName  = 'BB-DC01'
            TimeZone      = 'GMT Standard Time'
            EnsureW32Time = 'true'   # must be a literal string in .psd1

            # Network settings - Internal NIC
            InterfaceAlias_Internal = 'Ethernet 2'
            IPAddress_Internal      = '192.168.1.10/24'
            IPv4Address_Internal    = '192.168.1.10'
            PrefixLength_Internal   = 24

            DefaultGateway_Internal = ''              # no $null in psd1
            DNSServers_Internal     = @('127.0.0.1')

            # Network settings - External NIC
            InterfaceAlias_NAT            = 'Ethernet'
            DisableDnsRegistrationOnNat   = 'true'

            # DSC security flags (lab)
            PsDscAllowPlainTextPassword = 'true'
            PsDscAllowDomainUser        = 'true'

            # AD structure
            OrgName   = 'BarmBuzz'
            OrgPrefix = 'BB'
            DomainDN  = 'DC=barmbuzz,DC=corp'

            OrgnizationalUnits = @(
                @{ Key = 'BarmBuzz';              Name = 'BarmBuzz';        ParentPath = '';                              DependsOnKey = '';               Protected = 'true'; Description = 'Root OU for BarmBuzz Corporation, Silcon Bolton HQ' }

                @{ Key = 'Tier0';                Name = 'Tier0';           ParentPath = 'OU=BarmBuzz';                    DependsOnKey = 'BarmBuzz';       Protected = 'true'; Description = 'Domain Control Plane - Restricted admin Tier' }
                @{ Key = 'Tier0_Admins';         Name = 'Admins';          ParentPath = 'OU=Tier0,OU=BarmBuzz';           DependsOnKey = 'Tier0';          Protected = 'true'; Description = 'Domain Administrator account' }
                @{ Key = 'Tier0_Servers';        Name = 'Servers';         ParentPath = 'OU=Tier0,OU=BarmBuzz';           DependsOnKey = 'Tier0';          Protected = 'true'; Description = 'Domain Infrastructure Servers' }
                @{ Key = 'Tier0_ServiceAccounts';Name = 'ServiceAccounts'; ParentPath = 'OU=Tier0,OU=BarmBuzz';           DependsOnKey = 'Tier0';          Protected = 'true'; Description = 'Service Accounts for Domain Level Privileges' }

                @{ Key = 'Sites';                Name = 'Sites';           ParentPath = 'OU=BarmBuzz';                    DependsOnKey = 'BarmBuzz';       Protected = 'true'; Description = 'Geographic Site Container' }
                @{ Key = 'Bolton';               Name = 'Bolton';          ParentPath = 'OU=Sites,OU=BarmBuzz';           DependsOnKey = 'Sites';          Protected = 'true'; Description = 'Bolton HQ Silcon Croal Valley campus' }
                @{ Key = 'Bolton_Users';         Name = 'Users';           ParentPath = 'OU=Bolton,OU=Sites,OU=BarmBuzz'; DependsOnKey = 'Bolton';         Protected = 'true'; Description = 'Bolton staff, Managers, Drivers and Support Staff' }
                @{ Key = 'Bolton_Computers';     Name = 'Computers';       ParentPath = 'OU=Bolton,OU=Sites,OU=BarmBuzz'; DependsOnKey = 'Bolton';         Protected = 'true'; Description = 'Bolton Computer Accounts' }
                @{ Key = 'Bolton_Workstations';  Name = 'Workstations';    ParentPath = 'OU=Computers,OU=Bolton,OU=Sites,OU=BarmBuzz'; DependsOnKey = 'Bolton_Computers'; Protected = 'true'; Description = 'Staff Workstations and Depot machines' }
                @{ Key = 'Bolton_POS';           Name = 'POS';             ParentPath = 'OU=Computers,OU=Bolton,OU=Sites,OU=BarmBuzz'; DependsOnKey = 'Bolton_Computers'; Protected = 'true'; Description = 'POS terminals at Barm Unloading Sectors' }
                @{ Key = 'Bolton_Kiosks';        Name = 'Kiosks';          ParentPath = 'OU=Computers,OU=Bolton,OU=Sites,OU=BarmBuzz'; DependsOnKey = 'Bolton_Computers'; Protected = 'true'; Description = 'Self Service Ordering Kiosks' }

                @{ Key = 'Groups';               Name = 'Groups';          ParentPath = 'OU=BarmBuzz';                    DependsOnKey = 'BarmBuzz';       Protected = 'true'; Description = 'Security and Distribution Group Container' }
                @{ Key = 'Groups_Roles';         Name = 'Role';            ParentPath = 'OU=Groups,OU=BarmBuzz';          DependsOnKey = 'Groups';         Protected = 'true'; Description = 'Global role Groups (AGDLP: G layer)' }
                @{ Key = 'Groups_Resource';      Name = 'Resource';        ParentPath = 'OU=Groups,OU=BarmBuzz';          DependsOnKey = 'Groups';         Protected = 'true'; Description = 'Domain Local Resource Groups (AGDLP: DL layer)' }

                @{ Key = 'Clients';              Name = 'Clients';         ParentPath = 'OU=BarmBuzz';                    DependsOnKey = 'BarmBuzz';       Protected = 'true'; Description = 'Domain-joined client machines by OS' }
                @{ Key = 'Clients_Windows';      Name = 'Windows';         ParentPath = 'OU=Clients,OU=BarmBuzz';         DependsOnKey = 'Clients';        Protected = 'true'; Description = 'Windows Domain-joined Clients' }
                @{ Key = 'Clients_Linux';        Name = 'Linux';           ParentPath = 'OU=Clients,OU=BarmBuzz';         DependsOnKey = 'Clients';        Protected = 'true'; Description = 'Linux Domain-joined Clients' }
            )

            SecurityGroups = @(
                @{ Key = 'GG_Bolton_Baristas';   GroupName = 'GG_BB_Bolton_Baristas';  GroupScope = 'Global';     Category = 'Security'; OUPath = 'OU=Role,OU=Groups,OU=BarmBuzz';     DependsOnKey = 'Groups_Roles';   MembersToInclude = @(); Description = 'Bolton baristas - barm assembly and HVBSDP delivery' }
                @{ Key = 'GG_Bolton_Managers';   GroupName = 'GG_BB_Bolton_Managers';  GroupScope = 'Global';     Category = 'Security'; OUPath = 'OU=Role,OU=Groups,OU=BarmBuzz';     DependsOnKey = 'Groups_Roles';   MembersToInclude = @(); Description = 'Bolton Managers - Depot and route supervisors' }
                @{ Key = 'GG_IT_Helpdesk';       GroupName = 'GG_BB_IT_Helpdesk';      GroupScope = 'Global';     Category = 'Security'; OUPath = 'OU=Role,OU=Groups,OU=BarmBuzz';     DependsOnKey = 'Groups_Roles';   MembersToInclude = @(); Description = 'IT Helpdesk - delegated workstation and user support' }

                @{ Key = 'DL_POS_LocalAdmins';   GroupName = 'DL_BB_POS_LocalAdmins';  GroupScope = 'DomainLocal';Category = 'Security'; OUPath = 'OU=Resource,OU=Groups,OU=BarmBuzz'; DependsOnKey = 'Groups_Resource'; MembersToInclude = @('GG_BB_Bolton_Baristas'); Description = 'Local Admins on POS terminals' }
                @{ Key = 'DL_Recipes_Read';      GroupName = 'DL_BB_Recipes_Read';     GroupScope = 'DomainLocal';Category = 'Security'; OUPath = 'OU=Resource,OU=Groups,OU=BarmBuzz'; DependsOnKey = 'Groups_Resource'; MembersToInclude = @('GG_BB_Bolton_Managers','GG_BB_Bolton_Baristas'); Description = 'Read access to recipe repository' }
                @{ Key = 'DL_Recipes_Write';     GroupName = 'DL_BB_Recipes_Write';    GroupScope = 'DomainLocal';Category = 'Security'; OUPath = 'OU=Resource,OU=Groups,OU=BarmBuzz'; DependsOnKey = 'Groups_Resource'; MembersToInclude = @('GG_BB_Bolton_Managers'); Description = 'Write access to recipe repository' }
            )

            Delegations = @(
                @{
                    Key = 'Delegate_Workstation_Join'
                    TargetOUPath        = 'OU=Workstations,OU=Computers,OU=Bolton,OU=Sites,OU=BarmBuzz'
                    IdentityGroupName   = 'GG_BB_IT_Helpdesk'
                    DependsOnOUKey      = 'Bolton_Workstations'
                    DependsOnGroupKey   = 'GG_IT_Helpdesk'
                    Rights              = @('CreateChild','DeleteChild')
                    AccessControlType   = 'Allow'
                    ObjectTypeGuid      = 'bf967aba-0de6-11d0-a285-00aa003049e2'
                    InheritanceType     = 'All'
                    InheritedObjectType = '00000000-0000-0000-0000-000000000000'
                    Description         = 'Allow IT Helpdesk to join/remove workstations in Bolton'
                }
            )

            ADUsers = @(
                @{
                    Key                 = 'ava_barista'
                    UserName            = 'ava.barista'
                    GivenName           = 'Ava'
                    Surname             = 'Barista'
                    DisplayName         = 'Ava Barista'
                    UserPrincipalName   = 'ava.barista@barmbuzz.corp'
                    OUPath              = 'OU=Users,OU=Bolton,OU=Sites,OU=BarmBuzz'
                    DependsOnKey        = 'Bolton_Users'
                    GroupMembership     = @('GG_BB_Bolton_Baristas')
                    JobTitle            = 'Senior Barista'
                    Department          = 'Barm Assembly'
                    Description         = 'Bolton barista - HVBSDP certified'
                    ChangePasswordAtLogon = 'true'
                }
                @{
                    Key                 = 'bob_manager'
                    UserName            = 'bob.manager'
                    GivenName           = 'Bob'
                    Surname             = 'Manager'
                    DisplayName         = 'Bob Manager'
                    UserPrincipalName   = 'bob.manager@barmbuzz.corp'
                    OUPath              = 'OU=Users,OU=Bolton,OU=Sites,OU=BarmBuzz'
                    DependsOnKey        = 'Bolton_Users'
                    GroupMembership     = @('GG_BB_Bolton_Managers')
                    JobTitle            = 'Depot Manager'
                    Department          = 'Operations'
                    Description         = 'Bolton Depot Manager - route supervisor.'
                    ChangePasswordAtLogon = 'true'
                }
                @{
                    Key                 = 'Charlie_helpdesk'
                    UserName            = 'charlie.helpdesk'
                    GivenName           = 'Charlie'
                    Surname             = 'Helpdesk'
                    DisplayName         = 'Charlie Helpdesk'
                    UserPrincipalName   = 'charlie.helpdesk@barmbuzz.corp'
                    OUPath              = 'OU=Users,OU=Bolton,OU=Sites,OU=BarmBuzz'
                    DependsOnKey        = 'Bolton_Users'
                    GroupMembership     = @('GG_BB_IT_Helpdesk')
                    JobTitle            = 'IT Helpdesk Analyst'
                    Department          = 'IT'
                    Description         = 'IT Helpdesk - delegated workstation and user support.'
                    ChangePasswordAtLogon = 'true'
                }
            )

            PasswordPolicy = @{
                ComplexityEnabled         = 'true'
                MinimumPasswordLength     = 10
                PasswordHistoryCount      = 12
                MaxPasswordAge            = 129600
                MinPasswordAge            = 1440
                LockoutThreshold          = 5
                LockoutDuration           = 30
                LockoutObservationWindow  = 30
                ReversibleEncryptionEnabled = 'false'
            }

            GroupPolicies = @(
                @{ Key = 'GPO_Workstations_Basline'; Name = 'BB_Workstations_Baseline'; Description = 'Workstation baseline' }
                @{ Key = 'GPO_Servers_Baseline';     Name = 'BB_Servers_Baseline';      Description = 'Server baseline' }
                @{ Key = 'GPO_POS_Lockdown';         Name = 'BB_POS_Lockdown';          Description = 'POS lockdown' }
                @{ Key = 'GPO_AllUsers_Banner';      Name = 'BB_AllUsers_Banner';       Description = 'Org logon banner' }
            )

            GPOLinks = @(
                @{
                    Key           = 'Link_WksBaseline_Workstations'
                    GPOName       = 'BB_Workstations_Baseline'
                    TargetOUPath  = 'OU=Workstations,OU=Computers,OU=Bolton,OU=Sites,OU=BarmBuzz'
                    DependsONGPO  = 'GPO_Workstations_Basline'
                    DependsOnOUKey= 'Bolton_Workstations'
                    Order         = 1
                    Enforced      = 'No'
                    Enabled       = 'Yes'
                }
                @{
                    Key           = 'Link_SrvBaseline_Servers'
                    GPOName       = 'BB_Servers_Baseline'
                    TargetOUPath  = 'OU=Servers,OU=Tier0,OU=BarmBuzz'
                    DependsONGPO  = 'GPO_Servers_Baseline'
                    DependsOnOUKey= 'Tier0_Servers'
                    Order         = 1
                    Enforced      = 'No'
                    Enabled       = 'Yes'
                }
                @{
                    Key           = 'Link_POSLockdown_POS'
                    GPOName       = 'BB_POS_Lockdown'
                    TargetOUPath  = 'OU=POS,OU=Computers,OU=Bolton,OU=Sites,OU=BarmBuzz'
                    DependsONGPO  = 'GPO_POS_Lockdown'
                    DependsOnOUKey= 'Bolton_POS'
                    Order         = 1
                    Enforced      = 'No'
                    Enabled       = 'Yes'
                }
                @{
                    Key           = 'Link_Banner_BarmBuzz'
                    GPOName       = 'BB_AllUsers_Banner'
                    TargetOUPath  = 'OU=BarmBuzz'
                    DependsONGPO  = 'GPO_AllUsers_Banner'
                    DependsOnOUKey= 'BarmBuzz'
                    Order         = 1
                    Enforced      = 'No'
                    Enabled       = 'Yes'
                }
            )

            GPORegistryValues = @(
                @{ Key='Wks_NoLMHash';     GPOName='BB_Workstations_Baseline'; DependsOnGPO='GPO_Workstations_Basline'; RegistryKey='HKLM\SYSTEM\CurrentControlSet\Control\Lsa'; ValueName='NoLMHash'; ValueType='Dword'; ValueData=1 }
                @{ Key='Wks_SMBSigning';   GPOName='BB_Workstations_Baseline'; DependsOnGPO='GPO_Workstations_Basline'; RegistryKey='HKLM\SYSTEM\CurrentControlSet\Services\LanManServer\Parameters'; ValueName='RequireSecuritySignature'; ValueType='Dword'; ValueData=1 }
                @{ Key='wks_NTLMv2Only';   GPOName='BB_Workstations_Baseline'; DependsOnGPO='GPO_Workstations_Basline'; RegistryKey='HKLM\SYSTEM\CurrentControlSet\Control\Lsa'; ValueName='LmCompatibilityLevel'; ValueType='Dword'; ValueData=5 }
                @{ Key='Wks_ScreenSaver';  GPOName='BB_Workstations_Baseline'; DependsOnGPO='GPO_Workstations_Basline'; RegistryKey='HKCU\Control Panel\Desktop'; ValueName='ScreenSaveActive'; ValueType='String'; ValueData='600' }

                @{ Key='Srv_AuditLogSize'; GPOName='BB_Servers_Baseline';      DependsOnGPO='GPO_Servers_Baseline'; RegistryKey='HKLM\SYSTEM\CurrentControlSet\Services\EventLog\Security'; ValueName='MaxSize'; ValueType='Dword'; ValueData=1048576 }
                @{ Key='Srv_SMB1Disable';  GPOName='BB_Servers_Baseline';      DependsOnGPO='GPO_Servers_Baseline'; RegistryKey='HKLM\SYSTEM\CurrentControlSet\Services\LanManServer\Parameters'; ValueName='SMB1'; ValueType='Dword'; ValueData=0 }

                @{ Key='POS_NoUSB';        GPOName='BB_POS_Lockdown';          DependsOnGPO='GPO_POS_Lockdown'; RegistryKey='HKLM\SYSTEM\CurrentControlSet\Services\USBSTOR'; ValueName='Start'; ValueType='Dword'; ValueData=4 }
                @{ Key='POS_LogonBanner';  GPOName='BB_POS_Lockdown';          DependsOnGPO='GPO_POS_Lockdown'; RegistryKey='HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'; ValueName='LegalNoticeText'; ValueType='String'; ValueData='BarmBuzz POS Terminal - Authorized use only. All activity monitored' }

                @{ Key='Banner_Title';     GPOName='BB_AllUsers_Banner';       DependsOnGPO='GPO_AllUsers_Banner'; RegistryKey='HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'; ValueName='LegalNoticeCaption'; ValueType='String'; ValueData='BarmBuzz Corp - Acceptable use Policy' }
                @{ Key='Banner_Text';      GPOName='BB_AllUsers_Banner';       DependsOnGPO='GPO_AllUsers_Banner'; RegistryKey='HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'; ValueName='LegalNoticeText'; ValueType='String'; ValueData='This system is the property of BarmBuzz Corp. Unauthorized access is prohibited. All activity is logged and monitored.' }
            )

            GPOPermissions = @(
                @{
                    Key          = 'Perm_Pos_Baristas'
                    GPOName       = 'BB_POS_Lockdown'
                    DependsOnGPO  = 'GPO_POS_Lockdown'
                    TargetName    = 'GG_BB_Bolton_Baristas'
                    TargetType    = 'Group'
                    Permission    = 'GpoApply'
                }
            )

            DefaultComputerOU = 'OU=Workstations,OU=Clients,OU=BarmBuzz'
        }

        @{
            NodeName = 'BB-WIN11-01'
            Role     = 'WinClient'

            ComputerName = 'BB-WIN11-01'
            TimeZone     = 'GMT Standard Time'

            InterfaceAlias_Internal = 'Ethernet'
            DnsServerAddress        = '192.168.99.10'

            DomainName        = 'barmbuzz.corp'
            DomainNetBIOSName = 'BARMBUZZ'
            DomainDN          = 'DC=barmbuzz,DC=corp'
            JoinOU            = 'OU=Windows,OU=Clients,OU=BarmBuzz,DC=barmbuzz,DC=corp'

            PsDscAllowPlainTextPassword = 'true'
            PsDscAllowDomainUser        = 'true'
        }
    )
}