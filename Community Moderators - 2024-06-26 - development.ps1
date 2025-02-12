$ErrorActionPreference = "SilentlyContinue"
$ProgressPreference = "SilentlyContinue"

function Initialize-PSSession {
    Clear-Host
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
    [System.String]$SID_CURRENT = [System.Security.Principal.WindowsIdentity]::GetCurrent().Owner.Value
    [System.String]$SID_REQUIRED = "S-1-5-32-544"
    if ($SID_CURRENT -eq $SID_REQUIRED) {
        $EnableSmartScreen = (Get-ItemProperty -Path HKLM:\SOFTWARE\Policies\Microsoft\Windows\System).EnableSmartScreen
        if ($EnableSmartScreen -ne 0) {
            New-ItemProperty -Path HKLM:\SOFTWARE\Policies\Microsoft\Windows\System -Name EnableSmartScreen -Value 0 -Force
        }
        $LowRiskFileTypes = (Get-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Associations).LowRiskFileTypes
        if ($LowRiskFileTypes -ne ".exe;.msi") {
            New-Item -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Associations -Force
            New-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Associations -Name LowRiskFileTypes -Value ".exe;.msi" -Force
        }
    }
    else {
        Write-Host "This script requires administrator privileges to configure Windows for the first time." -ForegroundColor Red
        Write-Host
        cmd /c pause
        break
    }
    Initialize-WinGet
}

