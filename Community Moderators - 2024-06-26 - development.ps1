$ErrorActionPreference = "SilentlyContinue"
$ProgressPreference = "SilentlyContinue"

function Initialize-PSSession {
    Clear-Host
    [System.Int32]$CP_CURRENT = $OutputEncoding.CodePage
    [System.Int32]$CP_MINIMUM = 65001
    if ($CP_CURRENT -ne $CP_MINIMUM) {
        $OutputEncoding = [System.Text.Encoding]::UTF8
    }
    $PATH = "$env:SystemRoot\System32" + ";" + "$env:LOCALAPPDATA\Microsoft\WindowsApps" + ";" + "$env:ProgramFiles\Git\cmd" + ";" + "$env:LOCALAPPDATA\Microsoft\WinGet\Links"
    if ($env:PATH -ne $PATH) {
        $env:PATH = $PATH
    }
    Find-OSBuild
}

function Find-OSBuild {
    [System.Int32]$OS_BUILD_CURRENT = (Get-ItemProperty -Path $env:SystemRoot\System32\ntoskrnl.exe).VersionInfo.ProductBuildPart
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
    $SmartScreen = (Get-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer).SmartScreenEnabled
    if ($SmartScreen -ne "Off") {
        New-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer -Name SmartScreenEnabled -Value Off -Force
    }
    Initialize-WinGet
}

function Initialize-WinGet {
    $WINGET_COMMAND = Get-Command -CommandType Application -Name winget.exe
    [System.Version]$WINGET_VERSION_CURRENT = (winget --version).TrimStart("v")
    [System.Version]$WINGET_VERSION_MINIMUM = "1.10.280"
    if (-not($WINGET_COMMAND) -or $WINGET_VERSION_CURRENT -lt $WINGET_VERSION_MINIMUM) {
        Write-Host "Downloading WinGet..."
        Invoke-WebRequest -Uri https://github.com/ItzLevvie/winget-pkgs-validate-and-install/releases/download/20250208.1/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle -OutFile $env:TEMP\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle
        Invoke-WebRequest -Uri https://github.com/ItzLevvie/winget-pkgs-validate-and-install/releases/download/20250208.1/Microsoft.VCLibs.140.00.UWPDesktop_x64_8wekyb3d8bbwe.appx -OutFile $env:TEMP\Microsoft.VCLibs.140.00.UWPDesktop_x64_8wekyb3d8bbwe.appx
        Invoke-WebRequest -Uri https://github.com/ItzLevvie/winget-pkgs-validate-and-install/releases/download/20250208.1/Microsoft.UI.Xaml.2.8_x64_8wekyb3d8bbwe.appx -OutFile $env:TEMP\Microsoft.UI.Xaml.2.8_x64_8wekyb3d8bbwe.appx
        Write-Host "Installing WinGet..."
        Add-AppxPackage -Path $env:TEMP\Microsoft.VCLibs.140.00.UWPDesktop_x64_8wekyb3d8bbwe.appx -DeferRegistrationWhenPackagesAreInUse
        Add-AppxPackage -Path $env:TEMP\Microsoft.UI.Xaml.2.8_x64_8wekyb3d8bbwe.appx -DeferRegistrationWhenPackagesAreInUse
        Add-AppxPackage -Path $env:TEMP\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle -ForceApplicationShutdown
        Write-Host
    }
    Set-WinGetSettings
}

function Set-WinGetSettings {
    $WINGET_SETTINGS = Test-Path -Path $env:LOCALAPPDATA\Packages\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\LocalState\settings.json -PathType Leaf
    if (-not($WINGET_SETTINGS)) {
        if ([System.Security.Principal.WindowsIdentity]::GetCurrent().Owner -eq "S-1-5-32-544") {
            Invoke-WebRequest -Uri https://github.com/ItzLevvie/winget-pkgs-validate-and-install/releases/download/20240321.1/settings.json -OutFile $env:LOCALAPPDATA\Packages\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\LocalState\settings.json
            winget settings --enable LocalManifestFiles
            winget settings --enable BypassCertificatePinningForMicrosoftStore
            winget settings --enable InstallerHashOverride
            winget settings --enable LocalArchiveMalwareScanOverride
            winget settings --enable ProxyCommandLineOptions
            winget source remove --name msstore
            winget source update --name winget
        }
        else {
            Write-Host "This script requires administrator privileges to initialize WinGet for the first time." -ForegroundColor Red
            Write-Host
            cmd /c pause
            break
        }
    }
    Initialize-Git
}

