# This script requires you to run "Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope LocalMachine -Force" in PowerShell 5.1 or later.

$ErrorActionPreference = "SilentlyContinue"
$ProgressPreference = "SilentlyContinue"

function Initialize-PSSession {
    [System.Int32]$CP_CURRENT = $OutputEncoding.CodePage
    [System.Int32]$CP_REQUIRED = 65001
    if ($CP_CURRENT -ne $CP_REQUIRED) {
        $OutputEncoding = [System.Text.Encoding]::UTF8
    }
    [System.String]$PATH = "$env:SystemRoot\System32;$env:SystemRoot\System32\WindowsPowerShell\v1.0;$env:LOCALAPPDATA\Microsoft\WindowsApps;$env:ProgramFiles\Git\cmd"
    if ($env:PATH -ne $PATH) {
        $env:PATH = $PATH
    }
    Find-OSBuild
}

function Find-OSBuild {
    [System.Int32]$OS_BUILD_CURRENT = [System.Environment]::OSVersion.Version.Build
    [System.Int32]$OS_BUILD_MINIMUM = 19045
    if ($OS_BUILD_CURRENT -lt $OS_BUILD_MINIMUM) {
        Write-Host "This script requires Windows 10 version 22H2 or later to run." -ForegroundColor Red
        Write-Host
        cmd /c pause
        break
    }
    Set-WindowsSettings
}

function Set-WindowsSettings {
    [System.Boolean]$SETTINGS_CHECK = Test-Path -Path $env:TEMP\$env:COMPUTERNAME.internal -PathType Leaf
    [System.String]$SID_CURRENT = [System.Security.Principal.WindowsIdentity]::GetCurrent().Owner.Value
    [System.String]$SID_REQUIRED = "S-1-5-32-544"
    if (-not($SETTINGS_CHECK)) {
        if ($SID_CURRENT -eq $SID_REQUIRED) {
            netsh advfirewall set allprofiles state off
            powercfg /setactive e9a42b02-d5df-448d-aa00-03f14749eb61
            $EnableSmartScreen = (Get-ItemProperty -Path HKLM:\SOFTWARE\Policies\Microsoft\Windows\System).EnableSmartScreen
            if ($EnableSmartScreen -ne 0) {
                New-Item -Path HKLM:\SOFTWARE\Policies\Microsoft\Windows\System
                New-ItemProperty -Path HKLM:\SOFTWARE\Policies\Microsoft\Windows\System -PropertyType DWord -Name EnableSmartScreen -Value 0 -Force
            }
            $LowRiskFileTypes = (Get-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Associations).LowRiskFileTypes
            if ($LowRiskFileTypes -ne ".exe;.msi") {
                New-Item -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Associations
                New-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Associations -PropertyType String -Name LowRiskFileTypes -Value ".exe;.msi" -Force
            }
            $AllowDevelopmentWithoutDevLicense = (Get-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock).AllowDevelopmentWithoutDevLicense
            if ($AllowDevelopmentWithoutDevLicense -ne 1) {
                New-Item -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock
                New-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock -PropertyType DWord -Name AllowDevelopmentWithoutDevLicense -Value 1 -Force
            }
            $LongPathsEnabled = (Get-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem).LongPathsEnabled
            if ($LongPathsEnabled -ne 1) {
                New-Item -Path HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem
                New-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem -PropertyType DWord -Name LongPathsEnabled -Value 1 -Force
            }
            New-Item -Path $env:TEMP\$env:COMPUTERNAME.internal -ItemType File
        }
        else {
            Write-Host "This script requires administrator privileges to configure Windows for the first time." -ForegroundColor Red
            Write-Host
            cmd /c pause
            break
        }
    }
    Initialize-WinGet
}

