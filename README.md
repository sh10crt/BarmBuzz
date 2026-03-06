The BarmBuzz Active Directory Automation Project demonstrates how modern infrastructure automation can be used to deploy and manage an enterprise Active Directory environment in a consistent and secure way. The project uses PowerShell Desired State Configuration (DSC) to automatically configure a domain controller, deploy organisational units, create domain users and groups, apply security policies, and join client machines to the domain.

By using infrastructure-as-code principles, the configuration ensures that the Active Directory environment is repeatable, scalable, and compliant with security best practices. The project also implements the ADGLP (Accounts → Global Groups → Domain Local Groups → Permissions) model, delegated administration, and Group Policy Objects to enforce organisational security standards.

This automated approach reduces manual administrative effort while improving the reliability and security of the network infrastructure.

-----Project Overview-----
The following functions are carried out by the configuration:
It set ups the Domain Controller and generated Domain Users.
It creates a fresh Active Directory Forest.
It builds Organizational Unites (OU).
It applies the registry-based security settings.
It implements Delegation Administration.
It uses the ADGLP approach to apply security groups.
It connects Windows Client computers to the domain.

-----Tools Used-----
The tools facilitate system configuration maintenance, guarantee consistency and lessen
manual work. We applied the tools like PowerShell Desired State Configuration, GroupPolicy
DSC, Networking DSC, Computer Management DSC and Windows Server Active Directory
Domain Services.

----Structure----

BarmBuzz-DSC-Lab
│
├──  StudentBaseline.ps1
│ DSC configuration that reads
│ AllNodes.psd1 and deploys the environment
│
├── AllNodes.psd1
│ Configuration data file containing
│ domain settings, OU structure,
│ users, groups, policies and node definitions
│
└── README.md

----Domain Information---- 

Domain Controller:
Interface “Ethernet” – Internal network

“IP Address: 10.0.2.15
Subnet: /24
DNS: 127.0.0.1”
Interface “Ethernet2” – External network
“IP Address 192.168.1.10
Subnet:/24
DNS: 127.0.0.1”

Settings Values
Domain Name BarmBuzz.corp
NetBIOS Name BARMBUZZ
Domain Controller BB-DC01
Forest Mode Windows Threshold
Domain Mode Windows Threshold

------Active Directory Structure-----
BarmBuzz
│
├── Tier0
│ ├── Admins
│ ├── Servers
│ └── ServiceAccounts
│
├── Sites
│ └── Bolton
│ ├── Users
│ └── Computers
│ ├── Workstations
│ ├── POS
│ └── Kiosks
│
├── Groups
│ ├── Role
│ └── Resource
│
└── Clients

├── Windows
└── Linux

Tier 0
Admins Servers ServiceAccounts
It manages the AD,
Domain Controller, and
security policies.

It separates the Domain
controller which helps to
apply specific security
policies for servers.

It includes service
accounts that
applications, such as
monitoring systems and
backup services, employ.

------Sites----
Users Computers
It keeps the record of all the users for
staff at the Bolton.

It contains the join domain devices in
the Bolton.

Example: Managers Example: workstations, POS
Groups
Role Resource
It represents the job roles. It controls the access to specific

resource.

GG_BB_Bolton_Managers DL_BB_POS_LocalAdmins

------Clients-----
Applying different rules can be made simple by the OU Clients' separation of machines
according to operating system type. For example, Windows and Linux are available in OU
Clients. Linux systems can use various configuration management tools, while Windows
machines may receive Windows Group Policy.

------Security Group Design------

------Accounts User-----
Global Groups GG_BB_Bolton_Baristas
Domain Local Groups GG_BB_POS_LocalAdmins
Permissions Access to POS terminals

------Global Role Groups----
Groups Purpose
GG_BB_Bolton_Baristas Bolton Baristas
GG_BB_Bolton_Managers Bolton depot managers
GG_BB_IT_Helpdesk IT helpdesk staff

Domain Local resource Groups
Groups Purpose
DL_BB_POS_LocalAdmins Local admin access on POS terminals
DL_BB_Recipes_Read Read access to recipe repository
DL_BB_Recipes_Write Write Access to recipe repository

Delegated Administration
Active Directory Delegation is demonstrated in this project. Here, authorisation to add
computers to the domain and remove computer objects is given to the IT helpdesk team.
Permission given to the group: GG_BB_IT_Helpdesk
Delegation responses to: OU=Computers, OU=Workstations, and OU=Bolton
Domain Users
Users Role
Ava.barista Senior Barista
Bob.manager Depot Manager
Charlie.helpdesk IT Helpdesk Analyst

Password Policy
Setting Value
Minimum Length 10
Password History 12
Maximum Age 90 days
Minimum Age 1 day
Account Lockout 5 attempts
Lockout duration 30 minutes
Group Policy Object (PGO)
GPO Name Purpose
BB_Workstation_Baseline Workstation security baseline
BB_Servers_Baseline Server baseline policies
BB_POS_Lockdown POS terminal restrictions
BB_Allusers_Banner Logon banner

