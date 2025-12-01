@echo off
:: Check for admin rights and auto-elevate if needed
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting administrator privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:: Clear screen and show header
cls
echo ============================================
echo  AeriaLab Jetson Remote Desktop Installer
echo ============================================
echo.
echo This will set up remote desktop connection to your Jetson Nano
echo.
echo Running with administrator privileges...
echo.
timeout /t 2 /nobreak >nul

:: Create Scripts directory
echo [1/3] Creating C:\Scripts directory...
if not exist "C:\Scripts" (
    mkdir "C:\Scripts"
    echo       Created C:\Scripts
) else (
    echo       C:\Scripts already exists
)
echo.

:: Create connection batch file
echo [2/3] Creating connect_jetson.bat...
(
echo @echo off
echo echo Connecting to Jetson Nano at 192.168.0.191...
echo mstsc /v:192.168.0.191
) > "C:\Scripts\connect_jetson.bat"
echo       Created connect_jetson.bat
echo.

:: Add to PATH
echo [3/3] Adding C:\Scripts to system PATH...
powershell -Command "$currentPath = [Environment]::GetEnvironmentVariable('Path', 'Machine'); if ($currentPath -notlike '*C:\Scripts*') { [Environment]::SetEnvironmentVariable('Path', $currentPath + ';C:\Scripts', 'Machine'); echo '      Added to PATH' } else { echo '      Already in PATH' }"
echo.

:: Success message with instructions
cls
echo ============================================
echo  Installation Complete!
echo ============================================
echo.
echo The Jetson Remote Desktop tool has been installed successfully.
echo.
echo ========================================================
echo  How to Connect a Remote Dekstop Session with the Nano:
echo ========================================================
echo  1. Close this window
echo  2. Open a NEW Command Prompt (no need run as administrator)   
echo  3. Type: connect_jetson
echo  4. Press Enter
echo  5. Remote Desktop will open and connect to 192.168.0.191
echo ============================================
echo Press any key to close this installer...
pause >nul
exit
