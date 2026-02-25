<#
STUDENT TASK:
- Define Configuration StudentBaseline
- Use ConfigurationData (AllNodes.psd1)
- DO NOT hardcode passwords here.

CYBERSECURITY NOTES:
This is a Security module. Credential handling matters even in labs.

WHY NO HARDCODED CREDENTIALS?
1. Security Hygiene: Hardcoded credentials in code = security breach waiting to happen
2. Git History: Once committed, credentials are in your Git history FOREVER (even if you delete them later)
3. Professional Practice: Real environments use credential vaults (Azure KeyVault, HashiCorp Vault, etc.)
4. Audit Trail: Your Git commits may be reviewed by employers, peers, or examiners

HOW CREDENTIALS WILL WORK (Later weeks):
- The orchestrator (Run_BuildMain.ps1) will handle credential creation securely
- Your configuration receives them as PSCredential objects via parameters
- Example: Configuration StudentBaseline { param([PSCredential]$DomainCredential) }
- You reference them in DSC resources without seeing the plaintext password
- MOFs can be encrypted with certificates (production best practice)

FOR NOW (Week 1):
- Lab uses FIXED credentials documented in StudentRepoInit.ps1
- Administrator password: superw1n_user (Windows local admin)
- User accounts password: notlob2k26 (domain users you create)
- You may need these for MANUAL tasks, but NEVER put them in this file

THREAT MODEL AWARENESS:
Even in a lab, practice defense-in-depth:
- Assume your repo will be cloned by others (it will - it's Git!)
- Assume your transcripts/logs will be read (they're in Evidence/)
- Assume your build artifacts will be inspected (they're committed)
- NEVER commit: passwords, API keys, personal data, PII

If you accidentally commit a secret:
1. Rotating the secret is the ONLY fix (changing the password)
2. Deleting the file or "fixing" the commit does NOT remove it from Git history
3. Tools like git-secrets, TruffleHog, and GitGuardian scan for exposed secrets

This is not paranoia - this is professional discipline.
#>

Configuration StudentBaseline {
    param(
        #the username in the  crediential should be just "Administrator"
        [Parameter(Mandatory = $true)]
        [PSCredential]
        $DomainAdminCredential,
     #can be same as Domain Admin credential, or different for extra security
        [Parameter(Mandatory = $true)]
        [PSCredential]
        $DsrmCredential
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName ComputerManagementDSC
    Import-DscResource -ModuleName ActivedirectoryDSC
    Import-DscResource -ModuleName NetworkingDSC 

    #Import-DscResource -ModuleName ActivedirectoryDSC
    

    Node $AllNodes.NodeName {

        Computer SetName {
            Name = $AllNodes.ComputerName
        }
        TimeZone SetTimeZone {
            IsSingleInstance = 'Yes'
            TimeZone = $AllNodes.TimeZone
            
        }
       Service WindowsTime {
            Name = 'W32Time'
            State = 'Running'
            StartupType = 'Automatic'
             DependsOn = '[TimeZone]SetTimeZone'

            
        }
        #Network Settings Internal NIC
        IPAddress SetInternalIP
        {  #InterfaceAlias : The name of the network adapter
        InterfaceAlias = $Node.InterfaceAlias_Internal
        #Addressfamily : IPV4 or IPV6
        Addressfamily = 'IPv4'
        IPAddress = $Node.IPv4Address_Internal
        DependsOn = '[Computer]SetComputerName'

        }
        DnsServerAddress SetInternalDNS
        {
            InterfaceAlias = $Node.InterfaceAlias_Internal
            Addressfamily  = 'IPv4'
            #127.0.0.0 loopback
            Address = $Node.DnsServers_Internal
            DependsOn = '[IPAddress]SetInternalIP'

        }
        #Network Settings External- NIC
        DnsConnectionSuffix DisableNatDnsRegistration
        {
            InterfaceAlias = $Node.InterfaceAlias_NAT

            ConnectionSpecificSuffix = ''

            RegisterThisConnectionsAddress = $false
            DependsOn = '[DnsServerAddress]SetInternalDns'
        }

        ###Install AD DS and RSAT Tools for domain Controller



        windowsFeature ADDS {
            Name = 'AD-Domain-Services'
            Ensure = 'Present'
        }   
        windowsFeature RSATADDS {
            Name = 'RSAT-AD-Tools'
            Ensure = 'Present'
            DependsOn = '[WindowsFeature]ADDS'
        }
        ##Promote the Domain Controller and  create the new forest and Domain
        ADDomain CreateForest
        {
            DomainName = $Node.DomainName
            DomainNetBIOSName = $Node.DomainNetBIOSName

            Credential = $DomainAdminCredential
            SafemodeAdministratorPassword = $DsrmCredential

            ForestMode = $Node.ForestMode
            DomainMode = $Node.DomainMode
            DependsOn  = '[WindowsFeature]InstallRSAT'


        }

    }
}
