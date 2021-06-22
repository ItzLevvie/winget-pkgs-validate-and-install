@echo off

:1
cls
set NUMBER=
set /p NUMBER="Please enter the pull request number: "
if "%NUMBER%" == "" goto :1
cd "C:/Users/%USERNAME%/Documents/GitHub/winget-pkgs"
git fetch --force upstream master
git fetch --force upstream refs/pull/%NUMBER%/head pull/%NUMBER%
git checkout --force pull/%NUMBER%
git diff --name-only upstream/master...pull/%NUMBER%
goto :2

:2
set PATH=
set /p PATH="Please enter the path to the folder where the manifest file(s) is (are) located: "
if "%PATH%" == "" goto :2
winget validate --manifest "C:/Users/%USERNAME%/Documents/GitHub/winget-pkgs/%PATH%"
winget install --manifest "C:/Users/%USERNAME%/Documents/GitHub/winget-pkgs/%PATH%"
git checkout --detach --force upstream/master
git branch --delete --force pull/%NUMBER%
pause
goto :1
