This repo contains the StudentBaseline DSC configuration for the BarmBuzz domain (barmbuzz.corp), OUs, security groups, users, and password policy. Group Policy resources are in configuration data but not applied (GroupPolicyDsc required for PowerShell 7 compatibility).
________________________________________
1. Install Git (Windows)
winget install --id Git.Git -e --source winget
Restart the terminal, then verify:
git --version
2. Configure Git identity
git config --global user.name "Your Full Name"
git config --global user.email "your.email@example.com"
git config --global init.defaultBranch main
git config --global core.editor "code --wait"
3. GPG for signed commits (optional)
winget install -e --id GnuPG.Gpg4win
gpg --full-generate-key
Export and add to GitHub (Settings → SSH and GPG keys):
gpg --armor --export your.email@example.com
4. Local repo and GitHub
mkdir your_directory_name
cd your_directory_name
git init
git remote add origin https://github.com/yourusername/yourrepo.git
Evidence for submission:
git log --all --decorate --graph --oneline > git_history_evidence.txt
git reflog > git_reflog_evidence.txt
git remote -v
________________________________________
DSC v3 + PowerShell 7 environment
Step 1: Windows Server 2025 (AD DC)
•	Static IP (example):
•	New-NetIPAddress -InterfaceAlias "Ethernet 2" -IPAddress 192.168.1.10 -PrefixLength 24
Set-DnsClientServerAddress -InterfaceAlias "Ethernet 2" -ServerAddresses 192.168.1.10
•	Rename: Rename-Computer -NewName "BARM-DC-01" -Restart
•	Install Windows Updates (Settings → Windows Update).
Step 2: PowerShell 7
winget install -e --id Microsoft.PowerShell -s winget
# Verify: $PSVersionTable.PSVersion
Step 3: DSC v3
winget install -e --id Microsoft.DSC -s winget
dsc --help
DSC modules:
Save-PSResource -Name ActiveDirectoryDsc -Version 6.6.0 -Repository PSGallery -Path "C:\Program Files\WindowsPowerShell\Modules" -TrustRepository
Save-PSResource -Name GroupPolicyDsc -Version 1.0.3 -Repository PSGallery -Path "C:\Program Files\WindowsPowerShell\Modules" -TrustRepository
Get-Module -ListAvailable -Name ActiveDirectoryDsc, GroupPolicyDsc
Step 4: RSAT (Server 2025)
Install-WindowsFeature -Name RSAT-AD-PowerShell -IncludeAllSubFeature
Install-WindowsFeature -Name GPMC
Windows 11:
Add-WindowsCapability -Online -Name Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0
Add-WindowsCapability -Online -Name Rsat.GroupPolicy.Management.Tools~~~~0.0.1.0
Step 5: Git & VS Code
winget install -e --id Git.Git -s winget
winget install -e --id Microsoft.VisualStudioCode -s winget
code --install-extension ms-vscode.powershell
code --install-extension redhat.vscode-yaml
code --install-extension eamodio.gitlens
code --install-extension mhutchie.git-graph
code --install-extension donjayamanne.githistory
Step 6: Apply DSC 
If using DSC v3 YAML:
dsc config -Path "C:\Path\To\Your\Configuration.yaml"
This project uses MOF-based DSC (configuration script + .psd1 data). To compile and apply, see “Running this configuration” below.
Step 7: Pester
Save-PSResource -Name Pester -Version 5.7.1 -Repository PSGallery -Path "C:\Program Files\WindowsPowerShell\Modules" -TrustRepository
Import-Module Pester
Invoke-Pester -Output Detailed
________________________________________
Running this configuration
Prerequisites: PowerShell 5.1 or 7, modules: ComputerManagementDsc, ActiveDirectoryDsc, NetworkingDsc. Configuration data: AllNodes.psd1 next to StudentBaseline.ps1.
1.	Edit credentials in the script below (or use a secure method; plaintext is for lab only).
2.	Compile (run from the folder containing StudentBaseline.ps1 and AllNodes.psd1):
$AllNodes = Import-PowerShellDataFile -Path .\AllNodes.psd1
$domainAdmin = Get-Credential -Message "Domain Admin"
$dsrm        = Get-Credential -Message "DSRM"
$userPwd     = Get-Credential -Message "Default user password"

