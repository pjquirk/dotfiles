# Profile for All Users, Current Host
#   See: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_profiles?view=powershell-7.1

if (-not (Get-InstalledModule -ErrorAction Ignore -Name posh-git)) {
    Install-Module posh-git -Force
}
Import-Module posh-git

# Uncomment one of these based on your org/team
# $env:AzureSubscriptionId="8a53cb9a-a3a5-4602-aa2d-8c171edde3c7" # John Mogensen's org (Actions_Platform_Eng)
# $env:AzureSubscriptionId="16eb6e57-e88b-49c9-8acb-26048bee1f93" # c2c-actions-compute specifically (VCFP_Eng)
# $env:AzureSubscriptionId="ed693d19-8167-4d94-9193-b21025975b8f" # Youhana's org (Actions_Core_Eng)
$env:AzureSubscriptionId="9ed6f940-4ca4-4512-a8f8-a08f8d151201" # GHA: GitHub - NonProd - Compute Products - Actions Platform
$env:AzureRegion = "eastus"

# Set some POSH Git settings
$GitPromptSettings.DefaultPromptAbbreviateHomeDirectory = $true
$GitPromptSettings.DefaultPromptPrefix.Text = '$(if ($env:SKYRISEV3) { "Skyrise " } else { "" })'
$GitPromptSettings.DefaultPromptPrefix.ForegroundColor = [ConsoleColor]::Magenta

#
# Helper functions
#

function New-Tracepoint {
    do
    {
        # Truncate to get last two digits equal to zero
        $tp = Get-Random -Minimum 10000 -Maximum 21474836
        # Search for a commonly used pattern since we can't search for partial tracepoints
        $testTracepoint = '{0}01' -f $tp
        # Check if it exists in the source already
        $count = & gh api -H "Accept: application/vnd.github.v3+json" "/search/code?q=$testTracepoint%20repo:github/actions-dotnet%20extension:cs&per_page=1" |
            ConvertFrom-Json |
            Select-Object -ExpandProperty 'total_count'
    } while ($count -gt 0)
    return '{0}00' -f $tp
}