function Initialize-Git {
    $GIT_COMMAND = Get-Command -CommandType Application -Name git.exe
    [System.Version]$GIT_VERSION_CURRENT = (git version).TrimStart("git version").Split(".")[0] + "." + (git version).TrimStart("git version").Split(".")[1] + "." + (git version).TrimStart("git version").Split(".")[2]
    [System.Version]$GIT_VERSION_MINIMUM = "2.48.0"
    if (-not($GIT_COMMAND) -or $GIT_VERSION_CURRENT -lt $GIT_VERSION_MINIMUM) {
        Write-Host "Downloading Git..."
        Invoke-WebRequest -Uri https://github.com/ItzLevvie/winget-pkgs-validate-and-install/releases/download/20250208.1/Git-64-bit.exe -OutFile $env:TEMP\Git-64-bit.exe
        Write-Host "Installing Git..."
        Start-Process -FilePath $env:TEMP\Git-64-bit.exe -ArgumentList "/SP- /VERYSILENT /SUPPRESSMSGBOXES /NORESTART" -Wait
        Write-Host
    }
    Set-GitSettings
}

function Set-GitSettings {
    git config --global checkout.workers 0
    git config --global user.name $env:COMPUTERNAME
    git config --global user.email "$env:COMPUTERNAME.internal"
    Initialize-Repository
}

function Initialize-Repository {
    $REPOSITORY_DIRECTORY = "$env:USERPROFILE\Documents\GitHub\winget-pkgs"
    if (-not(Test-Path -Path $REPOSITORY_DIRECTORY\.git -PathType Container)) {
        Write-Host "Cloning the WinGet package repository..."
        git clone --no-checkout --sparse --branch master --single-branch --no-tags https://github.com/microsoft/winget-pkgs $REPOSITORY_DIRECTORY
        git -C $REPOSITORY_DIRECTORY remote add upstream https://github.com/microsoft/winget-pkgs
        Write-Host
    }
    Request-PR
}

function Request-PR {
    Reset-Repository
    Clear-Host
    $PR_NUMBER = Read-Host -Prompt "Enter a pull request number"
    $PR_NUMBER = $PR_NUMBER.Trim()
    if ([String]::IsNullOrWhiteSpace($PR_NUMBER)) {
        Request-PR
    }
    elseif ($PR_NUMBER.StartsWith("https://github.com/microsoft/winget-pkgs/pull/")) {
        $PR_NUMBER = $PR_NUMBER.TrimStart("https://github.com/microsoft/winget-pkgs/pull/").TrimEnd("/files")
    }
    elseif ($PR_NUMBER.StartsWith("pull/")) {
        $PR_NUMBER = $PR_NUMBER.TrimStart("pull/").TrimEnd("/files")
    }
    elseif ($PR_NUMBER.StartsWith("#")) {
        $PR_NUMBER = $PR_NUMBER.TrimStart("#")
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
    if ($PACKAGE_VERSION_DIRECTORY.GetType().Name -eq "Object[]") {
        Write-Host
        Write-Host "This script requires the pull request to have only one package." -ForegroundColor Red
        Write-Host
        cmd /c pause
        Request-PR
    }
    git -C $REPOSITORY_DIRECTORY sparse-checkout set $PACKAGE_VERSION_DIRECTORY
    git -C $REPOSITORY_DIRECTORY pull --no-edit --force upstream refs/pull/$PR_NUMBER/head
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
    $PACKAGE_VERSION_DIRECTORY_FULL_PATH = $REPOSITORY_DIRECTORY + "\" + $PACKAGE_VERSION_DIRECTORY.Replace("/", "\")
    winget validate --manifest $PACKAGE_VERSION_DIRECTORY_FULL_PATH
    if ($LASTEXITCODE -eq -1978335191) {
        Write-Host
        cmd /c pause
        Request-PR
    }
    winget install --manifest $PACKAGE_VERSION_DIRECTORY_FULL_PATH
    if ($LASTEXITCODE -ne 0) {
        Write-Host
        cmd /c pause
        Request-PR
    }
    Find-InstalledSoftware
}

function Find-InstalledSoftware {
    $WINGET_SHOW_MSIX = (winget show --manifest $PACKAGE_VERSION_DIRECTORY_FULL_PATH).Trim().Contains("Installer Type: msix")
    $APPX_PACKAGE = Get-AppxPackage | Select-Object -Last 1
    $APPX_PACKAGE_MANIFEST = ($APPX_PACKAGE | Get-AppxPackageManifest).Package.Properties
    if ($WINGET_SHOW_MSIX) {
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

Initialize-PSSession
