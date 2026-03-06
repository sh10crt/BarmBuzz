# Design Notes (Student)

Explain your decisions:
- OU structure rationale
- Group model rationale
- GPO linking choices (later)
- Any security controls you applied

Structure
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