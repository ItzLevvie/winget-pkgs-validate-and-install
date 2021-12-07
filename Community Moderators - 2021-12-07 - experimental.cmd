@echo off
cls

:1
path %SystemRoot%\System32;%SystemRoot%\System32\WindowsPowerShell\v1.0;%LOCALAPPDATA%\Microsoft\WindowsApps;%ProgramFiles%\Git\cmd
for /f "tokens=6 delims=[]. " %%a in ('ver') do (
    set OS_BUILD=%%a
)
if %OS_BUILD% LSS 19042 (
    echo This script requires Windows 10 version 20H2 or later to run.
    echo:
    echo You will need to update your PC to the latest version of Windows.
    pause
    goto :EOF
)
reg query HKEY_USERS\S-1-5-19 1>nul 2>nul
if %ERRORLEVEL% EQU 1 (
    if not exist "%TEMP%\%COMPUTERNAME%.local" (
        echo This script requires administrator privileges to allow you to run local manifest files.
        echo:
        echo You will only need to do this once.
        pause
        goto :EOF
    )
)
if %ERRORLEVEL% EQU 0 (
    if not exist "%TEMP%\%COMPUTERNAME%.local" (
        @echo off > "%TEMP%\%COMPUTERNAME%.local"
    )
)
if not exist "%LOCALAPPDATA%\Microsoft\WindowsApps\winget.exe" (
    echo Downloading WinGet...
    curl --dns-ipv4-addr 1.1.1.1 --dns-ipv6-addr 2606:4700:4700::1111 --location --url https://github.com/ItzLevvie/winget-pkgs-validate-and-install/releases/download/20211207.1/Microsoft.DesktopAppInstaller_neutral_8wekyb3d8bbwe.msixbundle --output "%TEMP%\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle" 1>nul 2>nul
    if %PROCESSOR_ARCHITECTURE% EQU AMD64 (
        curl --dns-ipv4-addr 1.1.1.1 --dns-ipv6-addr 2606:4700:4700::1111 --location --url https://github.com/ItzLevvie/winget-pkgs-validate-and-install/releases/download/20211207.1/Microsoft.VCLibs.140.00.UWPDesktop_x64_8wekyb3d8bbwe.appx --output "%TEMP%\Microsoft.VCLibs.140.00.UWPDesktop_8wekyb3d8bbwe.appx" 1>nul 2>nul
    ) else if %PROCESSOR_ARCHITECTURE% EQU x86 (
        curl --dns-ipv4-addr 1.1.1.1 --dns-ipv6-addr 2606:4700:4700::1111 --location --url https://github.com/ItzLevvie/winget-pkgs-validate-and-install/releases/download/20211207.1/Microsoft.VCLibs.140.00.UWPDesktop_x86_8wekyb3d8bbwe.appx --output "%TEMP%\Microsoft.VCLibs.140.00.UWPDesktop_8wekyb3d8bbwe.appx" 1>nul 2>nul
    ) else (
        curl --dns-ipv4-addr 1.1.1.1 --dns-ipv6-addr 2606:4700:4700::1111 --location --url https://github.com/ItzLevvie/winget-pkgs-validate-and-install/releases/download/20211207.1/Microsoft.VCLibs.140.00.UWPDesktop_arm64_8wekyb3d8bbwe.appx --output "%TEMP%\Microsoft.VCLibs.140.00.UWPDesktop_8wekyb3d8bbwe.appx" 1>nul 2>nul
    )
    if %PROCESSOR_ARCHITECTURE% EQU AMD64 (
        curl --dns-ipv4-addr 1.1.1.1 --dns-ipv6-addr 2606:4700:4700::1111 --location --url https://github.com/ItzLevvie/winget-pkgs-validate-and-install/releases/download/20211207.1/Microsoft.UI.Xaml.2.6_x64_8wekyb3d8bbwe.appx --output "%TEMP%\Microsoft.UI.Xaml.2.6_8wekyb3d8bbwe.appx" 1>nul 2>nul
    ) else if %PROCESSOR_ARCHITECTURE% EQU x86 (
        curl --dns-ipv4-addr 1.1.1.1 --dns-ipv6-addr 2606:4700:4700::1111 --location --url https://github.com/ItzLevvie/winget-pkgs-validate-and-install/releases/download/20211207.1/Microsoft.UI.Xaml.2.6_x86_8wekyb3d8bbwe.appx --output "%TEMP%\Microsoft.UI.Xaml.2.6_8wekyb3d8bbwe.appx" 1>nul 2>nul
    ) else (
        curl --dns-ipv4-addr 1.1.1.1 --dns-ipv6-addr 2606:4700:4700::1111 --location --url https://github.com/ItzLevvie/winget-pkgs-validate-and-install/releases/download/20211207.1/Microsoft.UI.Xaml.2.6_arm64_8wekyb3d8bbwe.appx --output "%TEMP%\Microsoft.UI.Xaml.2.6_8wekyb3d8bbwe.appx" 1>nul 2>nul
    )
    echo Installing WinGet...
    powershell -Command "$ProgressPreference = 'SilentlyContinue' ; Add-AppxPackage -Path '%TEMP%\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle' -DependencyPath '%TEMP%\Microsoft.VCLibs.140.00.UWPDesktop_8wekyb3d8bbwe.appx','%TEMP%\Microsoft.UI.Xaml.2.6_8wekyb3d8bbwe.appx' -ForceApplicationShutdown -ForceUpdateFromAnyVersion" 1>nul 2>nul
    echo:
)
winget settings --enable LocalManifestFiles 1>nul 2>nul
winget source remove --name msstore 1>nul 2>nul
if not exist "%LOCALAPPDATA%\Packages\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\LocalState\settings.json" (
    (
        echo {
        echo     "network": {"downloader": "wininet"},
        echo     "visual": {"progressBar": "rainbow"}
        echo }
    ) > "%LOCALAPPDATA%\Packages\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\LocalState\settings.json"
)
reg delete HKCU\Software\Microsoft\Windows\CurrentVersion\Applets\Regedit\Favorites /f 1>nul 2>nul & reg add HKCU\Software\Microsoft\Windows\CurrentVersion\Applets\Regedit\Favorites /v Computer\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall /t REG_SZ /d Computer\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall /f 1>nul 2>nul && reg add HKCU\Software\Microsoft\Windows\CurrentVersion\Applets\Regedit\Favorites /v Computer\HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall /t REG_SZ /d Computer\HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall /f 1>nul 2>nul && reg add HKCU\Software\Microsoft\Windows\CurrentVersion\Applets\Regedit\Favorites /v Computer\HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Uninstall /t REG_SZ /d Computer\HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Uninstall /f 1>nul 2>nul
if not exist "%ProgramFiles%\Git\cmd\git.exe" (
    echo Downloading Git...
    if %PROCESSOR_ARCHITECTURE% EQU AMD64 (
        curl --dns-ipv4-addr 1.1.1.1 --dns-ipv6-addr 2606:4700:4700::1111 --location --url https://github.com/ItzLevvie/winget-pkgs-validate-and-install/releases/download/20211207.1/Git-prerelease-x64.exe --output "%TEMP%\Git-prerelease.exe" 1>nul 2>nul
    ) else (
        curl --dns-ipv4-addr 1.1.1.1 --dns-ipv6-addr 2606:4700:4700::1111 --location --url https://github.com/ItzLevvie/winget-pkgs-validate-and-install/releases/download/20211207.1/Git-prerelease-x86.exe --output "%TEMP%\Git-prerelease.exe" 1>nul 2>nul
    )
    echo Installing Git...
    "%TEMP%\Git-prerelease.exe" /VERYSILENT /SUPPRESSMSGBOXES
    echo:
)
set "REPOSITORY_PATH=%USERPROFILE%\Documents\GitHub\winget-pkgs"
if not exist "%REPOSITORY_PATH%\.git" (
    echo Cloning the package repository for WinGet ...
    git config --global checkout.workers 0 1>nul 2>nul
    git clone --branch master --single-branch https://github.com/microsoft/winget-pkgs "%REPOSITORY_PATH%" 1>nul 2>nul
    git -C "%REPOSITORY_PATH%" remote add upstream https://github.com/microsoft/winget-pkgs 1>nul 2>nul
    git -C "%REPOSITORY_PATH%" config --local core.ignoreCase true 1>nul 2>nul
    git -C "%REPOSITORY_PATH%" config --local core.quotePath false 1>nul 2>nul
    git -C "%REPOSITORY_PATH%" config --local user.name %COMPUTERNAME% 1>nul 2>nul
    git -C "%REPOSITORY_PATH%" config --local user.email %COMPUTERNAME%.local 1>nul 2>nul
    echo:
)
cls
goto :2

