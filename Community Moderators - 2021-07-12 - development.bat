@echo off
cls

:1
winget --version > nul 2>&1
if %ERRORLEVEL% == 9009 (
    choice /n /m "Windows Package Manager is not installed. Would you like to install it (Y/N)?"
)
if %ERRORLEVEL% == 1 (
    echo:
    curl --location --url https://github.com/ItzLevvie/winget-pkgs-validate-and-install/releases/download/latest/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle --output "C:/Users/%USERNAME%/Downloads/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle" > nul 2>&1
    curl --location --url https://github.com/ItzLevvie/winget-pkgs-validate-and-install/releases/download/latest/Microsoft.VCLibs.140.00.UWPDesktop_8wekyb3d8bbwe.appx --output "C:/Users/%USERNAME%/Downloads/Microsoft.VCLibs.140.00.UWPDesktop_8wekyb3d8bbwe.appx" > nul 2>&1
    powershell Add-AppxPackage -Path "C:/Users/%USERNAME%/Downloads/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle" -DependencyPath "C:/Users/%USERNAME%/Downloads/Microsoft.VCLibs.140.00.UWPDesktop_8wekyb3d8bbwe.appx" > nul 2>&1
    del "C:\Users\%USERNAME%\Downloads\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle" > nul 2>&1
    del "C:\Users\%USERNAME%\Downloads\Microsoft.VCLibs.140.00.UWPDesktop_8wekyb3d8bbwe.appx" > nul 2>&1
)
if %ERRORLEVEL% == 2 goto :EOF
(
    echo {
    echo     "network": {"downloader": "wininet"},
    echo     "visual": {"progressBar": "rainbow"}
    echo }
) > "C:/Users/%USERNAME%/AppData/Local/Packages/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe/LocalState/settings.json"
git --version > nul 2>&1
if %ERRORLEVEL% == 9009 (
    choice /n /m "Git is not installed. Would you like to install it (Y/N)?"
)
if %ERRORLEVEL% == 1 (
    echo:
    curl --location --url https://github.com/git-for-windows/git/releases/download/v2.32.0.windows.2/Git-2.32.0.2-64-bit.exe --output "C:/Users/%USERNAME%/Downloads/Git-2.32.0.2-64-bit.exe" > nul 2>&1
    "C:/Users/%USERNAME%/Downloads/Git-2.32.0.2-64-bit.exe" /VERYSILENT /CURRENTUSER
    del "C:\Users\%USERNAME%\Downloads\Git-2.32.0.2-64-bit.exe" > nul 2>&1
    set PATH=%PATH%;"C:/Program Files/Git/cmd"
)
if %ERRORLEVEL% == 2 goto :EOF
set REPOSITORY_PATH="C:/Users/%USERNAME%/Desktop/winget-pkgs"
if not exist %REPOSITORY_PATH% (
    choice /n /m "winget-pkgs repository does not exist. Would you like to clone it (Y/N)?"
)
if %ERRORLEVEL% == 1 (
    echo:
    git clone https://github.com/ItzLevvie2/winget-pkgs %REPOSITORY_PATH% > nul 2>&1
    git -C %REPOSITORY_PATH% remote add upstream https://github.com/microsoft/winget-pkgs > nul 2>&1
)
if %ERRORLEVEL% == 2 goto :EOF
goto :2

:2
cls
set PR_NUMBER=
set /p PR_NUMBER="Please enter the pull request number: "
if "%PR_NUMBER%" == "" goto :2
git -C %REPOSITORY_PATH% fetch upstream master > nul 2>&1
git -C %REPOSITORY_PATH% fetch upstream refs/pull/%PR_NUMBER%/head:pull/%PR_NUMBER% > nul 2>&1
git -C %REPOSITORY_PATH% checkout pull/%PR_NUMBER% > nul 2>&1
goto :3

:3
for /f "tokens=1,2,3,4,5,6,7 delims=/" %%a in ('git -C %REPOSITORY_PATH% diff --name-only --diff-filter=d upstream/master...pull/%PR_NUMBER%') do (
    set DIRECTORY_PATH_5="%%a/%%b/%%c/%%d/%%e"
    set DIRECTORY_PATH_6="%%a/%%b/%%c/%%d/%%e/%%f"
    set DIRECTORY_PATH_7="%%a/%%b/%%c/%%d/%%e/%%f/%%g"
)
set DIRECTORY_PATH=%DIRECTORY_PATH_5%
winget validate --manifest %REPOSITORY_PATH%/%DIRECTORY_PATH_5% > nul 2>&1
if %ERRORLEVEL% == -1978335191 (
    set DIRECTORY_PATH=%DIRECTORY_PATH_6%
    winget validate --manifest %REPOSITORY_PATH%/%DIRECTORY_PATH_6% > nul 2>&1
)
if %ERRORLEVEL% == -1978335191 (
    set DIRECTORY_PATH=%DIRECTORY_PATH_7%
    winget validate --manifest %REPOSITORY_PATH%/%DIRECTORY_PATH_7% > nul 2>&1
)
goto :4

:4
winget validate --manifest %REPOSITORY_PATH%/%DIRECTORY_PATH%
winget install --manifest %REPOSITORY_PATH%/%DIRECTORY_PATH%
goto :5

:5
git -C %REPOSITORY_PATH% checkout --detach upstream/master > nul 2>&1
git -C %REPOSITORY_PATH% branch --delete --force pull/%PR_NUMBER% > nul 2>&1
pause
goto :2