function Initialize-WinGet {
    [System.Boolean]$WINGET_COMMAND = Test-Path -Path $env:LOCALAPPDATA\Microsoft\WindowsApps\winget.exe -PathType Leaf
    [System.Version]$WINGET_VERSION_CURRENT = (winget --version).TrimStart("v").TrimEnd("-preview")
    [System.Version]$WINGET_VERSION_MINIMUM = "1.11.220"
    if (-not($WINGET_COMMAND) -or $WINGET_VERSION_CURRENT -lt $WINGET_VERSION_MINIMUM) {
        Write-Host "Downloading WinGet..."
        if ($env:PROCESSOR_ARCHITECTURE -eq "AMD64") {
            Invoke-WebRequest -Uri https://github.com/ItzLevvie/winget-pkgs-validate-and-install/releases/download/20250522.1/Microsoft.UI.Xaml.2.8_x64_8wekyb3d8bbwe.appx -OutFile $env:TEMP\Microsoft.UI.Xaml.2.8_x64_8wekyb3d8bbwe.appx
            Invoke-WebRequest -Uri https://github.com/ItzLevvie/winget-pkgs-validate-and-install/releases/download/20250522.1/Microsoft.VCLibs.140.00.UWPDesktop_x64_8wekyb3d8bbwe.appx -OutFile $env:TEMP\Microsoft.VCLibs.140.00.UWPDesktop_x64_8wekyb3d8bbwe.appx
        }
        elseif ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") {
            Invoke-WebRequest -Uri https://github.com/ItzLevvie/winget-pkgs-validate-and-install/releases/download/20250522.1/Microsoft.UI.Xaml.2.8_arm64_8wekyb3d8bbwe.appx -OutFile $env:TEMP\Microsoft.UI.Xaml.2.8_arm64_8wekyb3d8bbwe.appx
            Invoke-WebRequest -Uri https://github.com/ItzLevvie/winget-pkgs-validate-and-install/releases/download/20250522.1/Microsoft.VCLibs.140.00.UWPDesktop_arm64_8wekyb3d8bbwe.appx -OutFile $env:TEMP\Microsoft.VCLibs.140.00.UWPDesktop_arm64_8wekyb3d8bbwe.appx
        }
        Invoke-WebRequest -Uri https://github.com/ItzLevvie/winget-pkgs-validate-and-install/releases/download/20250522.1/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle -OutFile $env:TEMP\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle
        Write-Host "Installing WinGet..."
        if ($env:PROCESSOR_ARCHITECTURE -eq "AMD64") {
            Add-AppxPackage -Path $env:TEMP\Microsoft.UI.Xaml.2.8_x64_8wekyb3d8bbwe.appx -DeferRegistrationWhenPackagesAreInUse
            Add-AppxPackage -Path $env:TEMP\Microsoft.VCLibs.140.00.UWPDesktop_x64_8wekyb3d8bbwe.appx -DeferRegistrationWhenPackagesAreInUse
        }
        elseif ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") {
            Add-AppxPackage -Path $env:TEMP\Microsoft.UI.Xaml.2.8_arm64_8wekyb3d8bbwe.appx -DeferRegistrationWhenPackagesAreInUse
            Add-AppxPackage -Path $env:TEMP\Microsoft.VCLibs.140.00.UWPDesktop_arm64_8wekyb3d8bbwe.appx -DeferRegistrationWhenPackagesAreInUse
        }
        Add-AppxPackage -Path $env:TEMP\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle -ForceApplicationShutdown
        Write-Host
    }
    Set-WinGetSettings
}

function Set-WinGetSettings {
    [System.Boolean]$WINGET_SETTINGS = Test-Path -Path $env:LOCALAPPDATA\Packages\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\LocalState\settings.json -PathType Leaf
    [System.String]$SID_CURRENT = [System.Security.Principal.WindowsIdentity]::GetCurrent().Owner.Value
    [System.String]$SID_REQUIRED = "S-1-5-32-544"
    if (-not($WINGET_SETTINGS)) {
        if ($SID_CURRENT -eq $SID_REQUIRED) {
            Invoke-WebRequest -Uri https://github.com/ItzLevvie/winget-pkgs-validate-and-install/releases/download/20250522.1/settings.json -OutFile $env:LOCALAPPDATA\Packages\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\LocalState\settings.json
            winget settings --enable LocalManifestFiles
            winget settings --enable BypassCertificatePinningForMicrosoftStore
            winget settings --enable InstallerHashOverride
            winget settings --enable LocalArchiveMalwareScanOverride
            winget settings --enable ProxyCommandLineOptions
            winget source remove --name msstore
            winget source update --name winget
        }
        else {
            Write-Host "This script requires administrator privileges to configure WinGet for the first time." -ForegroundColor Red
            Write-Host
            cmd /c pause
            break
        }
    }
    Initialize-Git
}

