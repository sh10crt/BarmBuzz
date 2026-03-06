BarmBuzz Active Directory Automation

Project Overview:
The following functions are carried out by the configuration:
It set ups the Domain Controller and generated Domain Users.
It creates a fresh Active Directory Forest.
It builds Organizational Unites (OU).
It applies the registry-based security settings.
It implements Delegation Administration.
It uses the ADGLP approach to apply security groups.
It connects Windows Client computers to the domain.

Tools Used
The tools facilitate system configuration maintenance, guarantee consistency and lessen
manual work. We applied the tools like PowerShell Desired State Configuration, GroupPolicy
DSC, Networking DSC, Computer Management DSC and Windows Server Active Directory
Domain Services.

Structure
BarmBuzz-DSC-Lab
│
├── AllNodes.psd1
│ Configuration data file containing
│ domain settings, OU structure,
│ users, groups, policies and node definitions
│
├── Studenconfig.ps1
│ DSC configuration that reads
│ AllNodes.psd1 and deploys the environment
│
└── README.md

Domain Information
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

Active Directory Structure
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

Sites
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

Clients
Applying different rules can be made simple by the OU Clients' separation of machines
according to operating system type. For example, Windows and Linux are available in OU
Clients. Linux systems can use various configuration management tools, while Windows
machines may receive Windows Group Policy.

Security Group Design

Accounts User
Global Groups GG_BB_Bolton_Baristas
Domain Local Groups GG_BB_POS_LocalAdmins
Permissions Access to POS terminals

Global Role Groups
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
I found plenty of difficulties during this practical lab, but the primary issue was with Group
Policies. Some of the GPO configurations weren't working since they are not totally compatible
with PowerShell 7 on our Windows server.
I gained a better understanding of how automation may improve safety and flexibility in a
network environment while also making AD management simpler, quicker, and more structured.

Edivences; 
Evidence\HealthChecks\{9D74A745-8A45-412E-B5E7-75F7773E6DA4}.png
Evidence\HealthChecks\{21C55B47-E668-4362-983E-F4975CEAD167}.png
Evidence\HealthChecks\{41BB4F62-AAF4-416A-B7E6-84F993534BE6}.png
Evidence\HealthChecks\{8073D626-6169-4F1E-A4E4-EE3A798433D1}.png
Evidence\HealthChecks\{3851482F-89CB-4D80-8E49-10D2D07FE781}.png
Evidence\HealthChecks\{AE9B0343-8F0F-485C-A6D4-DB2C337AF4C3}.png
Evidence\HealthChecks\{B90A2AB7-52EC-4B2E-BC3E-BFEFB1D15CD2}.png
Evidence\HealthChecks\{FD3EE666-D7E2-480E-B544-B0753DA5F998}.png
Refernces:
Bertram, A.R. (2020) PowerShell for sysadmins: workflow automation made easy. 1st edn. San Francisco, CA: No Starch Press.

Francis, D. (2021) ‘Advanced AD Management with PowerShell,’ in Mastering Active Directory. United Kingdom: Packt Publishing, Limited.

Lee, T. (2021) Windows Server Automation with PowerShell Cookbook. 4th edn. Packt Publishing.

Sukhija, V. (2021) PowerShell Fast Track: Hacks for Non-Coders. 1st edn. Berkeley, CA: Apress.

Waters, I. (2021) PowerShell for Beginners: Learn PowerShell 7 Through Hands-On Mini Games. 1st edn. Berkeley, CA: Apress L. P.