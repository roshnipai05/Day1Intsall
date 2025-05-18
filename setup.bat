@echo off
setlocal enabledelayedexpansion

:: ---------- 1. Check Internet ----------
echo Checking internet connection...
ping -n 1 1.1.1.1 >nul
if errorlevel 1 (
    echo [ERROR] No internet connection.
    exit /b 1
)

:: ---------- 2. Check Python version ----------
for /f "tokens=2 delims=[] " %%A in ('python --version 2^>nul') do set PYVER=%%A
set "MIN_VER=3.10"
set "TARGET_VER=3.12"

echo Detected Python version: %PYVER%
for /f "tokens=1,2 delims=." %%a in ("%PYVER%") do (
    set "MAJOR=%%a"
    set "MINOR=%%b"
)

if not defined PYVER (
    echo Python not found. Installing Python %TARGET_VER%...
    winget install -e --id Python.Python.3.12
    set PYJUSTINSTALLED=1
) else (
    if !MAJOR! LSS 3 (
        echo Python version too old. Installing Python %TARGET_VER%...
        winget install -e --id Python.Python.3.12
        set PYJUSTINSTALLED=1
    ) else if !MAJOR!==3 if !MINOR! LSS 10 (
        echo Python version too old. Installing Python %TARGET_VER%...
        winget install -e --id Python.Python.3.12
        set PYJUSTINSTALLED=1
    ) else (
        echo Python version is sufficient.
    )
)

:: If Python was just installed, refresh path
if defined PYJUSTINSTALLED (
    echo Waiting for Python to be added to PATH...
    timeout /t 5
)

:: ---------- 3. Install Git ----------
where git >nul 2>nul
if errorlevel 1 (
    echo Installing Git...
    winget install -e --id Git.Git
) else (
    echo Git is already installed.
)

:: ---------- 4. Install VSCode ----------
where code >nul 2>nul
if errorlevel 1 (
    echo Installing Visual Studio Code...
    winget install -e --id Microsoft.VisualStudioCode
    set CODEJUSTINSTALLED=1
) else (
    echo VSCode is already installed.
)

:: If VSCode was just installed, refresh path
if defined CODEJUSTINSTALLED (
    echo Waiting for VSCode to be added to PATH...
    timeout /t 5
)

:: ---------- 5. Install VSCode Extensions ----------
echo Installing VSCode Extensions...
code --install-extension ms-python.python
code --install-extension ms-python.vscode-pylance
code --install-extension ms-toolsai.jupyter
code --install-extension formulahendry.terminal
code --install-extension kisstkondoros.vscode-gutter-preview

:: ---------- 6. Clone GitHub Repository ----------
if exist ysp-exercises (
    echo Repo folder already exists. Skipping clone.
) else (
    echo Cloning GitHub repository...
    git clone https://github.com/roshnipai05/ysp-exercises
    if errorlevel 1 (
        echo [ERROR] Failed to clone repository.
        exit /b 1
    )
)

cd ysp-exercises

:: ---------- 7. Create and Activate Virtual Environment ----------
echo Creating virtual environment...
python -m venv venv

echo Activating virtual environment...
call venv\Scripts\activate.bat

:: ---------- 8. Install Dependencies ----------
if exist requirements.txt (
    echo Installing dependencies from requirements.txt...
    pip install --upgrade pip
    pip install -r requirements.txt
) else (
    echo No requirements.txt found. Skipping dependency installation.
)

:: ---------- 9. Launch VSCode in Notebooks Folder ----------
if exist notebooks (
    echo Opening 'notebooks' folder in VSCode...
    code notebooks
) else (
    echo [WARNING] 'notebooks' folder not found. Opening repo root.
    code .
)

endlocal
