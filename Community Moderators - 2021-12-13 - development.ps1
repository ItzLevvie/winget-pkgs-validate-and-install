# Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser -Force

$ErrorActionPreference = "SilentlyContinue"
$ProgressPreference = "SilentlyContinue"

function Initialize-Session {
    Clear-Host
    [System.Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $env:Path = $env:SystemRoot + "\System32" + ";" + $env:SystemRoot + "\System32\WindowsPowerShell\v1.0" + ";" + $env:LOCALAPPDATA + "\Microsoft\WindowsApps" + ";" + $env:ProgramFiles + "\Git\cmd"
    Get-Build
}

function Get-Build {
    $BUILD = (Get-ItemPropertyValue -Path "HKLM:SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name CurrentBuild)
    if ($BUILD -lt 19041) {
        Write-Host -ForegroundColor Red "This script requires Windows 10 version 20H1 or later."
        Write-Host
        cmd /c pause
        break
    }
    Initialize-WinGet
}

function Initialize-WinGet {
    if (-not(Get-Command -Name winget) -or (Get-AppxPackage -Name Microsoft.DesktopAppInstaller).Version -lt "1.17.3411.0") {
        if (([System.Security.Principal.WindowsIdentity]::GetCurrent()).Owner.Value -eq "S-1-5-32-544") {
            Write-Host Downloading WinGet...
            Invoke-WebRequest -Uri https://github.com/ItzLevvie/winget-pkgs-validate-and-install/releases/download/20211211.1/Microsoft.DesktopAppInstaller_neutral_8wekyb3d8bbwe.msixbundle -OutFile $env:TEMP\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle
            if ($env:PROCESSOR_ARCHITECTURE -eq "AMD64") {
                Invoke-WebRequest -Uri https://github.com/ItzLevvie/winget-pkgs-validate-and-install/releases/download/20211211.1/Microsoft.VCLibs.140.00.UWPDesktop_x64_8wekyb3d8bbwe.appx -OutFile $env:TEMP\Microsoft.VCLibs.140.00.UWPDesktop_8wekyb3d8bbwe.appx
                Invoke-WebRequest -Uri https://github.com/ItzLevvie/winget-pkgs-validate-and-install/releases/download/20211211.1/Microsoft.UI.Xaml.2.7_x64_8wekyb3d8bbwe.appx -OutFile $env:TEMP\Microsoft.UI.Xaml.2.7_8wekyb3d8bbwe.appx
            } elseif ($env:PROCESSOR_ARCHITECTURE -eq "x86") {
                Invoke-WebRequest -Uri https://github.com/ItzLevvie/winget-pkgs-validate-and-install/releases/download/20211211.1/Microsoft.VCLibs.140.00.UWPDesktop_x86_8wekyb3d8bbwe.appx -OutFile $env:TEMP\Microsoft.VCLibs.140.00.UWPDesktop_8wekyb3d8bbwe.appx
                Invoke-WebRequest -Uri https://github.com/ItzLevvie/winget-pkgs-validate-and-install/releases/download/20211211.1/Microsoft.UI.Xaml.2.7_x86_8wekyb3d8bbwe.appx -OutFile $env:TEMP\Microsoft.UI.Xaml.2.7_8wekyb3d8bbwe.appx
            } else {
                Invoke-WebRequest -Uri https://github.com/ItzLevvie/winget-pkgs-validate-and-install/releases/download/20211211.1/Microsoft.VCLibs.140.00.UWPDesktop_arm64_8wekyb3d8bbwe.appx -OutFile $env:TEMP\Microsoft.VCLibs.140.00.UWPDesktop_8wekyb3d8bbwe.appx
                Invoke-WebRequest -Uri https://github.com/ItzLevvie/winget-pkgs-validate-and-install/releases/download/20211211.1/Microsoft.UI.Xaml.2.7_arm64_8wekyb3d8bbwe.appx -OutFile $env:TEMP\Microsoft.UI.Xaml.2.7_8wekyb3d8bbwe.appx
            }
            Write-Host Installing WinGet...
            Add-AppxPackage -Path $env:TEMP\Microsoft.VCLibs.140.00.UWPDesktop_8wekyb3d8bbwe.appx
            Add-AppxPackage -Path $env:TEMP\Microsoft.UI.Xaml.2.7_8wekyb3d8bbwe.appx
            Add-AppxPackage -Path $env:TEMP\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle -ForceApplicationShutdown
            New-Item -Path $env:LOCALAPPDATA\Packages\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\LocalState\settings.json -ItemType File -Force > $null
@"
{
    "network": {"downloader": "wininet"},
    "source": {"autoUpdateIntervalInMinutes": 0},
    "visual": {"progressBar": "rainbow"}
}
"@ | Set-Content -Path $env:LOCALAPPDATA\Packages\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\LocalState\settings.json -Force
            winget settings --enable LocalManifestFiles > $null
            winget source remove --name msstore > $null
            winget source update --name winget > $null
            Write-Host
        } else {
            Write-Host -ForegroundColor Red "This script requires administrator privileges to initialize WinGet."
            Write-Host
            cmd /c pause
            break
        }
    }
    Initialize-Git
}

function Initialize-Git {
    $GIT_VERSION = (git version).Trim("git version").Split(".")[0] + "." + (git version).Trim("git version").Split(".")[1] + "." + (git version).Trim("git version").Split(".")[2]
    if (-not(Get-Command -Name git) -or ($GIT_VERSION -lt "2.34.1")) {
        Write-Host Downloading Git...
        if ($env:PROCESSOR_ARCHITECTURE -eq "AMD64") {
            Invoke-WebRequest -Uri https://github.com/ItzLevvie/winget-pkgs-validate-and-install/releases/download/20211211.1/Git-prerelease-64-bit.exe -OutFile $env:TEMP\Git-prerelease.exe
        } else {
            Invoke-WebRequest -Uri https://github.com/ItzLevvie/winget-pkgs-validate-and-install/releases/download/20211211.1/Git-prerelease-32-bit.exe -OutFile $env:TEMP\Git-prerelease.exe
        }
        Write-Host Installing Git...
        Start-Process -FilePath $env:TEMP\Git-prerelease.exe -ArgumentList "/VERYSILENT /SUPPRESSMSGBOXES" -Wait
        Write-Host
    }
    Initialize-Repository
}

function Initialize-Repository {
    $REPOSITORY_DIRECTORY = $env:USERPROFILE + "\Documents\GitHub\winget-pkgs"
    if (-not(Test-Path -Path $REPOSITORY_DIRECTORY\.git)) {
        Write-Host "Cloning the package repository for WinGet..."
        git config --global checkout.workers 0
        git clone --quiet --branch master --single-branch --no-tags https://github.com/microsoft/winget-pkgs $REPOSITORY_DIRECTORY > $null
        git -C $REPOSITORY_DIRECTORY remote add upstream https://github.com/microsoft/winget-pkgs
        git -C $REPOSITORY_DIRECTORY config --local core.ignoreCase true
        git -C $REPOSITORY_DIRECTORY config --local core.quotePath false
        git -C $REPOSITORY_DIRECTORY config --local user.name $env:COMPUTERNAME
        git -C $REPOSITORY_DIRECTORY config --local user.email "$env:COMPUTERNAME.local"
        Write-Host
    }
    Find-PR
}

function Find-PR {
    Clear-Host
    $NUMBER = Read-Host -Prompt "Enter a pull request number"
    $NUMBER = $NUMBER.Trim()
    if (-not($NUMBER)) {
        Find-PR
    } elseif (($NUMBER).StartsWith("https://github.com/microsoft/winget-pkgs/pull/")) {
        $NUMBER = $NUMBER.TrimStart("https://github.com/microsoft/winget-pkgs/pull/").TrimEnd("/files")
    } elseif (($NUMBER).StartsWith("pull/")) {
        $NUMBER = $NUMBER.TrimStart("pull/").TrimEnd("/files")
    } elseif (($NUMBER).StartsWith("#")) {
        $NUMBER = $NUMBER.TrimStart("#")
    }
    Get-PR
}

function Get-PR {
    git -C $REPOSITORY_DIRECTORY fetch --no-write-fetch-head --quiet upstream master
    git -C $REPOSITORY_DIRECTORY reset --quiet --hard upstream/master
    git -C $REPOSITORY_DIRECTORY pull --quiet upstream refs/pull/$NUMBER/head
    if ($LASTEXITCODE -ne 0) {
        Find-PR
    }
    Read-PR
}

function Read-PR {
    $PACKAGE_MANIFEST_PATH = (git -C $REPOSITORY_DIRECTORY diff --name-only --diff-filter=d upstream/master...FETCH_HEAD)
    $PACKAGE_VERSION_DIRECTORIES = (git -C $REPOSITORY_DIRECTORY diff --dirstat=files --diff-filter=d upstream/master...FETCH_HEAD)
    if ($PACKAGE_MANIFEST_PATH.GetType().Name -eq "Object[]") {
        if ($PACKAGE_VERSION_DIRECTORIES.Count -gt 1) {
            Write-Host
            Write-Host -ForegroundColor Red "This script requires the pull request to have only one package."
            Write-Host
            Reset-Repository
        }
        $PACKAGE_VERSION_DIRECTORY = (Get-Item -Path (Resolve-Path -Path ($REPOSITORY_DIRECTORY + "\" + $PACKAGE_MANIFEST_PATH[0]))).DirectoryName
    } else {
        $PACKAGE_VERSION_DIRECTORY = (Get-Item -Path (Resolve-Path -Path ($REPOSITORY_DIRECTORY + "\" + $PACKAGE_MANIFEST_PATH))).DirectoryName
    }
    Invoke-Validation
}

function Get-Installed {
    $REGISTRY_PATHS = @("HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*", "HKLM:SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*", "HKCU:Software\Microsoft\Windows\CurrentVersion\Uninstall\*")
    return Get-ItemProperty -Path $REGISTRY_PATHS | Sort-Object DisplayName | Select-Object DisplayName, Publisher, DisplayVersion, PSChildName, UninstallString | Where-Object {$_.DisplayName -ne $null -and $_.UninstallString -ne $null}
}

function Invoke-Validation {
    Write-Host
    winget validate --manifest $PACKAGE_VERSION_DIRECTORY
    if ($LASTEXITCODE -eq -1978335191) {
        Complete-Validation
    }
    $ARP = Get-Installed
    winget install --manifest $PACKAGE_VERSION_DIRECTORY
    if ($LASTEXITCODE -ne 0) {
        Write-Host
        Complete-Validation
    }
    Find-Installed
}

function Find-Installed {
    $MSIX = (winget show --manifest $PACKAGE_DIRECTORY).Contains("  Type: msix")
    if ($MSIX -eq $true) {
        $NAME = (Get-AppxPackage | Select-Object -Last 1 | Get-AppxPackageManifest).Package.Properties.DisplayName
        $PUBLISHER = (Get-AppxPackage | Select-Object -Last 1 | Get-AppxPackageManifest).Package.Properties.PublisherDisplayName
        $VERSION = (Get-AppxPackage | Select-Object -Last 1 | Get-AppxPackageManifest).Package.Identity.Version
        $PFN = (Get-AppxPackage | Select-Object -Last 1).PackageFamilyName
        Write-Host
        Write-Host
        Write-Host
        Write-Host @"
Name              : $NAME
Publisher         : $PUBLISHER
Version           : $VERSION
PackageFamilyName : $PFN
Uninstall         : winget uninstall "$PFN"
"@
        Write-Host
        Write-Host
        Write-Host
    } else {
        Write-Host
        Compare-Object -ReferenceObject (Get-Installed) -DifferenceObject $ARP -Property DisplayName, Publisher, DisplayVersion, PSChildName, UninstallString | Select-Object -Property DisplayName, Publisher, DisplayVersion, PSChildName, UninstallString | Format-List @{Label = "Name"; Expression = {$_.DisplayName}}, @{Label = "Publisher"; Expression = {$_.Publisher}}, @{Label = "Version"; Expression = {$_.DisplayVersion}}, @{Label = "ProductCode"; Expression = {$_.PSChildName}}, @{Label = "Uninstall"; Expression = {if ($_.UninstallString -ne $null) { "winget uninstall " + """" + $_.PSChildName + """" }}}
    }
    Complete-Validation
}

function Complete-Validation {
    Reset-Repository
}

function Reset-Repository {
    git -C $REPOSITORY_DIRECTORY fetch --no-write-fetch-head --quiet upstream master
    git -C $REPOSITORY_DIRECTORY reset --quiet --hard upstream/master
    cmd /c pause
    Find-PR
}

Initialize-Session