function Initialize-WinGet {
    [System.Boolean]$WINGET_COMMAND = Test-Path -Path $env:LOCALAPPDATA\Microsoft\WindowsApps\winget.exe -PathType Leaf
    [System.Version]$WINGET_VERSION_CURRENT = (winget --version).TrimStart("v")
    [System.Version]$WINGET_VERSION_MINIMUM = "1.10.280"
    if (-not($WINGET_COMMAND) -or $WINGET_VERSION_CURRENT -lt $WINGET_VERSION_MINIMUM) {
        Write-Host "Downloading WinGet..."
        Invoke-WebRequest -Uri https://github.com/ItzLevvie/winget-pkgs-validate-and-install/releases/download/20250212.1/Microsoft.UI.Xaml.2.8_x64_8wekyb3d8bbwe.appx -OutFile $env:TEMP\Microsoft.UI.Xaml.2.8_x64_8wekyb3d8bbwe.appx
        Invoke-WebRequest -Uri https://github.com/ItzLevvie/winget-pkgs-validate-and-install/releases/download/20250212.1/Microsoft.VCLibs.140.00.UWPDesktop_x64_8wekyb3d8bbwe.appx -OutFile $env:TEMP\Microsoft.VCLibs.140.00.UWPDesktop_x64_8wekyb3d8bbwe.appx
        Invoke-WebRequest -Uri https://github.com/ItzLevvie/winget-pkgs-validate-and-install/releases/download/20250212.1/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle -OutFile $env:TEMP\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle
        Write-Host "Installing WinGet..."
        Add-AppxPackage -Path $env:TEMP\Microsoft.UI.Xaml.2.8_x64_8wekyb3d8bbwe.appx -DeferRegistrationWhenPackagesAreInUse
        Add-AppxPackage -Path $env:TEMP\Microsoft.VCLibs.140.00.UWPDesktop_x64_8wekyb3d8bbwe.appx -DeferRegistrationWhenPackagesAreInUse
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
            Invoke-WebRequest -Uri https://github.com/ItzLevvie/winget-pkgs-validate-and-install/releases/download/20250212.1/settings.json -OutFile $env:LOCALAPPDATA\Packages\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\LocalState\settings.json
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
    [System.Version]$GIT_VERSION_CURRENT = (git version).TrimStart("git version").Split(".")[0] + "." + (git version).TrimStart("git version").Split(".")[1] + "." + (git version).TrimStart("git version").Split(".")[2]
    [System.Version]$GIT_VERSION_MINIMUM = "2.48.0"
    if (-not($GIT_COMMAND) -or $GIT_VERSION_CURRENT -lt $GIT_VERSION_MINIMUM) {
        Write-Host "Downloading Git..."
        Invoke-WebRequest -Uri https://github.com/ItzLevvie/winget-pkgs-validate-and-install/releases/download/20250212.1/Git-64-bit.exe -OutFile $env:TEMP\Git-64-bit.exe
        Write-Host "Installing Git..."
        Start-Process -FilePath $env:TEMP\Git-64-bit.exe -ArgumentList "/SP- /VERYSILENT /SUPPRESSMSGBOXES /NORESTART" -Wait
        Write-Host
    }
    Set-GitSettings
}

function Set-GitSettings {
    git config --global checkout.workers 0
    git config --global fetch.parallel 0
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
        git clone --no-checkout --sparse --branch master --shallow-since=2024-09-01 --single-branch --no-tags https://github.com/microsoft/winget-pkgs $REPOSITORY_DIRECTORY
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
    if ([System.String]::IsNullOrWhiteSpace($PR_NUMBER)) {
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
    # git -C $REPOSITORY_DIRECTORY pull --no-edit --force upstream refs/pull/$PR_NUMBER/head
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
    powershell Start-Process -FilePath powershell -ArgumentList "{ New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT ; Remove-Item -Path HKLM:\Software\Microsoft\Windows\CurrentVersion\Installer -Recurse -Force ; Remove-Item -Path HKLM:\Software\Microsoft\Windows\CurrentVersion\Installer -Recurse -Force ; Remove-Item -Path HKCU:\Software\Microsoft\Installer -Recurse -Force ; Remove-Item -Path HKCR:\Installer -Recurse -Force ; Remove-Item -Path @('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall', 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall', 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall') -Recurse -Force }" -Verb runas -Wait
    if ($LASTEXITCODE -ne 0) {
        Write-Host
        Write-Host "This script requires you to accept UAC." -ForegroundColor Red
        Write-Host
        cmd /c pause
        Request-PR
    }
    $PACKAGE_VERSION_DIRECTORY_FULL_PATH = $REPOSITORY_DIRECTORY + "\" + $PACKAGE_VERSION_DIRECTORY.Replace("/", "\")
    Write-Host
    winget validate --manifest $PACKAGE_VERSION_DIRECTORY_FULL_PATH
    [System.Int32]$WINGET_MANIFEST_FAILURE = -1978335191
    if ($LASTEXITCODE -eq $WINGET_MANIFEST_FAILURE) {
        Write-Host
        cmd /c pause
        Request-PR
    }
    winget install --manifest $PACKAGE_VERSION_DIRECTORY_FULL_PATH --accept-package-agreements
    [System.Int32]$WINGET_INSTALL_HASH_MISMATCH = -1978335215
    if ($LASTEXITCODE -eq $WINGET_INSTALL_HASH_MISMATCH) {
        $WINGET_TEMP_DIRECTORY = "$env:LOCALAPPDATA\Temp\WinGet"
        $WINGET_TEMP_PACKAGE_DIRECTORY = ($PACKAGE_VERSION_DIRECTORY -replace "^manifests\/[a-z0-9]\/", "").Replace("/", ".")

        # Expected
        $WINGET_TEMP_PACKAGE_DIRECTORY_FULL_PATH_1 = (Get-ChildItem -Path $WINGET_TEMP_DIRECTORY\$WINGET_TEMP_PACKAGE_DIRECTORY | Sort-Object -Property LastWriteTime | Select-Object -Last 1).Name.ToUpper()

        # Actual
        $WINGET_TEMP_PACKAGE_DIRECTORY_FULL_PATH_2 = (Get-ChildItem -Path $WINGET_TEMP_DIRECTORY\$WINGET_TEMP_PACKAGE_DIRECTORY | Sort-Object -Property LastWriteTime | Select-Object -Last 1).FullName
        $WINGET_TEMP_PACKAGE_DIRECTORY_HASH_2 = (Get-FileHash -Path $WINGET_TEMP_PACKAGE_DIRECTORY_FULL_PATH_2).Hash

        Write-Host
        Write-Host "InstallerSha256 (expected) : $WINGET_TEMP_PACKAGE_DIRECTORY_FULL_PATH_1" -ForegroundColor Red
        Write-Host "InstallerSha256 (actual)   : $WINGET_TEMP_PACKAGE_DIRECTORY_HASH_2" -ForegroundColor Green
        Write-Host
        cmd /c pause
        Request-PR
    }
    else {
        Write-Host
        cmd /c pause
        Request-PR
    }
    Update-Path
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
