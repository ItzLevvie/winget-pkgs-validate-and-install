@echo off
cls

:1
cd "C:/Users/%USERNAME%/Documents/GitHub/winget-pkgs" > nul 2>&1
if %ERRORLEVEL% == 1 (
    echo "C:/Users/%USERNAME%/Documents/GitHub/winget-pkgs" does not exist.
    goto :EOF
)
git > nul 2>&1
if %ERRORLEVEL% == 9009 (
    echo Git is not installed.
    goto :EOF
)
set PR_NUMBER=
set /p PR_NUMBER="Please enter the pull request number: "
if "%PR_NUMBER%" == "" goto :1
git fetch --force upstream master > nul 2>&1
git fetch --force upstream refs/pull/%PR_NUMBER%/head:pull/%PR_NUMBER% > nul 2>&1
if %ERRORLEVEL% == 128 (
    echo "%PR_NUMBER%" does not exist.
    goto :1
)
git checkout --force pull/%PR_NUMBER% > nul 2>&1
git diff --raw --no-renames --diff-filter=AM upstream/master...pull/%PR_NUMBER%
goto :2

:2
cd "C:/Users/%USERNAME%/Desktop"
set FOLDER_PATH=
set /p FOLDER_PATH="Please enter the path to the folder where the manifest file(s) is (are) located: "
if "%FOLDER_PATH%" == "" goto :2
winget validate --manifest "C:/Users/%USERNAME%/Documents/GitHub/winget-pkgs/%FOLDER_PATH%"
if %ERRORLEVEL% == -2147024893 goto :2
winget install --manifest "C:/Users/%USERNAME%/Documents/GitHub/winget-pkgs/%FOLDER_PATH%"
cd "C:/Users/%USERNAME%/Documents/GitHub/winget-pkgs"
git checkout --detach --force upstream/master > nul 2>&1
git branch --delete --force pull/%PR_NUMBER% > nul 2>&1
pause
cls
goto :1
