@echo off
echo ============================================
echo  AeriaLab Jetson Remote Desktop Installer
echo ============================================
echo.
echo This will set up remote desktop connection to your Jetson Nano
echo.
pause

REM Check for admin privileges
net session >nul 2>&1
if %errorLevel% == 0 (
    echo Running with administrator privileges...
    echo.
) else (
    echo ERROR: This installer requires administrator privileges!
    echo Please right-click and select "Run as administrator"
    echo.
    pause
    exit /b 1
)

REM Create Scripts directory
echo Creating C:\Scripts directory...
if not exist "C:\Scripts" (
    mkdir "C:\Scripts"
    echo Created C:\Scripts
) else (
    echo C:\Scripts already exists
)

REM Create connection batch file
echo Creating connect_jetson.bat...
(
echo @echo off
echo mstsc /v:192.168.0.191
) > "C:\Scripts\connect_jetson.bat"
echo Created connect_jetson.bat

REM Add to PATH
echo Adding C:\Scripts to system PATH...
powershell -Command "[Environment]::SetEnvironmentVariable('Path', [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';C:\Scripts', 'Machine')"
echo Added to PATH

echo.
echo ============================================
echo  Installation Complete!
echo ============================================
echo.
echo You can now connect to your Jetson Nano by:
echo 1. Opening a NEW Command Prompt or PowerShell
echo 2. Typing: connect_jetson
echo 3. Press Enter
echo.
echo Note: You may need to close and reopen your terminal
echo       for the PATH changes to take effect.
echo.
pause