. .\StudentBaseline.ps1
StudentBaseline -AllNodes $AllNodes `
  -DomainAdminCredential $domainAdmin `
  -DsrmCredential $dsrm `
  -UserCredential $userPwd
3.	Apply (on the DC node, typically localhost):
Start-DscConfiguration -Path .\StudentBaseline -Wait -Verbose -Force
4.	Test:
Test-DscConfiguration -Path .\StudentBaseline
________________________________________
Files
File	Purpose
StudentBaseline.ps1	DSC configuration (DC + WinClient nodes).
AllNodes.psd1	AllNodes data (DCs, clients, OUs, groups, users, GPO metadata).
Note: GPOs, GPOLinks, GPORegistryValues, and GPOPermissions are defined in AllNodes.psd1 for when GroupPolicyDsc is reintroduced; they are not applied by the current configuration.
________________________________________
Branching workflow (Git)
git checkout -b feature/update-readme
# edit README.md
git add README.md
git commit -m "FEAT: update README with feature branch info"
git checkout main
git merge feature/update-readme
git push origin main
BarmBuzz AD DSC - Engineer Handover Runbook
Operational handover runbook for engineers supporting the BarmBuzz (barmbuzz.corp) DSC environment: deployment, operations, verification, change control, and troubleshooting.
________________________________________
1. Overview
Item	Description
Scope	Domain Controller (BB-DC01), Windows client (BB-WIN11-01), OUs, security groups, AD users, password policy.
Config	StudentBaseline.ps1 + AllNodes.psd1 (MOF-based DSC).
Audience	Platform/Infrastructure engineers, support engineers, and on-call maintainers.
Key paths (this repo)
Path	Purpose
StudentBaseline.ps1	DSC configuration definition.
AllNodessd1	Node and AD data (OUs, groups, users, policy).
StudentBaseline\	Generated MOF output (after compile).
________________________________________

 Prerequisites & reference
Credentials required
Credential	Used for
Domain Admin	AD operations, domain join, DSC runs on DC.
DSRM (Safe Mode)	AD forest creation (one-time).
User (default password)	New AD user accounts (initial password).
Node reference
Node	Role	Notes
Localhost	DC	BB-DC01, 192.168.1.10, barmbuzz.corp.
BB-WIN11-01	WinClient	DNS 192.168.99.10; join OU=Windows,OU=Clients,OU=BarmBuzz.
________________________________________
4. Procedures
4.1 First-time: Install Git and set identity
When: Before any commits or push to GitHub.
Steps:
1.	Install Git (Windows):
winget install --id Git.Git -e --source winget
2.	Restart the terminal. Verify: git --version
3.	Set identity and defaults:
4.	git config --global user.name "Your Full Name"
5.	git config --global user.email "your.email@example.com"
6.	git config --global init.defaultBranch main
git config --global core.editor "code --wait"
________________________________________
4.2 First-time: Prepare the DC server (Windows Server 2025)
When: New DC host before promoting to domain controller.
Steps:
1.	Set static IP (adjust interface name if needed):
2.	New-NetIPAddress -InterfaceAlias "Ethernet 2" -IPAddress 192.168.1.10 -PrefixLength 24
Set-DnsClientServerAddress -InterfaceAlias "Ethernet 2" -ServerAddresses 192.168.1.10
3.	Rename (optional; config uses BB-DC01):
Rename-Computer -NewName "BARM-DC-01" -Restart
4.	Install Windows Updates (Settings → Windows Update).
5.	Install RSAT (AD + GPMC):
6.	Install-WindowsFeature -Name RSAT-AD-PowerShell -IncludeAllSubFeature
Install-WindowsFeature -Name GPMC
________________________________________
4.3 First-time: Install PowerShell 7 and DSC modules
When: Before compiling or applying DSC.
Steps:
1.	Install PowerShell 7:
winget install -e --id Microsoft.PowerShell -s winget
Verify: $PSVersionTable.PSVersion
2.	Install DSC modules (elevated if saving to Program Files):
3.	Save-PSResource -Name ActiveDirectoryDsc -Version 6.6.0 -Repository PSGallery -Path "C:\Program Files\WindowsPowerShell\Modules" -TrustRepository
4.	Save-PSResource -Name ComputerManagementDsc -Repository PSGallery -Path "C:\Program Files\WindowsPowerShell\Modules" -TrustRepository
Save-PSResource -Name NetworkingDsc -Repository PSGallery -Path "C:\Program Files\WindowsPowerShell\Modules" -TrustRepository
Verify: Get-Module -ListAvailable -Name ActiveDirectoryDsc, ComputerManagementDsc, NetworkingDsc
________________________________________
4.4 Compile and apply StudentBaseline 
When: Initial domain build or after changing StudentBaseline.ps1 / AllNodes.psd1.
Steps:
1.	Open PowerShell in the repo root (where StudentBaseline.ps1 and AllNodes.psd1 live).
2.	Compile only (recommended first to check for errors):
.\Apply-Configuration.ps1 -CompileOnly
Enter Domain Admin, DSRM, and default user password when prompted.
3.	Apply on the DC (run on the DC, typically as Administrator):
.\Apply-Configuration.ps1 -Apply
Or manually:
Start-DscConfiguration -Path .\StudentBaseline -Wait -Verbose -Force
4.	Verify:
.\Apply-Configuration.ps1 -Test
Or: Test-DscConfiguration -Path .\StudentBaseline
Note: WinClient node (BB-WIN11-01) is compiled here but applied when that machine runs DSC (pull or push). For a single-DC lab, applying on the DC applies only the localhost (DC) node.
________________________________________
4.5 Add a new AD user
When: You need a new user in the domain (e.g. Bolton Users OU).
Option A – Via configuration (recommended for consistency):
1.	Edit AllNodes.psd1. Under the DC node’s ADUsers array, add a block like:
2.	@{
3.	    Key                 = 'jane_analyst'
4.	    UserName            = 'jane.analyst'
5.	    GivenName           = 'Jane'
6.	    Surname             = 'Analyst'
7.	    DisplayName         = 'Jane Analyst'
8.	    UserPrincipalName   = 'jane.analyst@barmbuzz.corp'
9.	    OUPath              = 'OU=Users,OU=Bolton,OU=Sites,OU=BarmBuzz'
10.	    DependsOnKey        = 'Bolton_Users'
11.	    GroupMembership     = @('GG_BB_IT_Helpdesk')
12.	    JobTitle            = 'IT Analyst'
13.	    Department          = 'IT'
14.	    Description         = 'IT team'
15.	    ChangePasswordAtLogon = 'true'
}
16.	Recompile and re-apply (see 4.4). New users get the default password from the credential; set "Change password at logon" as above.
Option B – One-off via PowerShell:
$cred = Get-Credential   # Domain Admin
New-ADUser -Name "jane.analyst" -GivenName "Jane" -Surname "Analyst" `
  -UserPrincipalName "jane.analyst@barmbuzz.corp" `
  -Path "OU=Users,OU=Bolton,OU=Sites,OU=BarmBuzz,DC=barmbuzz,DC=corp" `
  -AccountPassword (ConvertTo-SecureString "TempPassword1!" -AsPlainText -Force) `
  -ChangePasswordAtLogon $true -Enabled $true -Credential $cred
Add-ADGroupMember -Identity "GG_BB_IT_Helpdesk" -Members "jane.analyst" -Credential $cred

Add a new OU or security group
When: New OU or group required (e.g. new site or role).
Steps:
1.	Edit AllNodes.psd1:
o	OU: Add an entry to OrgnizationalUnits with Key, Name, ParentPath, DependsOnKey, Protected, Description.
o	Group: Add an entry to SecurityGroups with Key, GroupName, GroupScope, Category, OUPath, DependsOnKey, MembersToInclude (if any), Description.
2.	Recompile: .\Apply-Configuration.ps1 -CompileOnly
3.	Apply on DC: .\Apply-Configuration.ps1 -Apply or Start-DscConfiguration -Path .\StudentBaseline -Wait -Verbose -Force


Join a new Windows client to the domain
When: A new workstation (e.g. BB-WIN11-02) must join barmbuzz.corp.
Option A – In DSC config:
1.	Add a new node block in AllNodes.psd1 under AllNodes (copy BB-WIN11-01 and change NodeName, ComputerName, DnsServerAddress, JoinOU if needed).
2.	Recompile. Push or pull the configuration to the new node so that node runs its MOF.
Option B – Manual one-off:
On the client, set DNS to the DC (e.g. 192.168.1.10), then:
Add-Computer -DomainName "barmbuzz.corp" -OUPath "OU=Windows,OU=Clients,OU=BarmBuzz,DC=barmbuzz,DC=corp" -Credential (Get-Credential)
Restart-Computer
 Generate operational/audit evidence
When: You need to prove change activity and local command history for audit/handover.
Steps:
1.	From repo root:
2.	git log --all --decorate --graph --oneline > git_history_evidence.txt
git reflog > git_reflog_evidence.txt
3.	Confirm remote: git remote -v (capture output if required).
4.	Include git_history_evidence.txt and git_reflog_evidence.txt in the handover package or change ticket.

Run Pester tests
When: After writing/changing tests, before handover, or before planned change windows.
Steps:
1.	Install Pester (once):
Save-PSResource -Name Pester -Version 5.7.1 -Repository PSGallery -Path "C:\Program Files\WindowsPowerShell\Modules" -TrustRepository
2.	Run tests:
3.	Import-Module Pester
Invoke-Pester -Path . -Output Detailed
(Adjust -Path to your test script or folder.)

5. Verification checklist
Use after apply or when troubleshooting.
Check	Command or action
Domain exists	Get-ADDomain
DC name / IP	hostname; Get-NetIPAddress -AddressFamily IPv4
OUs	`Get-ADOrganizationalUnit -Filter *
Security groups	`Get-ADGroup -Filter *
Users in OU	Get-ADUser -Filter * -SearchBase "OU=Users,OU=Bolton,OU=Sites,OU=BarmBuzz,DC=barmbuzz,DC=corp"
Password policy	Get-ADDefaultDomainPasswordPolicy
DSC status	Get-DscConfigurationStatus
DSC in desired state	Test-DscConfiguration -Path .\StudentBaseline
________________________________________
 Troubleshooting:
Client cannot join domain (DNS or trust)
•	Symptom: "Domain not found" or "trust relationship" errors.
•	Action: On client, set DNS to the DC’s IP (e.g. 192.168.1.10). Ping the DC by name. Ensure Domain Admin credential is correct and account is enabled.
MOF not found when applying
•	Symptom: Start-DscConfiguration cannot find configuration.
•	Action: Run from the directory that contains the StudentBaseline folder (MOF output). Run .\Apply-Configuration.ps1 -CompileOnly first to generate MOFs.

 Rollback and recovery
Config apply caused unwanted changes
•	Prevention: Test with -CompileOnly and review MOF; run in a lab first.
•	Recovery: Fix StudentBaseline.ps1 or AllNodes.psd1, recompile, and re-apply. DSC will bring state back to the new desired state. For one-off mistakes (e.g. wrong user), fix in AD (GUI or Set-ADUser / Remove-ADUser) and optionally update config to match.
Domain controller promotion failed or DC broken
•	Recovery: Use DSRM (Directory Services Restore Mode) if the DC is still bootable. Document DSRM password (used in config as Safe Mode password). For full rebuild, demote if possible (Uninstall-WindowsFeature AD-Domain-Services and clean metadata), then re-run the configuration from a clean OS.
Restore from Git
•	Action: Revert local changes: git checkout -- StudentBaseline.ps1 Allnodes.psd1. Recompile and re-apply.

 Support model and escalation
Ownership
•	Primary owner: Platform/Infrastructure engineer.
•	Secondary owner: Support engineer (cross-trained).
•	Backup: Team lead or designated on-call engineer.
Incident priority guide
Priority	Example	Target response
P1	DC unavailable, domain auth outage	Immediate (on-call)
P2	Failed DSC apply impacting onboarding/changes	< 4 hours
P3	Non-blocking drift, documentation mismatch	Next business day
 
