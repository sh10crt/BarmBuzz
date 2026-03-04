Describe "StudentConfig DSC Checks" {

    # Check 1: StudentConfig.ps1 file exists
    It "StudentConfig.ps1 file should exist" {
        Test-Path "$PSScriptRoot\DSC\Configurations\StudentConfig.ps1" | Should -BeTrue
    }

    # Check 2: AllNodes.psd1 file exists
    It "AllNodes.psd1 data file should exist" {
        Test-Path "$PSScriptRoot\DSC\Data\AllNodes.psd1" | Should -BeTrue
    }

    # Check 3: StudentBaseline configuration is defined
    It "StudentBaseline configuration should be defined" {
        . "$PSScriptRoot\DSC\Configurations\StudentConfig.ps1"
        Get-Command StudentBaseline -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }

    # Check 4: AllNodes.psd1 contains the 'AllNodes' key
    It "AllNodes.psd1 must contain 'AllNodes' key" {
        $AllNodesData = Import-PowerShellDataFile -Path "$PSScriptRoot\DSC\Data\AllNodes.psd1"
        $AllNodesData.ContainsKey('AllNodes') | Should -BeTrue
    }

    # Check 5: AllNodes contains localhost node
    It "AllNodes must include NodeName = 'localhost'" {
        $AllNodesData = Import-PowerShellDataFile -Path "$PSScriptRoot\DSC\Data\AllNodes.psd1"
        $localhostNode = $AllNodesData.AllNodes | Where-Object { $_.NodeName -eq 'localhost' }
        $localhostNode | Should -Not -BeNullOrEmpty
    }
}