:2
set PR_NUMBER=
set /p PR_NUMBER="Enter a pull request number: "
if not defined PR_NUMBER (
    cls
    goto :2
)
echo:
echo %PR_NUMBER% | findstr /r /c:"^https://github.com/microsoft/winget-pkgs/pull/" 1>nul 2>nul && set "PR_NUMBER=%PR_NUMBER:~46%" && goto :3
echo %PR_NUMBER% | findstr /r /c:"^#" 1>nul 2>nul && set "PR_NUMBER=%PR_NUMBER:~1%" && goto :3
echo %PR_NUMBER% | findstr /r /c:"^pull/" 1>nul 2>nul && set "PR_NUMBER=%PR_NUMBER:~5%" && goto :3
goto :3

:3
git -C "%REPOSITORY_PATH%" fetch --no-write-fetch-head --force upstream master 1>nul 2>nul
git -C "%REPOSITORY_PATH%" reset --hard upstream/master 1>nul 2>nul
git -C "%REPOSITORY_PATH%" pull --force upstream refs/pull/%PR_NUMBER%/head 1>nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    cls
    goto :2
)
goto :4

:4
git -C "%REPOSITORY_PATH%" diff --name-only --diff-filter=d upstream/master...FETCH_HEAD | findstr /n "^" | findstr /r /c:"^1:manifests/" 1>nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo:
    goto :6
)
goto :5

