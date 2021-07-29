@echo off
cls

:1
for /f "tokens=6 delims=[]. " %%a in ('ver') do set OPERATING_SYSTEM_BUILD=%%a
if %OPERATING_SYSTEM_BUILD% LSS 19041 goto :EOF
if not exist "C:\Users\%USERNAME%\AppData\Local\Microsoft\WindowsApps\winget.exe" (
    echo Please wait while we download Windows Package Manager.
    md "C:\Users\%USERNAME%\AppData\Local\Temp\WinGet"
    curl --location --url "https://github.com/ItzLevvie/winget-pkgs-validate-and-install/releases/download/latest/Microsoft.DesktopAppInstaller_neutral_8wekyb3d8bbwe.msixbundle" --output "C:\Users\%USERNAME%\AppData\Local\Temp\WinGet\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle" > nul 2>&1
    if %PROCESSOR_ARCHITECTURE% EQU AMD64 (
        curl --location --url "https://github.com/ItzLevvie/winget-pkgs-validate-and-install/releases/download/latest/Microsoft.VCLibs.140.00.UWPDesktop_x64_8wekyb3d8bbwe.appx" --output "C:\Users\%USERNAME%\AppData\Local\Temp\WinGet\Microsoft.VCLibs.140.00.UWPDesktop_8wekyb3d8bbwe.appx" > nul 2>&1
    ) else (
        curl --location --url "https://github.com/ItzLevvie/winget-pkgs-validate-and-install/releases/download/latest/Microsoft.VCLibs.140.00.UWPDesktop_x86_8wekyb3d8bbwe.appx" --output "C:\Users\%USERNAME%\AppData\Local\Temp\WinGet\Microsoft.VCLibs.140.00.UWPDesktop_8wekyb3d8bbwe.appx" > nul 2>&1
    )
    echo Successfully downloaded.
    echo:
    echo Please wait while we install Windows Package Manager.
    powershell -Command "$ProgressPreference = \"SilentlyContinue\" ; Add-AppxPackage -Path \"C:\Users\%USERNAME%\AppData\Local\Temp\WinGet\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle\" -DependencyPath \"C:\Users\%USERNAME%\AppData\Local\Temp\WinGet\Microsoft.VCLibs.140.00.UWPDesktop_8wekyb3d8bbwe.appx\"" > nul 2>&1
    rd /s /q "C:\Users\%USERNAME%\AppData\Local\Temp\WinGet" > nul 2>&1
    path %PATH%;C:\Users\%USERNAME%\AppData\Local\Microsoft\WindowsApps
    echo Successfully installed.
    echo:
)
(
    echo {
    echo     "network": {"downloader": "wininet"},
    echo     "visual": {"progressBar": "rainbow"}
    echo }
) > "C:\Users\%USERNAME%\AppData\Local\Packages\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\LocalState\settings.json"
if not exist "C:\Program Files\Git\cmd\git.exe" (
    echo Please wait while we download Git.
    md "C:\Users\%USERNAME%\AppData\Local\Temp\WinGet"
    if %PROCESSOR_ARCHITECTURE% EQU AMD64 (
        curl --location --url "https://github.com/ItzLevvie/winget-pkgs-validate-and-install/releases/download/latest/Git-prerelease-x64.exe" --output "C:\Users\%USERNAME%\AppData\Local\Temp\WinGet\Git-prerelease.exe" > nul 2>&1
    ) else (
        curl --location --url "https://github.com/ItzLevvie/winget-pkgs-validate-and-install/releases/download/latest/Git-prerelease-x86.exe" --output "C:\Users\%USERNAME%\AppData\Local\Temp\WinGet\Git-prerelease.exe" > nul 2>&1
    )
    echo Successfully downloaded.
    echo:
    echo Please wait while we install Git.
    "C:\Users\%USERNAME%\AppData\Local\Temp\WinGet\Git-prerelease.exe" /verysilent
    rd /s /q "C:\Users\%USERNAME%\AppData\Local\Temp\WinGet" > nul 2>&1
    path %PATH%;C:\Program Files\Git\cmd
    echo Successfully installed.
    echo:
)
set REPOSITORY_PATH="C:\Users\%USERNAME%\Documents\GitHub\winget-pkgs"
if not exist %REPOSITORY_PATH%\.git (
    echo Please wait while we clone the manifest repository.
    git clone --branch master --single-branch https://github.com/microsoft/winget-pkgs %REPOSITORY_PATH% > nul 2>&1
    git -C %REPOSITORY_PATH% remote add upstream https://github.com/microsoft/winget-pkgs > nul 2>&1
    echo Successfully cloned.
    echo:
)
goto :2

