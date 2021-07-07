@echo off
cls

:1
cd "C:/Users/%USERNAME%/Documents/GitHub/winget-pkgs" > nul 2>&1
if %ERRORLEVEL% == 1 (
    echo "C:/Users/%USERNAME%/Documents/GitHub/winget-pkgs" does not exist.
    goto :EOF
)
git --version > nul 2>&1
if %ERRORLEVEL% == 9009 (
    echo Git is not installed.
    goto :EOF
)
set PR_NUMBER=
set /p PR_NUMBER="Please enter the pull request number: "
if "%PR_NUMBER%" == "" goto :1
git fetch upstream master > nul 2>&1
git fetch upstream refs/pull/%PR_NUMBER%/head:pull/%PR_NUMBER% > nul 2>&1
if %ERRORLEVEL% == 128 (
    echo "%PR_NUMBER%" does not exist.
    goto :1
)
git checkout pull/%PR_NUMBER% > nul 2>&1
goto :2

:2
cd "C:/Users/%USERNAME%/Desktop"
set DIRECTORY_PATH=
set /p DIRECTORY_PATH="Please enter the directory path to the manifest: "
if "%DIRECTORY_PATH%" == "" goto :2
winget validate --manifest "C:/Users/%USERNAME%/Documents/GitHub/winget-pkgs/%DIRECTORY_PATH%"
if %ERRORLEVEL% == -2147024893 goto :2
winget install --manifest "C:/Users/%USERNAME%/Documents/GitHub/winget-pkgs/%DIRECTORY_PATH%"
cd "C:/Users/%USERNAME%/Documents/GitHub/winget-pkgs"
git checkout --detach upstream/master > nul 2>&1
git branch --delete --force pull/%PR_NUMBER% > nul 2>&1
pause
cls
goto :1
