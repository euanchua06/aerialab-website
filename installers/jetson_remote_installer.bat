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
echo This installer will set up remote desktop connection to your Jetson Nano
echo.
echo Running with administrator privileges...
echo.
timeout /t 2 /nobreak >nul

:: Show setup instructions
cls
echo ============================================
echo  SETUP INSTRUCTIONS
echo ============================================
echo.
echo Before continuing, please complete these steps on your Jetson Nano:
echo.
echo  1. Connect your Jetson Nano to the SAME network as this laptop
echo     (via Ethernet or WiFi)
echo.
echo  2. Open a terminal on the Jetson Nano
echo.
echo  3. Run this command:    hostname -I
echo.
echo  4. Note the IP address shown (example: 192.168.1.100)
echo.
echo ============================================
echo.
echo Press any key once you have the Jetson's IP address ready...
pause >nul

:: Prompt for IP address
cls
echo ============================================
echo  Enter Jetson Nano IP Address
echo ============================================
echo.
set /p JETSON_IP="Enter the IP address from your Jetson Nano: "

:: Validate IP format (basic check)
echo.
echo Validating IP address format...
echo %JETSON_IP% | findstr /r "^[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$" >nul
if %errorLevel% neq 0 (
    echo.
    echo ERROR: Invalid IP address format!
    echo Please enter a valid IP address like: 192.168.1.100
    echo.
    pause
    exit /b
)

echo IP address format valid: %JETSON_IP%
echo.
timeout /t 1 /nobreak >nul

:: Remove old Scripts directory if it exists
echo [1/3] Preparing C:\Scripts directory...
if exist "C:\Scripts" (
    echo       Removing old version...
    rmdir /s /q "C:\Scripts" 2>nul
    echo       Old version removed
)
mkdir "C:\Scripts"
echo       Created fresh C:\Scripts directory
echo.

:: Create connection batch file with user-provided IP
echo [2/3] Installing connect_jetson.bat...
(
echo @echo off
echo echo Connecting to Jetson Nano at %JETSON_IP%...
echo mstsc /v:%JETSON_IP%
) > "C:\Scripts\connect_jetson.bat"
echo       Installed connect_jetson.bat with IP: %JETSON_IP%
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
echo Configured to connect to: %JETSON_IP%
echo.
echo ============================================
echo  How to Connect to Your Jetson Nano:
echo ============================================
echo  1. Close this window
echo  2. Open a NEW Command Prompt (no admin rights needed)
echo  3. Type: connect_jetson
echo  4. Press Enter
echo  5. Remote Desktop will connect to %JETSON_IP%
echo ============================================
echo.
echo NOTE: If your Jetson's IP address changes, simply run this
echo       installer again and enter the new IP address.
echo.
echo ============================================
echo Press any key to close this installer...
pause >nul
exit
