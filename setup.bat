@echo off
:: Simplified script to check for and install winget and Git if not present
setlocal enabledelayedexpansion

echo === Checking for required software ===

:: --- WINGET INSTALLATION ---
echo Checking if winget is already installed...

:: Check if winget exists by trying to run it
Get-Command winget >nul 2>&1
if %errorlevel% equ 0 (
    echo Winget is already installed.
    winget --version
) else (
    echo Winget is not installed. Starting installation...


:: Check for admin privileges
net session >nul 2>&1
if !errorlevel! neq 0 (
    echo ERROR: Administrator privileges required. Please run as administrator.
    pause
    exit /b 1
)

    :: Quick Windows version check (must be Windows 10 1809+ or Windows 11)
    REM Extract version
for /f "tokens=4-6 delims=. " %%i in ('ver') do (
    set VERSION=%%i.%%j
    set BUILD=%%k
)

REM Check major version
if not "!VERSION:~0,4!"=="10.0" (
    echo ERROR: Winget requires Windows 10 or Windows 11.
    pause
    exit /b 1
)

REM Check minimum build number
if !BUILD! lss 18362 (
    echo ERROR: Winget requires Windows 10 version 1903 (build 18362) or later.
    pause
    exit /b 1
)

echo Windows version and build are OK.

    :: Create temp directory
    set "TEMP_DIR=%TEMP%\SoftwareInstall"
    if not exist "%TEMP_DIR%" mkdir "%TEMP_DIR%"

    :: Download and install winget
    echo Downloading and installing winget...
    powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle' -OutFile '%TEMP_DIR%\winget.msixbundle'; Add-AppxPackage -Path '%TEMP_DIR%\winget.msixbundle'}"

    :: Verify installation
    set "PATH=%PATH%;%LOCALAPPDATA%\Microsoft\WindowsApps"
    Get-Command winget >nul 2>&1
    if %errorlevel% equ 0 (
        echo Winget was successfully installed!
        winget --version
    ) else (
        echo Installation failed. Attempting to install dependencies...
        
        powershell -Command "& {Invoke-WebRequest -Uri 'https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx' -OutFile '%TEMP_DIR%\VCLibs.appx'; Add-AppxPackage -Path '%TEMP_DIR%\VCLibs.appx'}"
        powershell -Command "& {Invoke-WebRequest -Uri 'https://github.com/microsoft/microsoft-ui-xaml/releases/download/v2.7.3/Microsoft.UI.Xaml.2.7.x64.appx' -OutFile '%TEMP_DIR%\UI.Xaml.appx'; Add-AppxPackage -Path '%TEMP_DIR%\UI.Xaml.appx'}"
        
        echo Trying winget installation again...
        powershell -Command "& {Add-AppxPackage -Path '%TEMP_DIR%\winget.msixbundle'}"
        
        :: Update PATH again and check
        set "PATH=%PATH%;%LOCALAPPDATA%\Microsoft\WindowsApps"
        Get-Command winget >nul 2>&1
        if %errorlevel% equ 0 (
            echo Winget was successfully installed after adding dependencies!
            winget --version
        ) else (
            echo Winget installation still failed. Manual installation required.
            goto :CLEANUP
        )
    )
)

:: --- GIT INSTALLATION ---
echo.
echo Checking if Git is already installed...

:: Check if git exists by trying to run it
Get-Command git >nul 2>&1
if %errorlevel% equ 0 (
    echo Git is already installed.
    git --version
) else (
    echo Git is not installed. Starting installation...
    
    :: Use PowerShell to install Git with winget (more reliable)
    echo Installing Git using winget via PowerShell...
    powershell -Command "& {$process = Start-Process -FilePath 'winget' -ArgumentList 'install --id Git.Git -e --source winget --accept-source-agreements --accept-package-agreements' -Wait -PassThru -NoNewWindow; if ($process.ExitCode -ne 0) {Write-Output 'Winget Git installation failed with exit code: ' + $process.ExitCode; exit 1}}"
    
    if %errorlevel% neq 0 (
        echo Error during Git installation via winget. Trying direct download...
        goto :DIRECT_GIT
    )
    
    :: Refresh environment variables and check Git installation
    echo Refreshing environment variables...
    for /f "tokens=*" %%p in ('powershell -Command "[System.Environment]::GetEnvironmentVariable('PATH', 'Machine') + ';' + [System.Environment]::GetEnvironmentVariable('PATH', 'User')"') do set "PATH=%%p"
    
    :: Verify Git installation
    Get-Command git >nul 2>&1
    if %errorlevel% equ 0 (
        echo Git was successfully installed!
        git --version
    ) else (
        echo Git installation via winget appears to have completed, but Git command not found.
        echo This may be because Git is not in your PATH. Trying direct download...
        goto :DIRECT_GIT
    )
)

goto :CLEANUP

:DIRECT_GIT
:: Direct download of Git if winget method failed
echo Downloading Git installer directly...

:: Create temp directory if it doesn't exist
if not exist "%TEMP_DIR%" set "TEMP_DIR=%TEMP%\SoftwareInstall" && mkdir "%TEMP_DIR%"

:: Download Git installer
powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://github.com/git-for-windows/git/releases/download/v2.45.0.windows.1/Git-2.45.0-64-bit.exe' -OutFile '%TEMP_DIR%\GitInstaller.exe'}"

:: Run Git installer silently
echo Running Git installer...
call "%TEMP_DIR%\GitInstaller.exe" /VERYSILENT /NORESTART

:: Refresh environment variables again
echo Refreshing environment variables after direct installation...
for /f "tokens=*" %%p in ('powershell -Command "[System.Environment]::GetEnvironmentVariable('PATH', 'Machine') + ';' + [System.Environment]::GetEnvironmentVariable('PATH', 'User')"') do set "PATH=%%p"

:: Verify installation
Get-Command git >nul 2>&1
if %errorlevel% equ 0 (
    echo Git was successfully installed via direct download!
    git --version
) else (
    echo Git installation failed. You may need to restart your computer for PATH changes to take effect.
    echo After restarting, you can verify the installation by typing 'git --version' in a new command prompt.
    echo If Git still isn't found, please install Git manually from https://git-scm.com/download/win
)

:CLEANUP
:: Clean up
if defined TEMP_DIR (
    echo Cleaning up temporary files...
    rd /s /q "%TEMP_DIR%" 2>nul
)

echo.
echo Process completed.
pause
endlocal