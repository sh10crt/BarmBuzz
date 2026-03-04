@{
    AllNodes = @(
        # -----------------------------
        # Domain Controller Node
        # -----------------------------
        @{
            NodeName = 'localhost';
            Role     = 'DC';

            # AD Settings
            DomainName        = 'barmbuzz.corp';
            DomainNetBIOSName = 'BARMBUZZ';
            ForestMode        = 'WinThreshold';
            DomainMode        = 'WinThreshold';
            DomainDN          = 'DC=barmbuzz,DC=corp';

            # Computer Settings
            ComputerName = 'BB-DC01';
            TimeZone     = 'GMT Standard Time';

            # Networking
            InterfaceAlias_Internal = 'Ethernet 2';
            IPv4Address_Internal    = '192.168.1.10/24';
            DNSServers_Internal     = '127.0.0.1';
            InterfaceAlias_NAT      = 'Ethernet';

            PsDscAllowPlainTextPassword = $true;
            PsDscAllowDomainUser        = $true;

            # Organizational Units
            OrganizationalUnits = @(
                @{ Key='BarmBuzz'; Name='BarmBuzz'; ParentPath=''; DependsOnKey=''; Protected=$true; Description='Root OU' };
                @{ Key='Tier0'; Name='Tier0'; ParentPath='OU=BarmBuzz'; DependsOnKey='BarmBuzz'; Protected=$true; Description='Tier0 OU' };
                @{ Key='Tier0_Admins'; Name='Admins'; ParentPath='OU=Tier0,OU=BarmBuzz'; DependsOnKey='Tier0'; Protected=$true; Description='Admins OU' };
                @{ Key='Tier0_Servers'; Name='Servers'; ParentPath='OU=Tier0,OU=BarmBuzz'; DependsOnKey='Tier0'; Protected=$true; Description='Servers OU' };
                @{ Key='Sites'; Name='Sites'; ParentPath='OU=BarmBuzz'; DependsOnKey='BarmBuzz'; Protected=$true; Description='Sites OU' };
                @{ Key='Bolton'; Name='Bolton'; ParentPath='OU=Sites,OU=BarmBuzz'; DependsOnKey='Sites'; Protected=$true; Description='Bolton OU' };
                @{ Key='Bolton_Users'; Name='Users'; ParentPath='OU=Bolton,OU=Sites,OU=BarmBuzz'; DependsOnKey='Bolton'; Protected=$true; Description='Users OU' };
                @{ Key='Bolton_Computers'; Name='Computers'; ParentPath='OU=Bolton,OU=Sites,OU=BarmBuzz'; DependsOnKey='Bolton'; Protected=$true; Description='Computers OU' };
                @{ Key='Bolton_Workstations'; Name='Workstations'; ParentPath='OU=Computers,OU=Bolton,OU=Sites,OU=BarmBuzz'; DependsOnKey='Bolton_Computers'; Protected=$true; Description='Workstations OU' };
                @{ Key='Groups'; Name='Groups'; ParentPath='OU=BarmBuzz'; DependsOnKey='BarmBuzz'; Protected=$true; Description='Groups OU' };
                @{ Key='Groups_Role'; Name='Role'; ParentPath='OU=Groups,OU=BarmBuzz'; DependsOnKey='Groups'; Protected=$true; Description='Role Groups OU' };
                @{ Key='Groups_Resource'; Name='Resource'; ParentPath='OU=Groups,OU=BarmBuzz'; DependsOnKey='Groups'; Protected=$true; Description='Resource Groups OU' };
                @{ Key='Clients'; Name='Clients'; ParentPath='OU=BarmBuzz'; DependsOnKey='BarmBuzz'; Protected=$true; Description='Clients OU' };
                @{ Key='Clients_Windows'; Name='Windows'; ParentPath='OU=Clients,OU=BarmBuzz'; DependsOnKey='Clients'; Protected=$true; Description='Windows Clients OU' };
            );

            # Security Groups
            SecurityGroups = @(
                @{ Key='GG_Bolton-Baristas'; GroupName='GG_BB_Bolton_Baristas'; GroupScope='Global'; Category='Security'; OUPath='OU=Role,OU=Groups,OU=BarmBuzz'; DependsOnOUKey='Groups_Role'; MembersToInclude=@() };
                @{ Key='GG_Bolton-Managers'; GroupName='GG_BB_Bolton_Managers'; GroupScope='Global'; Category='Security'; OUPath='OU=Role,OU=Groups,OU=BarmBuzz'; DependsOnOUKey='Groups_Role'; MembersToInclude=@() };
                @{ Key='GG_Bolton-Helpdesk'; GroupName='GG_BB_IT_Helpdesk'; GroupScope='Global'; Category='Security'; OUPath='OU=Role,OU=Groups,OU=BarmBuzz'; DependsOnOUKey='Groups_Role'; MembersToInclude=@() };
                @{ Key='DL_POS-LocalAdmins'; GroupName='DL_BB_POS_LocalAdmins'; GroupScope='DomainLocal'; Category='Security'; OUPath='OU=Resource,OU=Groups,OU=BarmBuzz'; DependsOnOUKey='Groups_Resource'; MembersToInclude=@('GG_BB_Bolton_Baristas') };
            );

            # AD Users
            ADUsers = @(
                @{
                    Key='ava_barista';
                    UserName='ava_barista';
                    GivenName='Ava';
                    Surname='Barista';
                    DisplayName='Ava Barista';
                    UserPrincipalName='ava.barista@barmbuzz.corp';
                    OUPath='OU=Users,OU=Bolton,OU=Sites,OU=BarmBuzz';
                    DependsOnOUKey='Bolton_Users';
                    GroupMembership=@('GG_BB_Bolton_Baristas');
                    ChangePasswordAtLogon=$true;
                    Description='Barista User';
                }
            );

            # Password Policy
            PasswordPolicy = @{
                ComplexityEnabled=$true;
                MinPasswordLength=10;
                PasswordHistoryCount=12;
                MaxPasswordAge=90;
                MinPasswordAge=1;
                LockoutThreshold=5;
                LockoutDuration=30;
                LockoutObservationWindow=30;
                ReversibleEncryptionEnabled=$false;
            };
        };

        # -----------------------------
        # Windows Client Node
        # -----------------------------
        @{
            NodeName='BB-WIN11-01';
            Role='WINClient';

            ComputerName='BB-WIN11-01';
            TimeZone='GMT Standard Time';
            DomainName='barmbuzz.corp';
            DomainNetBIOSName='BARMBUZZ';
            DomainDN='DC=barmbuzz,DC=corp';

            PsDscAllowPlainTextPassword=$true;
            PsDscAllowDomainUser=$true;

            # Add default empty arrays/properties to prevent DSC errors
            OrganizationalUnits = @();
            SecurityGroups = @(@{ MembersToInclude=@() });
            ADUsers = @(@{ Description=$null });
            InterfaceAlias_Internal = $null;
            IPv4Address_Internal = $null;
            DNSServers_Internal = $null;
            InterfaceAlias_NAT = $null;
        }
    );
}