:5
reg delete HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall /f 1>nul 2>nul && reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall /f 1>nul 2>nul
if %PROCESSOR_ARCHITECTURE% NEQ x86 (
    reg delete HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall /f 1>nul 2>nul && reg add HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall /f 1>nul 2>nul
)
reg delete HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall /f 1>nul 2>nul && reg add HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall /f 1>nul 2>nul
powershell -Command "Set-Location -Path '%REPOSITORY_PATH%' ; if ((git -C '%REPOSITORY_PATH%' diff --name-only --diff-filter=d upstream/master...FETCH_HEAD).GetType().Name -eq 'Object[]') { winget validate --manifest (Get-Item -Path (git -C '%REPOSITORY_PATH%' diff --name-only --diff-filter=d upstream/master...FETCH_HEAD)[0]).DirectoryName ; if ($LASTEXITCODE -eq -1978335191) { return } else { winget install --manifest (Get-Item -Path (git -C '%REPOSITORY_PATH%' diff --name-only --diff-filter=d upstream/master...FETCH_HEAD)[0]).DirectoryName ; Write-Host } } else { winget validate --manifest (Get-Item -Path (git -C '%REPOSITORY_PATH%' diff --name-only --diff-filter=d upstream/master...FETCH_HEAD)).DirectoryName ; if ($LASTEXITCODE -eq -1978335191) { return } else { winget install --manifest (Get-Item -Path (git -C '%REPOSITORY_PATH%' diff --name-only --diff-filter=d upstream/master...FETCH_HEAD)).DirectoryName ; Write-Host } }"
if %ERRORLEVEL% NEQ 0 (
    goto :6
)
echo Finding the application in the following registry paths below...
echo 1^) Computer\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall
if %PROCESSOR_ARCHITECTURE% NEQ x86 (
    echo 2^) Computer\HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall
    echo 3^) Computer\HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Uninstall
) else (
    echo 2^) Computer\HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Uninstall
)
echo:
powershell -Command "Get-ItemProperty -Path HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\* -Exclude \"{*}.KB*\" | Sort-Object DisplayName | Select-Object DisplayName, Publisher, DisplayVersion, PSChildName, PSPath, UninstallString | Where-Object {$_.PSChildName -NotMatch \"^WIC$\" -and $_.PSChildName -NotMatch \"^Connection Manager$\"} | Format-List @{Label = \"Name\" ; Expression = {$_.DisplayName}}, @{Label = \"Publisher\" ; Expression = {$_.Publisher}}, @{Label = \"Version\" ; Expression = {$_.DisplayVersion}}, @{Label = \"Product Code\" ; Expression = {$_.PSChildName}}, @{Label = \"Registry Path\" ; Expression = {$_.PSPath.Replace(\"Microsoft.PowerShell.Core\Registry::\", \"Computer\\\")}}, @{Label = \"Uninstall\" ; Expression = {if ($_.UninstallString) {\"winget uninstall \"\"\" + $_.PSChildName + \"\"\"\"}}}" 2>nul
if %PROCESSOR_ARCHITECTURE% NEQ x86 (
    powershell -Command "Get-ItemProperty -Path HKLM:SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* -Exclude \"{*}.KB*\" | Sort-Object DisplayName | Select-Object DisplayName, Publisher, DisplayVersion, PSChildName, PSPath, UninstallString | Where-Object {$_.PSChildName -NotMatch \"^WIC$\" -and $_.PSChildName -NotMatch \"^Connection Manager$\"} | Format-List @{Label = \"Name\" ; Expression = {$_.DisplayName}}, @{Label = \"Publisher\" ; Expression = {$_.Publisher}}, @{Label = \"Version\" ; Expression = {$_.DisplayVersion}}, @{Label = \"Product Code\" ; Expression = {$_.PSChildName}}, @{Label = \"Registry Path\" ; Expression = {$_.PSPath.Replace(\"Microsoft.PowerShell.Core\Registry::\", \"Computer\\\")}}, @{Label = \"Uninstall\" ; Expression = {if ($_.UninstallString) {\"winget uninstall \"\"\" + $_.PSChildName + \"\"\"\"}}}" 2>nul
)
powershell -Command "Get-ItemProperty -Path HKCU:Software\Microsoft\Windows\CurrentVersion\Uninstall\* -Exclude \"{*}.KB*\" | Sort-Object DisplayName | Select-Object DisplayName, Publisher, DisplayVersion, PSChildName, PSPath, UninstallString | Where-Object {$_.PSChildName -NotMatch \"^WIC$\" -and $_.PSChildName -NotMatch \"^Connection Manager$\"} | Format-List @{Label = \"Name\" ; Expression = {$_.DisplayName}}, @{Label = \"Publisher\" ; Expression = {$_.Publisher}}, @{Label = \"Version\" ; Expression = {$_.DisplayVersion}}, @{Label = \"Product Code\" ; Expression = {$_.PSChildName}}, @{Label = \"Registry Path\" ; Expression = {$_.PSPath.Replace(\"Microsoft.PowerShell.Core\Registry::\", \"Computer\\\")}}, @{Label = \"Uninstall\" ; Expression = {if ($_.UninstallString) {\"winget uninstall \"\"\" + $_.PSChildName + \"\"\"\"}}}" 2>nul
goto :6

:6
git -C "%REPOSITORY_PATH%" fetch --no-write-fetch-head --force upstream master 1>nul 2>nul
git -C "%REPOSITORY_PATH%" reset --hard upstream/master 1>nul 2>nul
pause
cls
goto :2
