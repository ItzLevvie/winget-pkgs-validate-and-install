# Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser -Force

$ErrorActionPreference = "SilentlyContinue"
$ProgressPreference = "SilentlyContinue"

function Initialize-PSSession {
    Clear-Host
    [System.Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $env:Path = "$env:SystemRoot\System32" + ";" + "$env:SystemRoot\System32\WindowsPowerShell\v1.0" + ";" + "$env:LOCALAPPDATA\Microsoft\WindowsApps" + ";" + "$env:ProgramFiles\Git\cmd"
    Get-WindowsOSBuild
}

function Get-WindowsOSBuild {
    if ((Get-ItemProperty -Path $env:SystemRoot\System32\ntoskrnl.exe).VersionInfo.ProductBuildPart -lt 19041) {
        Write-Host "This script requires Windows 10 version 20H1 or later." -ForegroundColor Red
        Write-Host
        cmd /c pause
        break
    }
    Initialize-WinGetSoftware
}

function Initialize-WinGetSoftware {
    if (-not(Get-Command -Name winget) -or (winget --version).TrimStart("v").Split("-")[0] -lt "1.2.3411") {
        if (([System.Security.Principal.WindowsIdentity]::GetCurrent()).Owner.Value -eq "S-1-5-32-544") {
            Write-Host "Downloading WinGet..."
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
            Write-Host "Installing WinGet..."
            Add-AppxPackage -Path $env:TEMP\Microsoft.VCLibs.140.00.UWPDesktop_8wekyb3d8bbwe.appx
            Add-AppxPackage -Path $env:TEMP\Microsoft.UI.Xaml.2.7_8wekyb3d8bbwe.appx
            Add-AppxPackage -Path $env:TEMP\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle -ForceApplicationShutdown
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
            Write-Host "This script requires administrator privileges to initialize WinGet." -ForegroundColor Red
            Write-Host
            cmd /c pause
            break
        }
    }
    Initialize-GitSoftware
}

function Initialize-GitSoftware {
    if (-not(Get-Command -Name git) -or (git version).TrimStart("git version").Split(".")[0] + "." + (git version).TrimStart("git version").Split(".")[1] + "." + (git version).TrimStart("git version").Split(".")[2] -lt "2.34.1") {
        Write-Host "Downloading Git..."
        if ($env:PROCESSOR_ARCHITECTURE -eq "AMD64") {
            Invoke-WebRequest -Uri https://github.com/ItzLevvie/winget-pkgs-validate-and-install/releases/download/20211215.1/Git-prerelease-64-bit.exe -OutFile $env:TEMP\Git-prerelease.exe
        } else {
            Invoke-WebRequest -Uri https://github.com/ItzLevvie/winget-pkgs-validate-and-install/releases/download/20211215.1/Git-prerelease-32-bit.exe -OutFile $env:TEMP\Git-prerelease.exe
        }
        Write-Host "Installing Git..."
        Start-Process -FilePath $env:TEMP\Git-prerelease.exe -ArgumentList "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART" -Wait
        Write-Host
    }
    Initialize-GitHubRepository
}

function Initialize-GitHubRepository {
    $REPOSITORY_DIRECTORY = "$env:USERPROFILE\Documents\GitHub\winget-pkgs"
    if (-not(Test-Path -Path $REPOSITORY_DIRECTORY\.git)) {
        Write-Host "Cloning the WinGet package repository..."
        git config --global checkout.workers 0
        git clone --quiet --no-checkout --branch master --single-branch --no-tags https://github.com/microsoft/winget-pkgs $REPOSITORY_DIRECTORY
        git -C $REPOSITORY_DIRECTORY remote add upstream https://github.com/microsoft/winget-pkgs
        git -C $REPOSITORY_DIRECTORY config --local core.ignoreCase true
        git -C $REPOSITORY_DIRECTORY config --local core.quotePath false
        git -C $REPOSITORY_DIRECTORY config --local user.name $env:COMPUTERNAME
        git -C $REPOSITORY_DIRECTORY config --local user.email "$env:COMPUTERNAME.local"
        git -C $REPOSITORY_DIRECTORY sparse-checkout set
        Write-Host
    }
    Request-GitHubPullRequest
}

function Request-GitHubPullRequest {
    Clear-Host
    git -C $REPOSITORY_DIRECTORY fetch --no-write-fetch-head --quiet upstream master
    git -C $REPOSITORY_DIRECTORY reset --quiet --hard upstream/master
    git -C $REPOSITORY_DIRECTORY sparse-checkout set
    $PULL_REQUEST_NUMBER = Read-Host -Prompt "Enter a pull request number"
    $PULL_REQUEST_NUMBER = $PULL_REQUEST_NUMBER.Trim()
    if (-not($PULL_REQUEST_NUMBER)) {
        Request-GitHubPullRequest
    } elseif ($PULL_REQUEST_NUMBER.StartsWith("https://github.com/microsoft/winget-pkgs/pull/")) {
        $PULL_REQUEST_NUMBER = $PULL_REQUEST_NUMBER.TrimStart("https://github.com/microsoft/winget-pkgs/pull/").TrimEnd("/files")
    } elseif ($PULL_REQUEST_NUMBER.StartsWith("pull/")) {
        $PULL_REQUEST_NUMBER = $PULL_REQUEST_NUMBER.TrimStart("pull/").TrimEnd("/files")
    } elseif ($PULL_REQUEST_NUMBER.StartsWith("#")) {
        $PULL_REQUEST_NUMBER = $PULL_REQUEST_NUMBER.TrimStart("#")
    }
    Get-GitHubPullRequest
}

function Get-GitHubPullRequest {
    git -C $REPOSITORY_DIRECTORY fetch --no-write-fetch-head --quiet upstream master
    git -C $REPOSITORY_DIRECTORY reset --quiet --hard upstream/master
    git -C $REPOSITORY_DIRECTORY sparse-checkout set
    git -C $REPOSITORY_DIRECTORY pull --quiet upstream refs/pull/$PULL_REQUEST_NUMBER/head > $null
    if ($LASTEXITCODE -ne 0) {
        Write-Host
        Write-Host "This script requires the pull request to have no merge conflicts." -ForegroundColor Red
        Write-Host
        Reset-GitHubRepository
    }
    Read-GitHubPullRequest
}

function Read-GitHubPullRequest {
    $PACKAGE_MANIFEST_FILE = (git -C $REPOSITORY_DIRECTORY diff --name-only --diff-filter=d upstream/master...FETCH_HEAD)
    if ($PACKAGE_MANIFEST_FILE.GetType().Name -eq "Object[]") {
        $PACKAGE_VERSION_DIRECTORIES = (git -C $REPOSITORY_DIRECTORY diff --dirstat=files --diff-filter=d upstream/master...FETCH_HEAD)
        if ($PACKAGE_VERSION_DIRECTORIES.Count -gt 1) {
            Write-Host
            Write-Host "This script requires the pull request to have only one package." -ForegroundColor Red
            Write-Host
            Reset-GitHubRepository
        }
        git -C $REPOSITORY_DIRECTORY sparse-checkout set (git -C $REPOSITORY_DIRECTORY diff --dirstat=files --diff-filter=d upstream/master...FETCH_HEAD).TrimStart(" 100.0% ").TrimEnd("/")
        $PACKAGE_VERSION_DIRECTORY = (Get-Item -Path (Resolve-Path -Path ($REPOSITORY_DIRECTORY + "\" + $PACKAGE_MANIFEST_FILE[0]))).DirectoryName
    } else {
        git -C $REPOSITORY_DIRECTORY sparse-checkout set (git -C $REPOSITORY_DIRECTORY diff --dirstat=files --diff-filter=d upstream/master...FETCH_HEAD).TrimStart(" 100.0% ").TrimEnd("/")
        $PACKAGE_VERSION_DIRECTORY = (Get-Item -Path (Resolve-Path -Path ($REPOSITORY_DIRECTORY + "\" + $PACKAGE_MANIFEST_FILE))).DirectoryName
    }
    Start-WinGetValidation
}

function Start-WinGetValidation {
    if (([System.Security.Principal.WindowsIdentity]::GetCurrent()).Owner.Value -eq "S-1-5-32-544" -or ([System.Security.Principal.WindowsIdentity]::GetCurrent()).Owner.Value -ne "S-1-5-32-544") {
        Start-Process -FilePath powershell -ArgumentList {$REGISTRY_PATHS = @("""HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*""", """HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*""", """HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"""); Remove-Item -Path $REGISTRY_PATHS} -Verb RunAs -WindowStyle Hidden -Wait
    }
    Write-Host
    winget validate --manifest $PACKAGE_VERSION_DIRECTORY
    if ($LASTEXITCODE -eq -1978335191) {
        Write-Host
        Stop-WinGetValidation
    }
    winget install --manifest $PACKAGE_VERSION_DIRECTORY
    if ($LASTEXITCODE -ne 0) {
        Write-Host
        Stop-WinGetValidation
    }
    Find-InstalledSoftware
}

function Find-InstalledSoftware {
    $IS_INSTALLER_TYPE_MSIX = (winget show --manifest $PACKAGE_VERSION_DIRECTORY).Contains("  Type: msix")
    if ($IS_INSTALLER_TYPE_MSIX -eq $true) {
        $NAME_MSIX = (Get-AppxPackage | Select-Object -Last 1 | Get-AppxPackageManifest).Package.Properties.DisplayName
        $PUBLISHER_MSIX = (Get-AppxPackage | Select-Object -Last 1 | Get-AppxPackageManifest).Package.Properties.PublisherDisplayName
        $VERSION_MSIX = (Get-AppxPackage | Select-Object -Last 1 | Get-AppxPackageManifest).Package.Identity.Version
        $PACKAGE_FAMILY_NAME_MSIX = (Get-AppxPackage | Select-Object -Last 1).PackageFamilyName
        Write-Host
        Write-Host @"
Name              : $NAME_MSIX
Publisher         : $PUBLISHER_MSIX
Version           : $VERSION_MSIX
PackageFamilyName : $PACKAGE_FAMILY_NAME_MSIX
Uninstall         : winget uninstall "$PACKAGE_FAMILY_NAME_MSIX"
"@
        Write-Host
    } else {
        $REGISTRY_PATHS = @("HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*", "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*", "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*")
        $ARP = Get-ItemProperty -Path $REGISTRY_PATHS | Sort-Object -Property DisplayName | Select-Object -Property DisplayName, Publisher, DisplayVersion, PSChildName, UninstallString | Where-Object {$_.DisplayName -ne $null -and $_.UninstallString -ne $null -and $_.DisplayName -notlike "* Additional Runtime *" -and $_.DisplayName -notlike "* Minimum Runtime *"}
        $ARP | ForEach-Object {
            $NAME_WIN32 = $_.DisplayName
            $PUBLISHER_WIN32 = $_.Publisher
            $VERSION_WIN32 = $_.DisplayVersion
            $PRODUCT_CODE_WIN32 = $_.PSChildName
            Write-Host @"

Name        : $NAME_WIN32
Publisher   : $PUBLISHER_WIN32
Version     : $VERSION_WIN32
ProductCode : $PRODUCT_CODE_WIN32
Uninstall   : winget uninstall "$PRODUCT_CODE_WIN32"
"@
        }
        Write-Host
    }
    Stop-WinGetValidation
}

function Stop-WinGetValidation {
    Reset-GitHubRepository
}

function Reset-GitHubRepository {
    git -C $REPOSITORY_DIRECTORY fetch --no-write-fetch-head --quiet upstream master
    git -C $REPOSITORY_DIRECTORY reset --quiet --hard upstream/master
    git -C $REPOSITORY_DIRECTORY sparse-checkout set
    cmd /c pause
    Request-GitHubPullRequest
}

Initialize-PSSession
