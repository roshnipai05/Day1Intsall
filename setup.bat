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
) else (
    if !MAJOR! LSS 3 (
        echo Python version too old. Installing Python %TARGET_VER%...
        winget install -e --id Python.Python.3.12
    ) else if !MAJOR!==3 if !MINOR! LSS 10 (
        echo Python version too old. Installing Python %TARGET_VER%...
        winget install -e --id Python.Python.3.12
    ) else (
        echo Python version is sufficient.
    )
)

:: ---------- 3. Check and Install Git ----------
where git >nul 2>nul
if errorlevel 1 (
    echo Installing Git...
    winget install -e --id Git.Git
) else (
    echo Git is already installed.
)

:: ---------- 4. Check and Install VSCode ----------
where code >nul 2>nul
if errorlevel 1 (
    echo Installing Visual Studio Code...
    winget install -e --id Microsoft.VisualStudioCode
) else (
    echo VSCode is already installed.
)

:: ---------- 5. Install VSCode Extensions ----------
echo Installing VSCode Extensions...
code --install-extension ms-python.python
code --install-extension ms-python.vscode-pylance
code --install-extension ms-toolsai.jupyter
code --install-extension formulahendry.terminal
code --install-extension kisstkondoros.vscode-gutter-preview

:: ---------- 6. Clone Repository ----------
echo Cloning GitHub repository...
git clone https://github.com/roshnipai05/ysp-exercises
cd ysp-exercises

:: ---------- 7. Create Virtual Environment ----------
echo Creating virtual environment...
python -m venv venv
call venv\Scripts\activate

:: ---------- 8. Install Dependencies ----------
if exist requirements.txt (
    echo Installing Python dependencies...
    pip install --upgrade pip
    pip install -r requirements.txt
) else (
    echo No requirements.txt found.
)

:: ---------- 9. Launch VSCode in 'notebooks' Folder ----------
if exist notebooks (
    echo Launching VSCode in 'notebooks' folder...
    code notebooks
) else (
    echo [WARNING] 'notebooks' folder not found.
    code .
)

endlocal
