# This script requires you to run "Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope LocalMachine -Force" in Windows PowerShell version 5.1

$ErrorActionPreference = "SilentlyContinue"
$ProgressPreference = "SilentlyContinue"

function Initialize-PSSession {
    Clear-Host
    if (([System.Console]::OutputEncoding).CodePage -ne "65001") {
        [System.Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    }
    $PATH = "$env:SystemRoot\System32" + ";" + "$env:SystemRoot\System32\WindowsPowerShell\v1.0" + ";" + "$env:LOCALAPPDATA\Microsoft\WindowsApps" + ";" + "$env:LOCALAPPDATA\Microsoft\WinGet\Links" + ";" + "$env:ProgramFiles\Git\cmd"
    if ($env:PATH -ne $PATH) {
        $env:PATH = $PATH
    }
    if ($env:USERNAME -eq "WDAGUtilityAccount") {
        if (-not(Get-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer -Name SmartScreenEnabled)) {
            Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer -Name SmartScreenEnabled -Value Off -Force
        }
    }
    Get-WindowsOSBuild
}

function Get-WindowsOSBuild {
    if ((Get-ItemProperty -Path $env:SystemRoot\System32\ntoskrnl.exe).VersionInfo.ProductBuildPart -lt "19045") {
        Write-Host "This script requires Windows 10 version 22H2 or later to run." -ForegroundColor Red
        Write-Host
        cmd /c pause
        break
    }
    Initialize-WinGetSoftware
}

function Initialize-WinGetSoftware {
    if (-not(Get-Command -Name winget) -or (winget --version).TrimStart("v").Split("-")[0] -lt "1.5.101") {
        Write-Host "Downloading WinGet..."
        Invoke-WebRequest -Uri https://github.com/ItzLevvie/winget-pkgs-validate-and-install/releases/download/20230124.1/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle -OutFile $env:TEMP\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle
        if ($env:PROCESSOR_ARCHITECTURE -eq "AMD64") {
            Invoke-WebRequest -Uri https://github.com/ItzLevvie/winget-pkgs-validate-and-install/releases/download/20230124.1/Microsoft.VCLibs.140.00.UWPDesktop_x64_8wekyb3d8bbwe.appx -OutFile $env:TEMP\Microsoft.VCLibs.140.00.UWPDesktop_8wekyb3d8bbwe.appx
            Invoke-WebRequest -Uri https://github.com/ItzLevvie/winget-pkgs-validate-and-install/releases/download/20230124.1/Microsoft.UI.Xaml.2.7_x64_8wekyb3d8bbwe.appx -OutFile $env:TEMP\Microsoft.UI.Xaml.2.7_8wekyb3d8bbwe.appx
        } elseif ($env:PROCESSOR_ARCHITECTURE -eq "x86") {
            Invoke-WebRequest -Uri https://github.com/ItzLevvie/winget-pkgs-validate-and-install/releases/download/20230124.1/Microsoft.VCLibs.140.00.UWPDesktop_x86_8wekyb3d8bbwe.appx -OutFile $env:TEMP\Microsoft.VCLibs.140.00.UWPDesktop_8wekyb3d8bbwe.appx
            Invoke-WebRequest -Uri https://github.com/ItzLevvie/winget-pkgs-validate-and-install/releases/download/20230124.1/Microsoft.UI.Xaml.2.7_x86_8wekyb3d8bbwe.appx -OutFile $env:TEMP\Microsoft.UI.Xaml.2.7_8wekyb3d8bbwe.appx
        } else {
            Invoke-WebRequest -Uri https://github.com/ItzLevvie/winget-pkgs-validate-and-install/releases/download/20230124.1/Microsoft.VCLibs.140.00.UWPDesktop_arm64_8wekyb3d8bbwe.appx -OutFile $env:TEMP\Microsoft.VCLibs.140.00.UWPDesktop_8wekyb3d8bbwe.appx
            Invoke-WebRequest -Uri https://github.com/ItzLevvie/winget-pkgs-validate-and-install/releases/download/20230124.1/Microsoft.UI.Xaml.2.7_arm64_8wekyb3d8bbwe.appx -OutFile $env:TEMP\Microsoft.UI.Xaml.2.7_8wekyb3d8bbwe.appx
        }
        Write-Host "Installing WinGet..."
        Add-AppxPackage -Path $env:TEMP\Microsoft.VCLibs.140.00.UWPDesktop_8wekyb3d8bbwe.appx -DeferRegistrationWhenPackagesAreInUse
        Add-AppxPackage -Path $env:TEMP\Microsoft.UI.Xaml.2.7_8wekyb3d8bbwe.appx -DeferRegistrationWhenPackagesAreInUse
        Add-AppxPackage -Path $env:TEMP\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle -ForceApplicationShutdown
        Write-Host
    }
    Initialize-WinGetSoftware2
}

function Initialize-WinGetSoftware2 {
    if (-not(Test-Path -Path $env:LOCALAPPDATA\Packages\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\LocalState\settings.json -PathType Leaf)) {
        if (([System.Security.Principal.WindowsIdentity]::GetCurrent()).Owner.Value -eq "S-1-5-32-544") {
            Invoke-WebRequest -Uri https://github.com/ItzLevvie/winget-pkgs-validate-and-install/releases/download/20230124.1/settings.json -OutFile $env:LOCALAPPDATA\Packages\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\LocalState\settings.json
            winget settings --enable LocalManifestFiles > $null
            winget settings --enable InstallerHashOverride > $null
            winget settings --enable LocalArchiveMalwareScanOverride > $null
            winget source remove --name msstore > $null
            winget source update --name winget > $null
        } else {
            Write-Host "This script requires administrator privileges to initialize WinGet for the first time." -ForegroundColor Red
            Write-Host
            cmd /c pause
            break
        }
    }
    Initialize-GitSoftware
}

function Initialize-GitSoftware {
    if (-not(Get-Command -Name git) -or (git version).TrimStart("git version").Split(".")[0] + "." + (git version).TrimStart("git version").Split(".")[1] + "." + (git version).TrimStart("git version").Split(".")[2] -lt "2.39.1") {
        Write-Host "Downloading Git..."
        if ($env:PROCESSOR_ARCHITECTURE -eq "AMD64") {
            Invoke-WebRequest -Uri https://github.com/ItzLevvie/winget-pkgs-validate-and-install/releases/download/20230217.1/Git-prerelease-64-bit.exe -OutFile $env:TEMP\Git-prerelease.exe
        } else {
            Invoke-WebRequest -Uri https://github.com/ItzLevvie/winget-pkgs-validate-and-install/releases/download/20230217.1/Git-prerelease-32-bit.exe -OutFile $env:TEMP\Git-prerelease.exe
        }
        Write-Host "Installing Git..."
        Start-Process -FilePath $env:TEMP\Git-prerelease.exe -ArgumentList "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART" -Wait
        Write-Host
    }
    Initialize-GitHubRepository
}

function Initialize-GitHubRepository {
    $REPOSITORY_DIRECTORY = "$env:USERPROFILE\Documents\GitHub\winget-pkgs"
    if (-not(Test-Path -Path $REPOSITORY_DIRECTORY\.git -PathType Container)) {
        Write-Host "Cloning the WinGet package repository..."
        git config --global --add safe.directory $REPOSITORY_DIRECTORY.Replace("\", "/")
        git clone --quiet --no-checkout --branch master --single-branch --no-tags https://github.com/microsoft/winget-pkgs $REPOSITORY_DIRECTORY
        git -C $REPOSITORY_DIRECTORY remote add upstream https://github.com/microsoft/winget-pkgs
        git -C $REPOSITORY_DIRECTORY config --local gc.auto 0
        git -C $REPOSITORY_DIRECTORY config --local core.ignoreCase true
        git -C $REPOSITORY_DIRECTORY config --local core.quotePath false
        git -C $REPOSITORY_DIRECTORY config --local user.name $env:COMPUTERNAME
        git -C $REPOSITORY_DIRECTORY config --local user.email "$env:COMPUTERNAME.local"
        git -C $REPOSITORY_DIRECTORY sparse-checkout set --no-cone !/*
        Write-Host
    }
    Request-GitHubPullRequest
}

function Request-GitHubPullRequest {
    Clear-Host
    git -C $REPOSITORY_DIRECTORY sparse-checkout set --no-cone !/*
    git -C $REPOSITORY_DIRECTORY fetch --no-write-fetch-head --quiet upstream master
    git -C $REPOSITORY_DIRECTORY reset --quiet --hard upstream/master
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
    git -C $REPOSITORY_DIRECTORY sparse-checkout set --no-cone !/*
    git -C $REPOSITORY_DIRECTORY fetch --no-write-fetch-head --quiet upstream master
    git -C $REPOSITORY_DIRECTORY reset --quiet --hard upstream/master
    git -C $REPOSITORY_DIRECTORY pull --quiet upstream refs/pull/$PULL_REQUEST_NUMBER/head > $null
    if ($LASTEXITCODE -ne 0) {
        Write-Host
        Write-Host "This script requires the pull request to be valid and have no merge conflicts." -ForegroundColor Red
        Write-Host
        Reset-GitHubRepository
    }
    Read-GitHubPullRequest
}

function Read-GitHubPullRequest {
    $PACKAGE_VERSION_DIRECTORY = (git -C $REPOSITORY_DIRECTORY diff --dirstat=files --diff-filter=d upstream/master...FETCH_HEAD).TrimStart(" 100.0% ").TrimEnd("/")
    if ($PACKAGE_VERSION_DIRECTORY.GetType().Name -eq "Object[]") {
        Write-Host
        Write-Host "This script requires the pull request to have only one package." -ForegroundColor Red
        Write-Host
        Reset-GitHubRepository
    }
    git -C $REPOSITORY_DIRECTORY sparse-checkout set $PACKAGE_VERSION_DIRECTORY
    Start-WinGetValidation
}

function Start-WinGetValidation {
    powershell Start-Process -FilePath powershell -ArgumentList "{ New-PSDrive -Name HCR -PSProvider Registry -Root HKEY_CLASSES_ROOT; Remove-Item -Path HCR:\Installer\* -Recurse -Force; Remove-Item -Path @('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*') -Recurse -Force }" -Verb RunAs -WindowStyle Hidden -Wait > $null
    if ($LASTEXITCODE -ne 0) {
        Write-Host
        Write-Host "This script requires you to accept UAC." -ForegroundColor Red
        Write-Host
        Stop-WinGetValidation
    }
    Write-Host
    winget validate --manifest $REPOSITORY_DIRECTORY\$($PACKAGE_VERSION_DIRECTORY.Replace("/", "\"))
    if ($LASTEXITCODE -eq -1978335191) {
        Write-Host
        Stop-WinGetValidation
    }
    winget install --manifest $REPOSITORY_DIRECTORY\$($PACKAGE_VERSION_DIRECTORY.Replace("/", "\")) --ignore-local-archive-malware-scan --accept-package-agreements
    if ($LASTEXITCODE -ne 0) {
        Write-Host
        Stop-WinGetValidation
    }
    Find-InstalledSoftware
}

function Find-InstalledSoftware {
    if ((winget show --manifest $REPOSITORY_DIRECTORY\$($PACKAGE_VERSION_DIRECTORY.Replace("/", "\"))).Trim().Contains("Installer Type: msix")) {
        Write-Host
        Write-Host @"
Name              : $((Get-AppxPackage | Select-Object -Last 1 | Get-AppxPackageManifest).Package.Properties.DisplayName)
Publisher         : $((Get-AppxPackage | Select-Object -Last 1 | Get-AppxPackageManifest).Package.Properties.PublisherDisplayName)
Version           : $((Get-AppxPackage | Select-Object -Last 1 | Get-AppxPackageManifest).Package.Identity.Version)
PackageFamilyName : $((Get-AppxPackage | Select-Object -Last 1).PackageFamilyName)
Uninstall         : winget uninstall --id "$((Get-AppxPackage | Select-Object -Last 1).PackageFamilyName)"
"@
        Write-Host
    } else {
        Get-ItemProperty -Path @("HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*", "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*", "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*") |
        Sort-Object -Property DisplayName |
        Select-Object -Property DisplayName, Publisher, DisplayVersion, PSChildName, PSPath, UninstallString, SystemComponent |
        Where-Object -FilterScript { $_.DisplayName -ne $null -and $_.SystemComponent -ne 1 } |
        ForEach-Object -Process {
            Write-Host
            Write-Host @"
Name          : $($_.DisplayName)
Publisher     : $($_.Publisher)
Version       : $($_.DisplayVersion)
ProductCode   : $($_.PSChildName)
Registry Path : $(($_.PSPath).Replace("Microsoft.PowerShell.Core\Registry::", "Computer\"))
Uninstall     : winget uninstall --id "$($_.PSChildName)"
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
    git -C $REPOSITORY_DIRECTORY sparse-checkout set --no-cone !/*
    git -C $REPOSITORY_DIRECTORY fetch --no-write-fetch-head --quiet upstream master
    git -C $REPOSITORY_DIRECTORY reset --quiet --hard upstream/master
    cmd /c pause
    Request-GitHubPullRequest
}

Initialize-PSSession