Client Configuration
Client: BB-WIN11-01
Time Zone - we’ll set the correct time zone for the client by using this code
TimeZone SetClientTimeZone {

IsSingleInstance = 'Yes'
TimeZone = $Node.TimeZone # e.g., 'GMT Standard Time'
}
DNS Server - then, we’ll configure DNS to point to the domain controller with this code
DnsServerAddress SetDnsToDC {
InterfaceAlias = $Node.InterfaceAlias_Internal # e.g., 'Ethernet'
Address = $Node.DnsServerAddress # e.g., '192.168.99.10'
AddressFamily = 'IPv4'
}

Join Domain – by using this code, we’ll join the client to the Active Directory domain in the
correct OU
Computer JoinDomain {
Name = $Node.ComputerName # e.g., 'BB-WIN11-01'
DomainName = $Node.DomainName # e.g., 'barmbuzz.corp'
JoinOU = $Node.JoinOU # e.g., 'OU=Windows,OU=Clients,OU=BarmBuzz'
Credential = $DomainAdminCredential # Domain admin credentials
DependsOn = '[DnsServerAddress]SetDnsToDC'
}

Windows Time Services
Service WindowsTimeClient {
Name = 'W32Time'
State = 'Running'
StartupType = 'Automatic'
}

Security Features
# Disable SMBv1 (legacy protocol)
WindowsOptionalFeature DisableSMBv1Client {
Name = 'SMB1Protocol'
Ensure = 'Disable'
NoWindowsUpdateCheck = $true
}

# Ensure Windows Firewall is running
Service WindowsFirewall {
Name = 'mpsSvc'
State = 'Running'
StartupType = 'Automatic'
}

DSC Configuration
In our configuration file, we did configuration like import the configuration, create credentials,
compile DSC configuration and start DSC.
Import the configuration: .\StudentBaseline.ps1
Create Credentials: $DomainAdminCredential = Get-Credential
$DsrmCredential = Get-Credential
$UserCredential = Get-Credential

Compile DSC configuration: StudentBaseline `
-ConfigurationData .\AllNodes.psd1 `
-DomainAdminCredential $DomainAdminCredential `
-DsrmCredential $DsrmCredential `
-UserCredential $UserCredential

Start DSC: Start-DscConfiguration -Path .\StudentBaseline -Wait -Verbose -Force

Conclusion:
Gpg was a nightmare when it comes with setting up the path. But AI helped with all the problems and made them quite easier for me.
Furthermore Syntax is a minor but can be really painfull and with the development and setting uo this It made me realised the importance of small problems needs proper consideration.
I found plenty of difficulties during this practical lab, but the primary issue was with Group
Policies. Some of the GPO configurations weren't working since they are not totally compatible
with PowerShell 7 on our Windows server.
I gained a better understanding of how automation may improve safety and flexibility in a
network environment while also making AD management simpler, quicker, and more structured.
Refernces:
Microsoft (2024) Active Directory Domain Services Overview. Available at:
https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/get-started/virtual-dc/active-directory-domain-services-overview

Microsoft (2024) PowerShell Desired State Configuration (DSC) Documentation. Available at:
https://learn.microsoft.com/en-us/powershell/dsc/overview

Microsoft (2024) Group Policy Overview. Available at:
https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/manage/group-policy/group-policy-overview

Microsoft (2024) Active Directory Security Best Practices. Available at:
https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/plan/security-best-practices

Microsoft (2024) Delegating Administration in Active Directory. Available at:
https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/manage/delegation/delegating-administration

Microsoft (2024) Group Policy Security Baselines. Available at:
https://learn.microsoft.com/en-us/windows/security/threat-protection/windows-security-baselines

Center for Internet Security (2023) CIS Microsoft Windows Server Benchmark. Available at:
https://www.cisecurity.org/cis-benchmarks

National Institute of Standards and Technology (2020) Security and Privacy Controls for Information Systems (NIST SP 800-53). Available at:
https://nvd.nist.gov
Bertram, A.R. (2020) PowerShell for sysadmins: workflow automation made easy. 1st edn. San Francisco, CA: No Starch Press.

Francis, D. (2021) ‘Advanced AD Management with PowerShell,’ in Mastering Active Directory. United Kingdom: Packt Publishing, Limited.

Lee, T. (2021) Windows Server Automation with PowerShell Cookbook. 4th edn. Packt Publishing.

Sukhija, V. (2021) PowerShell Fast Track: Hacks for Non-Coders. 1st edn. Berkeley, CA: Apress.

Waters, I. (2021) PowerShell for Beginners: Learn PowerShell 7 Through Hands-On Mini Games. 1st edn. Berkeley, CA: Apress L. P.