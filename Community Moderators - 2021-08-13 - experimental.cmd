@echo off
cls

:1
path %SystemRoot%\System32;%SystemRoot%\System32\WindowsPowerShell\v1.0
for /f "tokens=6 delims=[]. " %%a in ('ver') do (
    set OS_BUILD=%%a
)
if %OS_BUILD% LSS 19041 (
    goto :EOF
)
if not exist "%LOCALAPPDATA%\Microsoft\WindowsApps\winget.exe" (
    echo Please wait while we download WinGet.
    mkdir "%TEMP%\20210813.1" 1>nul 2>nul
    curl --location --url "https://github.com/ItzLevvie/winget-pkgs-validate-and-install/releases/download/latest/Microsoft.DesktopAppInstaller_neutral_8wekyb3d8bbwe.msixbundle" --output "%TEMP%\20210813.1\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle" 1>nul 2>nul
    if "%PROCESSOR_ARCHITECTURE%" EQU "AMD64" (
        curl --location --url "https://github.com/ItzLevvie/winget-pkgs-validate-and-install/releases/download/latest/Microsoft.VCLibs.140.00.UWPDesktop_x64_8wekyb3d8bbwe.appx" --output "%TEMP%\20210813.1\Microsoft.VCLibs.140.00.UWPDesktop_8wekyb3d8bbwe.appx" 1>nul 2>nul
    ) else (
        curl --location --url "https://github.com/ItzLevvie/winget-pkgs-validate-and-install/releases/download/latest/Microsoft.VCLibs.140.00.UWPDesktop_x86_8wekyb3d8bbwe.appx" --output "%TEMP%\20210813.1\Microsoft.VCLibs.140.00.UWPDesktop_8wekyb3d8bbwe.appx" 1>nul 2>nul
    )
    echo Successfully downloaded.
    echo:
    echo Please wait while we install WinGet.
    powershell -NoProfile -Command "$ProgressPreference = \"SilentlyContinue\" ; Add-AppxPackage -Path \"%TEMP%\20210813.1\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle\" -DependencyPath \"%TEMP%\20210813.1\Microsoft.VCLibs.140.00.UWPDesktop_8wekyb3d8bbwe.appx\" -ForceUpdateFromAnyVersion -ErrorAction SilentlyContinue" 1>nul 2>nul
    rmdir /s /q "%TEMP%\20210813.1" 1>nul 2>nul
    echo Successfully installed.
    echo:
)
if not exist "%LOCALAPPDATA%\Packages\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\LocalState\settings.json" (
    (
        echo {
        echo     "network": {"downloader": "wininet"},
        echo     "visual": {"progressBar": "rainbow"},
        echo }
    ) > "%LOCALAPPDATA%\Packages\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\LocalState\settings.json"
)
if not exist "%ProgramFiles%\Git\cmd\git.exe" (
    echo Please wait while we download Git.
    mkdir "%TEMP%\20210813.1" 1>nul 2>nul
    if "%PROCESSOR_ARCHITECTURE%" EQU "AMD64" (
        curl --location --url "https://github.com/ItzLevvie/winget-pkgs-validate-and-install/releases/download/latest/Git-prerelease-x64.exe" --output "%TEMP%\20210813.1\Git-prerelease.exe" 1>nul 2>nul
    ) else (
        curl --location --url "https://github.com/ItzLevvie/winget-pkgs-validate-and-install/releases/download/latest/Git-prerelease-x86.exe" --output "%TEMP%\20210813.1\Git-prerelease.exe" 1>nul 2>nul
    )
    echo Successfully downloaded.
    echo:
    echo Please wait while we install Git.
    "%TEMP%\20210813.1\Git-prerelease.exe" /VERYSILENT /SUPPRESSMSGBOXES
    rmdir /s /q "%TEMP%\20210813.1" 1>nul 2>nul
    echo Successfully installed.
    echo:
)
path %SystemRoot%\System32;%SystemRoot%\System32\WindowsPowerShell\v1.0;%LOCALAPPDATA%\Microsoft\WindowsApps;%ProgramFiles%\Git\cmd
set REPOSITORY_PATH="%USERPROFILE%\Documents\GitHub\winget-pkgs"
if not exist %REPOSITORY_PATH%\.git (
    echo Please wait while we clone the WinGet package repository.
    git config --global core.quotePath false 1>nul 2>nul
    git clone --branch master --single-branch https://github.com/microsoft/winget-pkgs %REPOSITORY_PATH% 1>nul 2>nul
    git -C %REPOSITORY_PATH% remote add upstream https://github.com/microsoft/winget-pkgs 1>nul 2>nul
    echo Successfully cloned.
    echo:
)
cls
goto :2

