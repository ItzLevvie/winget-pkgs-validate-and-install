@echo off
cls

:1
path %SystemRoot%\System32;%SystemRoot%\System32\WindowsPowerShell\v1.0;%LOCALAPPDATA%\Microsoft\WindowsApps;%ProgramFiles%\Git\cmd
for /f "tokens=6 delims=[]. " %%a in ('ver') do (
    set OS_BUILD=%%a
)
if %OS_BUILD% LSS 19041 (
    echo This script requires an OS build of 19041 or above to run.
    echo:
    pause
    goto :EOF
)
reg query HKEY_USERS\S-1-5-19 1>nul 2>nul
if %ERRORLEVEL% EQU 1 (
    if not exist "%TEMP%\%COMPUTERNAME%.local" (
        echo This script requires administrator privileges to run.
        echo Note: You will only need to do this once.
        echo:
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
    echo Downloading WinGet ...
    mkdir "%TEMP%\WinGet" 1>nul 2>nul
    curl --location --url https://github.com/ItzLevvie/winget-pkgs-validate-and-install/releases/download/20211022.1/Microsoft.DesktopAppInstaller_neutral_8wekyb3d8bbwe.msixbundle --output "%TEMP%\WinGet\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle" 1>nul 2>nul
    if %PROCESSOR_ARCHITECTURE% EQU AMD64 (
        curl --location --url https://github.com/ItzLevvie/winget-pkgs-validate-and-install/releases/download/20211022.1/Microsoft.VCLibs.140.00.UWPDesktop_x64_8wekyb3d8bbwe.appx --output "%TEMP%\WinGet\Microsoft.VCLibs.140.00.UWPDesktop_8wekyb3d8bbwe.appx" 1>nul 2>nul
    ) else if %PROCESSOR_ARCHITECTURE% EQU x86 (
        curl --location --url https://github.com/ItzLevvie/winget-pkgs-validate-and-install/releases/download/20211022.1/Microsoft.VCLibs.140.00.UWPDesktop_x86_8wekyb3d8bbwe.appx --output "%TEMP%\WinGet\Microsoft.VCLibs.140.00.UWPDesktop_8wekyb3d8bbwe.appx" 1>nul 2>nul
    ) else (
        curl --location --url https://github.com/ItzLevvie/winget-pkgs-validate-and-install/releases/download/20211022.1/Microsoft.VCLibs.140.00.UWPDesktop_arm64_8wekyb3d8bbwe.appx --output "%TEMP%\WinGet\Microsoft.VCLibs.140.00.UWPDesktop_8wekyb3d8bbwe.appx" 1>nul 2>nul
    )
    echo Installing WinGet ...
    powershell -Command "$ProgressPreference = \"SilentlyContinue\" ; Add-AppxPackage -Path \"%TEMP%\WinGet\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle\" -DependencyPath \"%TEMP%\WinGet\Microsoft.VCLibs.140.00.UWPDesktop_8wekyb3d8bbwe.appx\" -ForceUpdateFromAnyVersion" 1>nul 2>nul
    rmdir /s /q "%TEMP%\WinGet" 1>nul 2>nul
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
    echo Downloading Git ...
    mkdir "%TEMP%\WinGet" 1>nul 2>nul
    if %PROCESSOR_ARCHITECTURE% EQU AMD64 (
        curl --location --url https://github.com/ItzLevvie/winget-pkgs-validate-and-install/releases/download/20211110.1/Git-prerelease-x64.exe --output "%TEMP%\WinGet\Git-prerelease.exe" 1>nul 2>nul
    ) else (
        curl --location --url https://github.com/ItzLevvie/winget-pkgs-validate-and-install/releases/download/20211110.1/Git-prerelease-x86.exe --output "%TEMP%\WinGet\Git-prerelease.exe" 1>nul 2>nul
    )
    echo Installing Git ...
    "%TEMP%\WinGet\Git-prerelease.exe" /VERYSILENT /SUPPRESSMSGBOXES
    rmdir /s /q "%TEMP%\WinGet" 1>nul 2>nul
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
chcp 65001 1>nul 2>nul
for /f "usebackq tokens=1,2,3,4,5,6,7,8 delims=/" %%a in (`git -C "%REPOSITORY_PATH%" diff --name-only --diff-filter=d upstream/master...FETCH_HEAD ^| findstr /n "^" ^| findstr /r /c:"^1:manifests/"`) do (
    set "RELATIVE_PATH_4=manifests\%%b\%%c\%%d"
    set "RELATIVE_PATH_5=manifests\%%b\%%c\%%d\%%e"
    set "RELATIVE_PATH_6=manifests\%%b\%%c\%%d\%%e\%%f"
    set "RELATIVE_PATH_7=manifests\%%b\%%c\%%d\%%e\%%f\%%g"
    set "RELATIVE_PATH_8=manifests\%%b\%%c\%%d\%%e\%%f\%%g\%%h"
)
chcp 437 1>nul 2>nul
set "RELATIVE_PATH=%RELATIVE_PATH_4%"
winget validate --manifest "%REPOSITORY_PATH%\%RELATIVE_PATH_4%" 1>nul 2>nul
if %ERRORLEVEL% EQU -1978335191 (
    set "RELATIVE_PATH=%RELATIVE_PATH_5%"
    winget validate --manifest "%REPOSITORY_PATH%\%RELATIVE_PATH_5%" 1>nul 2>nul
)
if %ERRORLEVEL% EQU -1978335191 (
    set "RELATIVE_PATH=%RELATIVE_PATH_6%"
    winget validate --manifest "%REPOSITORY_PATH%\%RELATIVE_PATH_6%" 1>nul 2>nul
)
if %ERRORLEVEL% EQU -1978335191 (
    set "RELATIVE_PATH=%RELATIVE_PATH_7%"
    winget validate --manifest "%REPOSITORY_PATH%\%RELATIVE_PATH_7%" 1>nul 2>nul
)
if %ERRORLEVEL% EQU -1978335191 (
    set "RELATIVE_PATH=%RELATIVE_PATH_8%"
    winget validate --manifest "%REPOSITORY_PATH%\%RELATIVE_PATH_8%" 1>nul 2>nul
)
goto :5

:5
reg delete HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall /f 1>nul 2>nul && reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall /f 1>nul 2>nul
if %PROCESSOR_ARCHITECTURE% NEQ x86 (
    reg delete HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall /f 1>nul 2>nul && reg add HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall /f 1>nul 2>nul
)
reg delete HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall /f 1>nul 2>nul && reg add HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall /f 1>nul 2>nul
winget validate --manifest "%REPOSITORY_PATH%\%RELATIVE_PATH%"
winget install --manifest "%REPOSITORY_PATH%\%RELATIVE_PATH%"
if %ERRORLEVEL% NEQ 0 (
    echo:
    goto :6
)
winget show --manifest "%REPOSITORY_PATH%\%RELATIVE_PATH%" | findstr /r /c:"^  Type: Msix$" 1>nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo:
    goto :6
)
echo:
echo Looking for the application in the following registry paths below ...
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
