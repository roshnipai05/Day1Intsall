@echo off
:: Simplified script to check for and install winget if not present

echo Checking if winget is already installed...

:: Check if winget exists by trying to run it
winget --version >nul 2>&1
if %errorlevel% equ 0 (
    echo Winget is already installed on this system.
    winget --version
    goto :END
)

echo Winget is not installed. Starting installation...

:: Check for admin privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Administrator privileges required. Please run as administrator.
    pause
    exit /b 1
)

:: Quick Windows version check (must be Windows 10 1809+ or Windows 11)
for /f "tokens=4-5 delims=. " %%i in ('ver') do set VERSION=%%i.%%j
if "%VERSION%" neq "10.0" (
    echo ERROR: Winget requires Windows 10 or Windows 11.
    pause
    exit /b 1
)

:: Create temp directory
set "TEMP_DIR=%TEMP%\WingetInstall"
if not exist "%TEMP_DIR%" mkdir "%TEMP_DIR%"

:: Download and install winget
echo Downloading and installing winget...
powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle' -OutFile '%TEMP_DIR%\winget.msixbundle'; Add-AppxPackage -Path '%TEMP_DIR%\winget.msixbundle'}"

:: Verify installation
winget --version >nul 2>&1
if %errorlevel% equ 0 (
    echo Winget was successfully installed!
    winget --version
) else (
    echo Installation failed. You may need to install dependencies:
    echo - Microsoft.UI.Xaml
    echo - Microsoft.VCLibs.x64.14.00.Desktop
    echo Attempting to install dependencies...
    
    powershell -Command "& {Invoke-WebRequest -Uri 'https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx' -OutFile '%TEMP_DIR%\VCLibs.appx'; Add-AppxPackage -Path '%TEMP_DIR%\VCLibs.appx'}"
    powershell -Command "& {Invoke-WebRequest -Uri 'https://github.com/microsoft/microsoft-ui-xaml/releases/download/v2.7.3/Microsoft.UI.Xaml.2.7.x64.appx' -OutFile '%TEMP_DIR%\UI.Xaml.appx'; Add-AppxPackage -Path '%TEMP_DIR%\UI.Xaml.appx'}"
    
    echo Trying winget installation again...
    powershell -Command "& {Add-AppxPackage -Path '%TEMP_DIR%\winget.msixbundle'}"
    
    winget --version >nul 2>&1
    if %errorlevel% equ 0 (
        echo Winget was successfully installed after adding dependencies!
        winget --version
    ) else (
        echo Installation still failed. Please install winget manually from the Microsoft Store.
    )
)

:: Clean up
rd /s /q "%TEMP_DIR%" 2>nul

:END
echo.
echo Process completed.
pause