:2
set PULL_REQUEST_NUMBER=
set /p PULL_REQUEST_NUMBER="Enter a pull request number: "
if "%PULL_REQUEST_NUMBER%" EQU "" (
    cls
    goto :2
)
git -C %REPOSITORY_PATH% fetch --no-write-fetch-head --force upstream master 1>nul 2>nul
git -C %REPOSITORY_PATH% fetch --force upstream refs/pull/%PULL_REQUEST_NUMBER%/head 1>nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    cls
    goto :2
)
git -C %REPOSITORY_PATH% checkout --force --detach FETCH_HEAD 1>nul 2>nul
goto :3

:3
chcp 65001 1>nul 2>nul
for /f "tokens=1,2,3,4,5,6,7,8 delims=/" %%a in ('git -C %REPOSITORY_PATH% diff --name-only --diff-filter=d upstream/master...FETCH_HEAD') do (
    set RELATIVE_PATH_4="%%a\%%b\%%c\%%d"
    set RELATIVE_PATH_5="%%a\%%b\%%c\%%d\%%e"
    set RELATIVE_PATH_6="%%a\%%b\%%c\%%d\%%e\%%f"
    set RELATIVE_PATH_7="%%a\%%b\%%c\%%d\%%e\%%f\%%g"
    set RELATIVE_PATH_8="%%a\%%b\%%c\%%d\%%e\%%f\%%g\%%h"
)
chcp 437 1>nul 2>nul
set RELATIVE_PATH=%RELATIVE_PATH_4%
winget validate --manifest %REPOSITORY_PATH%\\%RELATIVE_PATH_4% 1>nul 2>nul
if %ERRORLEVEL% EQU -1978335191 (
    set RELATIVE_PATH=%RELATIVE_PATH_5%
    winget validate --manifest %REPOSITORY_PATH%\\%RELATIVE_PATH_5% 1>nul 2>nul
)
if %ERRORLEVEL% EQU -1978335191 (
    set RELATIVE_PATH=%RELATIVE_PATH_6%
    winget validate --manifest %REPOSITORY_PATH%\\%RELATIVE_PATH_6% 1>nul 2>nul
)
if %ERRORLEVEL% EQU -1978335191 (
    set RELATIVE_PATH=%RELATIVE_PATH_7%
    winget validate --manifest %REPOSITORY_PATH%\\%RELATIVE_PATH_7% 1>nul 2>nul
)
if %ERRORLEVEL% EQU -1978335191 (
    set RELATIVE_PATH=%RELATIVE_PATH_8%
    winget validate --manifest %REPOSITORY_PATH%\\%RELATIVE_PATH_8% 1>nul 2>nul
)
goto :4

