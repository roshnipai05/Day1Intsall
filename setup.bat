@echo off
setlocal enabledelayedexpansion

:: ---------- 1. Check Internet ----------
echo Checking internet connection...
ping -n 1 1.1.1.1 >nul
if errorlevel 1 (
    echo [ERROR] No internet connection.
    pause
    exit /b 1
)

:: ---------- 2. Install Git if missing ----------
where git >nul 2>nul
if errorlevel 1 (
    echo Git not found. Installing Git...
    winget install --id Git.Git -e --silent
    set GIT_JUST_INSTALLED=1
) else (
    echo Git is already installed.
)

:: ---------- 3. Install VSCode if missing ----------
where code >nul 2>nul
if errorlevel 1 (
    echo VSCode not found. Installing VSCode...
    winget install --id Microsoft.VisualStudioCode -e --silent
    set CODE_JUST_INSTALLED=1
) else (
    echo VSCode is already installed.
)

:: ---------- 4. Refresh PATH if needed ----------
if defined GIT_JUST_INSTALLED (
    echo Adding Git to PATH...
    set "GIT_PATH=C:\Program Files\Git\cmd"
    setx PATH "%PATH%;%GIT_PATH%"
)

if defined CODE_JUST_INSTALLED (
    echo Adding VSCode to PATH...
    set "CODE_PATH=%USERPROFILE%\AppData\Local\Programs\Microsoft VS Code\bin"
    setx PATH "%PATH%;%CODE_PATH%"
)

:: Refresh session PATH (for immediate use)
set "PATH=%PATH%;C:\Program Files\Git\cmd"
set "PATH=%PATH%;%USERPROFILE%\AppData\Local\Programs\Microsoft VS Code\bin"

:: ---------- 5. Confirm VSCode CLI is available ----------
where code >nul 2>nul
if errorlevel 1 (
    echo [ERROR] VSCode CLI 'code' still not recognized. Please restart terminal and re-run script.
    pause
    exit /b 1
)

:: ---------- 6. Install VSCode Extensions ----------
echo Installing VSCode Extensions...
code --install-extension ms-python.python
code --install-extension ms-python.vscode-pylance
code --install-extension ms-toolsai.jupyter
code --install-extension formulahendry.terminal
code --install-extension kisstkondoros.vscode-gutter-preview

:: ---------- 7. Clone Repository ----------
if not exist ysp-exercises (
    echo Cloning GitHub repository...
    git clone https://github.com/roshnipai05/ysp-exercises
    if errorlevel 1 (
        echo [ERROR] Failed to clone repository. Check your internet or GitHub access.
        pause
        exit /b 1
    )
) else (
    echo Repository folder already exists. Skipping clone.
)

cd ysp-exercises

:: ---------- 8. Create and Activate Virtual Environment ----------
echo Creating virtual environment...
python -m venv venv
if errorlevel 1 (
    echo [ERROR] Failed to create virtual environment.
    pause
    exit /b 1
)

echo Activating virtual environment...
call venv\Scripts\activate.bat

:: ---------- 9. Install Dependencies ----------
if exist requirements.txt (
    echo Installing dependencies from requirements.txt...
    pip install --upgrade pip
    pip install -r requirements.txt
    if errorlevel 1 (
        echo [ERROR] Failed to install dependencies.
        pause
        exit /b 1
    )
) else (
    echo No requirements.txt found.
)

:: ---------- 10. Launch VSCode in 'notebooks' Folder ----------
if exist notebooks (
    echo Opening 'notebooks' folder in VSCode...
    code notebooks
) else (
    echo [WARNING] 'notebooks' folder not found. Opening project root instead.
    code .
)

echo.
echo === Setup complete! ===
pause
endlocal
