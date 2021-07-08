@echo off
cls

:1
winget --version > nul 2>&1
if %ERRORLEVEL% == 9009 (
    echo Windows Package Manager is not installed.
    goto :EOF
)
(
    echo {
    echo     "network": { "downloader": "wininet" },
    echo     "visual": { "progressBar": "rainbow" }
    echo }
) > "C:/Users/%USERNAME%/AppData/Local/Packages/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe/LocalState/settings.json"
git --version > nul 2>&1
if %ERRORLEVEL% == 9009 (
    echo Git is not installed.
    goto :EOF
)
if not exist "C:/Users/%USERNAME%/Documents/GitHub/winget-pkgs" (
    echo "C:/Users/%USERNAME%/Documents/GitHub/winget-pkgs" does not exist.
    goto :EOF
)
goto :2

:2
set PR_NUMBER=
set /p PR_NUMBER="Please enter the pull request number: "
if "%PR_NUMBER%" == "" goto :2
::git fetch upstream master > nul 2>&1
git -C "C:/Users/%USERNAME%/Documents/GitHub/winget-pkgs" fetch upstream refs/pull/%PR_NUMBER%/head:pull/%PR_NUMBER% > nul 2>&1
if %ERRORLEVEL% == 128 (
    echo "%PR_NUMBER%" does not exist.
    goto :2
)
git -C "C:/Users/%USERNAME%/Documents/GitHub/winget-pkgs" checkout pull/%PR_NUMBER% > nul 2>&1
git -C "C:/Users/%USERNAME%/Documents/GitHub/winget-pkgs" diff --name-only --diff-filter=d upstream/master...pull/%PR_NUMBER%
::cd "C:/Users/%USERNAME%/Desktop"
goto :3

:3
set DIRECTORY_PATH=
set /p DIRECTORY_PATH="Please enter the directory path to the manifest: "
if "%DIRECTORY_PATH%" == "" goto :3
winget validate --manifest "C:/Users/%USERNAME%/Documents/GitHub/winget-pkgs/%DIRECTORY_PATH%"
if %ERRORLEVEL% == -2147024893 goto :3
winget install --manifest "C:/Users/%USERNAME%/Documents/GitHub/winget-pkgs/%DIRECTORY_PATH%"
::cd "C:/Users/%USERNAME%/Documents/GitHub/winget-pkgs"
git -C "C:/Users/%USERNAME%/Documents/GitHub/winget-pkgs" checkout --detach upstream/master > nul 2>&1
git -C "C:/Users/%USERNAME%/Documents/GitHub/winget-pkgs" branch --delete --force pull/%PR_NUMBER% > nul 2>&1
cd "C:/Users/%USERNAME%/Desktop"
pause
cls
goto :1