:4
winget validate --manifest %REPOSITORY_PATH%\\%RELATIVE_PATH%
powershell -NoProfile -Command "Remove-Item -Path \"HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*\" -Recurse -Force -ErrorAction SilentlyContinue" 1>nul 2>nul
if "%PROCESSOR_ARCHITECTURE%" NEQ "x86" (
    powershell -NoProfile -Command "Remove-Item -Path \"HKLM:SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*\" -Recurse -Force -ErrorAction SilentlyContinue" 1>nul 2>nul
)
powershell -NoProfile -Command "Remove-Item -Path \"HKCU:Software\Microsoft\Windows\CurrentVersion\Uninstall\*\" -Recurse -Force -ErrorAction SilentlyContinue" 1>nul 2>nul
winget install --manifest %REPOSITORY_PATH%\\%RELATIVE_PATH%
if %ERRORLEVEL% EQU -1978335215 (
    echo:
    goto :5
) else if %ERRORLEVEL% EQU -1978335216 (
    echo:
    goto :5
) else if %ERRORLEVEL% EQU -2145844844 (
    echo:
    goto :5
) else if %ERRORLEVEL% EQU -2147009293 (
    echo:
    goto :5
) else if %ERRORLEVEL% EQU -2147467260 (
    echo:
    goto :5
)
winget show --manifest %REPOSITORY_PATH%\\%RELATIVE_PATH% | find "  Type: Msix" 1>nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo:
    goto :5
)
echo:
echo Please wait while we look for the application in the registry.
echo Note: If the application is not listed below, you will need to wait for a few minutes to make sure the application has enough time to create the required registry keys for the application to be listed in Control Panel.
echo:
echo Once you have waited for a few minutes, you will need to look for the application in the following registry paths below:
echo 1^) Computer\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall
if "%PROCESSOR_ARCHITECTURE%" NEQ "x86" (
    echo 2^) Computer\HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall
    echo 3^) Computer\HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Uninstall
) else (
    echo 2^) Computer\HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Uninstall
)
echo:
echo This will take 30 seconds to complete.
echo Note: If you would like to skip this, press Ctrl + C and then press N + Enter, and use one of the following to look for the application: Control Panel, CCleaner, or Revo Uninstaller.
echo:
timeout /t 30 /nobreak 1>nul 2>nul
if %ERRORLEVEL% EQU 1 (
    echo:
    goto :5
)
powershell -NoProfile -Command "Get-ItemProperty -Path \"HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*\" -Exclude \"{*}.KB*\" -ErrorAction SilentlyContinue | Sort-Object DisplayName -ErrorAction SilentlyContinue | Select-Object DisplayName, Publisher, DisplayVersion, PSChildName, PSPath -ErrorAction SilentlyContinue | Format-List @{Label=\"Name\" ; Expression={$_.DisplayName}}, @{Label=\"Publisher\" ; Expression={$_.Publisher}}, @{Label=\"Version\" ; Expression={$_.DisplayVersion}}, @{Label=\"Product Code\" ; Expression={$_.PSChildName}}, @{Label=\"Registry Path\" ; Expression={$_.PSPath.Replace(\"Microsoft.PowerShell.Core\Registry::\", \"Computer\\\")}} -ErrorAction SilentlyContinue" 2>nul
if "%PROCESSOR_ARCHITECTURE%" NEQ "x86" (
    powershell -NoProfile -Command "Get-ItemProperty -Path \"HKLM:SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*\" -Exclude \"{*}.KB*\" -ErrorAction SilentlyContinue | Sort-Object DisplayName -ErrorAction SilentlyContinue | Select-Object DisplayName, Publisher, DisplayVersion, PSChildName, PSPath -ErrorAction SilentlyContinue | Format-List @{Label=\"Name\" ; Expression={$_.DisplayName}}, @{Label=\"Publisher\" ; Expression={$_.Publisher}}, @{Label=\"Version\" ; Expression={$_.DisplayVersion}}, @{Label=\"Product Code\" ; Expression={$_.PSChildName}}, @{Label=\"Registry Path\" ; Expression={$_.PSPath.Replace(\"Microsoft.PowerShell.Core\Registry::\", \"Computer\\\")}} -ErrorAction SilentlyContinue" 2>nul
)
powershell -NoProfile -Command "Get-ItemProperty -Path \"HKCU:Software\Microsoft\Windows\CurrentVersion\Uninstall\*\" -Exclude \"{*}.KB*\" -ErrorAction SilentlyContinue | Sort-Object DisplayName -ErrorAction SilentlyContinue | Select-Object DisplayName, Publisher, DisplayVersion, PSChildName, PSPath -ErrorAction SilentlyContinue | Format-List @{Label=\"Name\" ; Expression={$_.DisplayName}}, @{Label=\"Publisher\" ; Expression={$_.Publisher}}, @{Label=\"Version\" ; Expression={$_.DisplayVersion}}, @{Label=\"Product Code\" ; Expression={$_.PSChildName}}, @{Label=\"Registry Path\" ; Expression={$_.PSPath.Replace(\"Microsoft.PowerShell.Core\Registry::\", \"Computer\\\")}} -ErrorAction SilentlyContinue" 2>nul
echo Successfully looked.
echo:
goto :5

:5
git -C %REPOSITORY_PATH% fetch --no-write-fetch-head --force upstream master 1>nul 2>nul
git -C %REPOSITORY_PATH% checkout --force --detach upstream/master 1>nul 2>nul
pause
cls
goto :2
