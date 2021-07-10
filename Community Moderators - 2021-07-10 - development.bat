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
    echo     "network": {"downloader": "wininet"},
    echo     "visual": {"progressBar": "rainbow"}
    echo }
) > "C:/Users/%USERNAME%/AppData/Local/Packages/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe/LocalState/settings.json"
git --version > nul 2>&1
if %ERRORLEVEL% == 9009 (
    echo Git is not installed.
    goto :EOF
)
set REPOSITORY_PATH="C:/Users/%USERNAME%/Desktop/winget-pkgs"
if not exist %REPOSITORY_PATH% (
    git clone https://github.com/ItzLevvie2/winget-pkgs %REPOSITORY_PATH% > nul 2>&1
    git -C %REPOSITORY_PATH% remote add upstream https://github.com/microsoft/winget-pkgs > nul 2>&1
)
goto :2

:2
set PR_NUMBER=
set /p PR_NUMBER="Please enter the pull request number: "
if "%PR_NUMBER%" == "" (
    cls
    goto :2
)
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
echo Checking if the directory path to the manifest has 5 folders.
set DIRECTORY_PATH=%DIRECTORY_PATH_5%
winget validate --manifest %REPOSITORY_PATH%/%DIRECTORY_PATH_5% > nul 2>&1
if %ERRORLEVEL% == -1978335191 (
    echo Checking if the directory path to the manifest has 6 folders.
    set DIRECTORY_PATH=%DIRECTORY_PATH_6%
    winget validate --manifest %REPOSITORY_PATH%/%DIRECTORY_PATH_6% > nul 2>&1
)
if %ERRORLEVEL% == -1978335191 (
    echo Checking if the directory path to the manifest has 7 folders.
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
cls
goto :2