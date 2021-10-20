# Profile for All Users, Current Host
#   See: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_profiles?view=powershell-7.1

if (-not (Get-InstalledModule -ErrorAction Ignore -Name posh-git)) {
    Install-Module posh-git -Force
}
Import-Module posh-git

# Uncomment one of these based on your org/team
$env:AzureSubscriptionId="8a53cb9a-a3a5-4602-aa2d-8c171edde3c7" # John Mogensen's org (Actions_Platform_Eng)
# $env:AzureSubscriptionId="16eb6e57-e88b-49c9-8acb-26048bee1f93" # c2c-actions-compute specifically (VCFP_Eng)
# $env:AzureSubscriptionId="ed693d19-8167-4d94-9193-b21025975b8f" # Youhana's org (Actions_Core_Eng)
$env:AzureRegion = "eastus"

# Set some POSH Git settings
$GitPromptSettings.DefaultPromptAbbreviateHomeDirectory = $true
$GitPromptSettings.DefaultPromptPrefix.Text = '$(if ($env:SKYRISEV3) { "Skyrise " } else { "" })'
$GitPromptSettings.DefaultPromptPrefix.ForegroundColor = [ConsoleColor]::Magenta

