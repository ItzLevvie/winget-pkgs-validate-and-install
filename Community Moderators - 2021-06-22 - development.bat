@echo off

:1
cls
set PULL_REQUEST_NUMBER=
set /p PULL_REQUEST_NUMBER="Please enter the pull request number: "
if "%PULL_REQUEST_NUMBER%" == "" goto :1
cd "C:/Users/%USERNAME%/Documents/GitHub/winget-pkgs"
git fetch --force upstream refs/pull/%NUMBER%/head:pull/%PULL_REQUEST_NUMBER%
git checkout --force pull/%PULL_REQUEST_NUMBER%
git diff --name-only upstream/master...pull/%PULL_REQUEST_NUMBER%
goto :2

:2
set FOLDER_PATH=
set /p FOLDER_PATH="Please enter the path to the folder where the manifest file(s) is (are) located: "
if "%FOLDER_PATH%" == "" goto :2
winget validate --manifest "C:/Users/%USERNAME%/Documents/GitHub/winget-pkgs/%FOLDER_PATH%"
winget install --manifest "C:/Users/%USERNAME%/Documents/GitHub/winget-pkgs/%FOLDER_PATH%"
git checkout --detach --force upstream/master
git branch --delete --force pull/%PULL_REQUEST_NUMBER%
pause
goto :1