function Initialize-Git {
    [System.Boolean]$GIT_COMMAND = Test-Path -Path $env:ProgramFiles\Git\cmd\git.exe -PathType Leaf
    [System.String]$GIT_VERSION_COMMAND = git version
    [System.Version]$GIT_VERSION_CURRENT = $GIT_VERSION_COMMAND.TrimStart("git version").Split(".")[0] + "." + $GIT_VERSION_COMMAND.TrimStart("git version").Split(".")[1] + "." + $GIT_VERSION_COMMAND.TrimStart("git version").Split(".")[2]
    [System.Version]$GIT_VERSION_MINIMUM = "2.49.0"
    if (-not($GIT_COMMAND) -or $GIT_VERSION_CURRENT -lt $GIT_VERSION_MINIMUM) {
        Write-Host "Downloading Git..."
        if ($env:PROCESSOR_ARCHITECTURE -eq "AMD64") {
            Invoke-WebRequest -Uri https://github.com/ItzLevvie/winget-pkgs-validate-and-install/releases/download/20250522.1/Git-64-bit.exe -OutFile $env:TEMP\Git-64-bit.exe
        }
        elseif ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") {
            Invoke-WebRequest -Uri https://github.com/ItzLevvie/winget-pkgs-validate-and-install/releases/download/20250522.1/Git-arm64.exe -OutFile $env:TEMP\Git-arm64.exe
        }
        Write-Host "Installing Git..."
        if ($env:PROCESSOR_ARCHITECTURE -eq "AMD64") {
            Start-Process -FilePath $env:TEMP\Git-64-bit.exe -ArgumentList "/SP- /VERYSILENT /SUPPRESSMSGBOXES /NORESTART" -Wait
        }
        elseif ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") {
            Start-Process -FilePath $env:TEMP\Git-arm64.exe -ArgumentList "/SP- /VERYSILENT /SUPPRESSMSGBOXES /NORESTART" -Wait
        }
        Write-Host
    }
    Set-GitSettings
}

function Set-GitSettings {
    git config --global checkout.workers 0
    git config --global fetch.parallel 0
    git config --global core.quotePath false
    git config --global user.name $env:COMPUTERNAME
    git config --global user.email "$env:COMPUTERNAME.internal"
    Initialize-Repository
}