:2
cls
set PULL_REQUEST_NUMBER=
set /p PULL_REQUEST_NUMBER="Please enter the pull request number: "
if "%PULL_REQUEST_NUMBER%" EQU "" goto :2
git -C %REPOSITORY_PATH% fetch --no-write-fetch-head --force upstream master > nul 2>&1
git -C %REPOSITORY_PATH% fetch --force upstream refs/pull/%PULL_REQUEST_NUMBER%/head > nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :2
git -C %REPOSITORY_PATH% checkout --force --detach FETCH_HEAD > nul 2>&1
goto :3

:3
for /f "tokens=1,2,3,4,5,6,7,8 delims=/" %%a in ('git -C %REPOSITORY_PATH% diff --name-only --diff-filter=d upstream/master...FETCH_HEAD') do (
    set RELATIVE_PATH_5="%%a\%%b\%%c\%%d\%%e"
    set RELATIVE_PATH_6="%%a\%%b\%%c\%%d\%%e\%%f"
    set RELATIVE_PATH_7="%%a\%%b\%%c\%%d\%%e\%%f\%%g"
    set RELATIVE_PATH_8="%%a\%%b\%%c\%%d\%%e\%%f\%%g\%%h"
)
set RELATIVE_PATH=%RELATIVE_PATH_5%
winget validate --manifest %REPOSITORY_PATH%\\%RELATIVE_PATH_5% > nul 2>&1
if %ERRORLEVEL% EQU -1978335191 (
    set RELATIVE_PATH=%RELATIVE_PATH_6%
    winget validate --manifest %REPOSITORY_PATH%\\%RELATIVE_PATH_6% > nul 2>&1
)
if %ERRORLEVEL% EQU -1978335191 (
    set RELATIVE_PATH=%RELATIVE_PATH_7%
    winget validate --manifest %REPOSITORY_PATH%\\%RELATIVE_PATH_7% > nul 2>&1
)
if %ERRORLEVEL% EQU -1978335191 (
    set RELATIVE_PATH=%RELATIVE_PATH_8%
    winget validate --manifest %REPOSITORY_PATH%\\%RELATIVE_PATH_8% > nul 2>&1
)
if %ERRORLEVEL% EQU -1978335191 (
    echo:
    goto :5
)
goto :4

:4
powershell -Command "Remove-Item -Path HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
if %PROCESSOR_ARCHITECTURE% EQU AMD64 (
        powershell -Command "Remove-Item -Path HKLM:SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)
powershell -Command "New-PSDrive -Name HKU -PSProvider Registry -Root HKEY_USERS | Out-Null ; Remove-Item -Path HKU:S-1-5-21*\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*
winget validate --manifest %REPOSITORY_PATH%\\%RELATIVE_PATH%
winget install --manifest %REPOSITORY_PATH%\\%RELATIVE_PATH%
echo:
echo Please wait while we search the registry for the installed application.
echo Note: Some installed applications will not be shown immediately so you will have to manually search the registry for it.
echo:
powershell -Command "Get-ItemProperty -Path HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\* | Sort-Object DisplayName | Select-Object DisplayName, Publisher, DisplayVersion, PSChildName"
if %PROCESSOR_ARCHITECTURE% EQU AMD64 (
    powershell -Command "Get-ItemProperty -Path HKLM:SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Sort-Object DisplayName | Select-Object DisplayName, Publisher, DisplayVersion, PSChildName"
)
powershell -Command "New-PSDrive -Name HKU -PSProvider Registry -Root HKEY_USERS | Out-Null ; Get-ItemProperty -Path HKU:S-1-5-21*\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\* | Sort-Object DisplayName | Select-Object DisplayName, Publisher, DisplayVersion, PSChildName"
powershell -Command "Remove-Item -Path HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
if %PROCESSOR_ARCHITECTURE% EQU AMD64 (
    powershell -Command "Remove-Item -Path HKLM:SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)
powershell -Command "New-PSDrive -Name HKU -PSProvider Registry -Root HKEY_USERS | Out-Null ; Remove-Item -Path HKU:S-1-5-21*\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*
echo Successfully searched.
echo:
goto :5

:5
git -C %REPOSITORY_PATH% fetch --no-write-fetch-head --force upstream master > nul 2>&1
git -C %REPOSITORY_PATH% checkout --force --detach upstream/master > nul 2>&1
pause
goto :2
