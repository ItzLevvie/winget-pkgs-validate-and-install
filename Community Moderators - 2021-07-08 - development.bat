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
set REPOSITORY_PATH=C:/Users/%USERNAME%/Documents/GitHub/winget-pkgs
if not exist "%REPOSITORY_PATH%" (
    echo "%REPOSITORY_PATH%" does not exist.
    goto :EOF
)
goto :2

:2
set PR_NUMBER=
set /p PR_NUMBER="Please enter the pull request number: "
if "%PR_NUMBER%" == "" goto :2
git -C "%REPOSITORY_PATH%" fetch upstream refs/pull/%PR_NUMBER%/head:pull/%PR_NUMBER% > nul 2>&1
if %ERRORLEVEL% == 128 (
    echo "%PR_NUMBER%" does not exist.
    goto :2
)
git -C "%REPOSITORY_PATH%" checkout pull/%PR_NUMBER% > nul 2>&1
for /f "tokens=1,2,3,4,5,6,7 delims=/" %%a in ('git -C "%REPOSITORY_PATH%" diff --name-only --diff-filter=d upstream/master...pull/%PR_NUMBER%') do (
    set DIRECTORY_PATH_5=%%a/%%b/%%c/%%d/%%e
    set DIRECTORY_PATH_6=%%a/%%b/%%c/%%d/%%e/%%f
    set DIRECTORY_PATH_7=%%a/%%b/%%c/%%d/%%e/%%f/%%g
)
goto :3

:3
set DIRECTORY_PATH=%DIRECTORY_PATH_5%
winget validate --manifest "%REPOSITORY_PATH%/%DIRECTORY_PATH%" > nul 2>&1
if %ERRORLEVEL% == -1978335191 (
     set DIRECTORY_PATH=%DIRECTORY_PATH_6%
)
winget validate --manifest "%REPOSITORY_PATH%/%DIRECTORY_PATH%" > nul 2>&1
if %ERRORLEVEL% == -1978335191 (
     set DIRECTORY_PATH=%DIRECTORY_PATH_7%
)
winget install --manifest "%REPOSITORY_PATH%/%DIRECTORY_PATH%"
git -C "%REPOSITORY_PATH%" fetch upstream master > nul 2>&1
git -C "%REPOSITORY_PATH%" checkout --detach upstream/master > nul 2>&1
git -C "%REPOSITORY_PATH%" branch --delete --force pull/%PR_NUMBER% > nul 2>&1
pause
cls
goto :1
