@echo off

:1
cls
set PR_NUMBER=
set /p PR_NUMBER="Please enter the pull request number: "
if "%PR_NUMBER%" == "" goto :1
cd "C:/Users/%USERNAME%/Documents/GitHub/winget-pkgs"
git fetch --force upstream master > nul 2>&1
git fetch --force upstream refs/pull/%PR_NUMBER%/head:pull/%PR_NUMBER%
git checkout --force pull/%PR_NUMBER%
git diff --numstat --no-renames --diff-filter=AM upstream/master...pull/%PR_NUMBER%
cd "C:/Users/%USERNAME%/Desktop"
goto :2

:2
set FOLDER_PATH=
set /p FOLDER_PATH="Please enter the path to the folder where the manifest file(s) is (are) located: "
if "%FOLDER_PATH%" == "" goto :2
winget validate --manifest "C:/Users/%USERNAME%/Documents/GitHub/winget-pkgs/%FOLDER_PATH%"
winget install --manifest "C:/Users/%USERNAME%/Documents/GitHub/winget-pkgs/%FOLDER_PATH%"
cd "C:/Users/%USERNAME%/Documents/GitHub/winget-pkgs"
git checkout --detach --force upstream/master
git branch --delete --force pull/%PR_NUMBER%
pause
goto :1