function Initialize-Repository {
    [System.String]$REPOSITORY_DIRECTORY = "$env:USERPROFILE\Documents\GitHub\winget-pkgs"
    [System.Boolean]$REPOSITORY_DIRECTORY_GIT_FOLDER = Test-Path -Path $REPOSITORY_DIRECTORY\.git -PathType Container
    if (-not($REPOSITORY_DIRECTORY_GIT_FOLDER)) {
        Write-Host "Cloning the WinGet package repository..."
        git config --global safe.directory $REPOSITORY_DIRECTORY.Replace("\", "/")
        git clone --no-checkout --sparse --branch master --shallow-since=2025-03-01 --single-branch --no-tags https://github.com/microsoft/winget-pkgs $REPOSITORY_DIRECTORY
        git -C $REPOSITORY_DIRECTORY remote add upstream https://github.com/microsoft/winget-pkgs
        Write-Host
    }
    Request-PR
}

function Request-PR {
    Reset-Repository
    $PR_NUMBER = Read-Host -Prompt "Enter a pull request number"
    $PR_NUMBER = $PR_NUMBER.Trim()
    if ($PR_NUMBER -match "^\d+$") {}
    elseif ($PR_NUMBER -match "^#\d+$") {
        $PR_NUMBER = $PR_NUMBER.TrimStart("#")
    }
    elseif ($PR_NUMBER -match "^pull\/\d+$") {
        $PR_NUMBER = $PR_NUMBER.TrimStart("pull/")
    }
    elseif ($PR_NUMBER -match "^https:\/\/github\.com\/microsoft\/winget-pkgs\/pull\/\d+") {
        $PR_NUMBER = $PR_NUMBER.TrimStart("https://github.com/microsoft/winget-pkgs/pull/").TrimEnd("/files")
    }
    else {
        Request-PR
    }
    Get-PR
}

function Get-PR {
    Reset-Repository
    git -C $REPOSITORY_DIRECTORY fetch --force upstream refs/pull/$PR_NUMBER/head
    Read-PR
}

function Read-PR {
    $PACKAGE_VERSION_DIRECTORY = (git -C $REPOSITORY_DIRECTORY diff --dirstat=files --diff-filter=d upstream/master...FETCH_HEAD).TrimStart(" 100.0% ").TrimEnd("/")
    if ($PACKAGE_VERSION_DIRECTORY -notmatch "^manifests\/[a-z0-9]\/") {
        Write-Host
        Write-Host "This script requires the pull request to contain a valid package." -ForegroundColor Red
        Write-Host
        cmd /c pause
        Request-PR
    }
    if ($PACKAGE_VERSION_DIRECTORY.GetType().Name -eq "Object[]") {
        Write-Host
        Write-Host "This script requires the pull request to have only one package." -ForegroundColor Red
        Write-Host
        cmd /c pause
        Request-PR
    }
    git -C $REPOSITORY_DIRECTORY sparse-checkout set $PACKAGE_VERSION_DIRECTORY
    git -C $REPOSITORY_DIRECTORY merge --no-edit FETCH_HEAD
    if ($LASTEXITCODE -eq 1) {
        Write-Host
        Write-Host "This script requires the pull request to be valid and have no merge conflicts." -ForegroundColor Red
        Write-Host
        cmd /c pause
        Request-PR
    }
    Start-WinGetValidation
}

function Start-WinGetValidation {
    powershell Start-Process -FilePath powershell -ArgumentList "{ New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT ; Remove-Item -Path HKLM:\Software\Microsoft\Windows\CurrentVersion\Installer -Recurse -Force ; Remove-Item -Path HKCU:\Software\Microsoft\Installer -Recurse -Force ; Remove-Item -Path HKCR:\Installer -Recurse -Force ; Remove-Item -Path @('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall', 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall', 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall') -Recurse -Force }" -Verb runas -Wait
    if ($LASTEXITCODE -ne 0) {
        Write-Host
        Write-Host "This script requires you to accept UAC." -ForegroundColor Red
        Write-Host
        cmd /c pause
        Request-PR
    }
    [System.String]$PACKAGE_VERSION_DIRECTORY_FULL_PATH = $REPOSITORY_DIRECTORY + "\" + $PACKAGE_VERSION_DIRECTORY.Replace("/", "\")
    Write-Host
    winget validate --manifest $PACKAGE_VERSION_DIRECTORY_FULL_PATH
    [System.Int32]$WINGET_VALIDATE_MANIFEST_FAILURE = -1978335191
    if ($LASTEXITCODE -eq $WINGET_VALIDATE_MANIFEST_FAILURE) {
        Write-Host
        cmd /c pause
        Request-PR
    }
    winget install --manifest $PACKAGE_VERSION_DIRECTORY_FULL_PATH --ignore-local-archive-malware-scan --accept-package-agreements
    [System.Int32]$WINGET_INSTALL_HASH_MISMATCH = -1978335215
    if ($LASTEXITCODE -eq $WINGET_INSTALL_HASH_MISMATCH) {
        [System.String]$WINGET_TEMP_DIRECTORY = "$env:LOCALAPPDATA\Temp\WinGet"
        [System.String]$WINGET_TEMP_PACKAGE_DIRECTORY = ($PACKAGE_VERSION_DIRECTORY -replace "^manifests\/[a-z0-9]\/", "").Replace("/", ".")

        # Expected
        [System.String]$WINGET_INSTALL_EXPECTED_HASH = (Get-ChildItem -Path $WINGET_TEMP_DIRECTORY\$WINGET_TEMP_PACKAGE_DIRECTORY | Sort-Object -Property LastWriteTime | Select-Object -Last 1).Name.ToUpper()

        # Actual
        [System.String]$WINGET_TEMP_PACKAGE_DIRECTORY_FULL_PATH_2 = (Get-ChildItem -Path $WINGET_TEMP_DIRECTORY\$WINGET_TEMP_PACKAGE_DIRECTORY | Sort-Object -Property LastWriteTime | Select-Object -Last 1).FullName
        [System.String]$WINGET_INSTALL_ACTUAL_HASH = (Get-FileHash -Path $WINGET_TEMP_PACKAGE_DIRECTORY_FULL_PATH_2).Hash

        Write-Host
        Write-Host "InstallerSha256 (expected) : $WINGET_INSTALL_EXPECTED_HASH" -ForegroundColor DarkRed
        Write-Host "InstallerSha256 (actual)   : $WINGET_INSTALL_ACTUAL_HASH" -ForegroundColor Green
        Write-Host
        cmd /c pause
        Request-PR
    }
    elseif ($LASTEXITCODE -ne 0) {
        Write-Host
        cmd /c pause
        Request-PR
    }
    Find-InstalledSoftware
}

function Find-InstalledSoftware {
    [System.Boolean]$WINGET_SHOW_MSIX = (winget show --manifest $PACKAGE_VERSION_DIRECTORY_FULL_PATH).Trim().Contains("Installer Type: msix")
    if ($WINGET_SHOW_MSIX) {
        $APPX_PACKAGE = Get-AppxPackage -PackageTypeFilter Main | Select-Object -Last 1
        $APPX_PACKAGE_MANIFEST = ($APPX_PACKAGE | Get-AppxPackageManifest).Package.Properties
        Write-Host
        Write-Host @"
Name              : $($APPX_PACKAGE_MANIFEST.DisplayName)
Publisher         : $($APPX_PACKAGE_MANIFEST.PublisherDisplayName)
Version           : $($APPX_PACKAGE.Version)
PackageFamilyName : $($APPX_PACKAGE.PackageFamilyName)
Uninstall         : winget uninstall -id "$($APPX_PACKAGE.PackageFamilyName)"
"@
        Write-Host
    }
    else {
        Get-ItemProperty -Path @("HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*", "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*", "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*") |
        Sort-Object -Property DisplayName |
        Where-Object -FilterScript { $null -ne $_.DisplayName -and $_.SystemComponent -ne 1 } |
        Select-Object -Property DisplayName, Publisher, DisplayVersion, PSChildName, PSDrive, PSPath |
        ForEach-Object -Process {
            Write-Host
            Write-Host @"
Name          : $($_.DisplayName)
Publisher     : $($_.Publisher)
Version       : $($_.DisplayVersion)
ProductCode   : $($_.PSChildName)
Scope         : $(($_.PSDrive.Name).Replace("HKLM", "Machine").Replace("HKCU", "User"))
Registry Path : $(($_.PSPath).Replace("Microsoft.PowerShell.Core\Registry::", "Computer\"))
Uninstall     : winget uninstall --id "$($_.PSChildName)"
"@
        }
        Write-Host
    }
    cmd /c pause
    Request-PR
}

function Reset-Repository {
    git -C $REPOSITORY_DIRECTORY fetch --no-write-fetch-head --force upstream master
    git -C $REPOSITORY_DIRECTORY reset --hard upstream/master
}

function Update-Path {
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")
}

Initialize-PSSession
